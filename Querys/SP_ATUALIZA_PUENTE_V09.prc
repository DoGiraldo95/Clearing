CREATE OR REPLACE PROCEDURE "SP_ATUALIZA_PUENTE_V09"
AS
  -- select unprocessed datafiles.
  /* Autor: Operaciones CPT
     Descripcion: Para las transacciones de usos, este procedimiento agrupa por lotes las transacciones que se encuentran en la base de datos de Mercury
                  cuyo campo cu_dat_inc_puente estan  06/06/6666(no se han transmitido a Puente-Lote). Posteriormete
                  inserta dichas transacciones en Lote y Puente de Clearing y establece como marca de procesamiento la fecha actual (SYSDATE)
                  en la tabla cardusage.
          Para las transacciones de recargas y ventas, este procedimiento agrupa por lotes las transacciones que se encuentran en la base de datos de Mercury
                  cuyo campo ptd_dat_inc_puente estan  03/03/3333(no se han transmitido a Puente-Lote). Posteriormete
                  inserta dichas transacciones en Lote y Puente de Clearing y establece como marca de procesamiento la fecha actual (SYSDATE)
                  en la tabla y pos_trandt.
  */

  cursor c_UsageDataFiles
  is
    select cu.pb_id, cu.dlf_id, udf_id, count(1) transCount
    from cardusage cu
    join deviceLogFiles dlf on cu.pb_id = dlf.pb_id and cu.dlf_id = dlf.dlf_id
    JOIN DEVICELOGMT DMT ON DLF.PB_ID = DMT.PB_ID AND DLF.DLF_ID = DMT.DLF_ID
    join UsageDataFile udf on udf.pb_id = cu.pb_id and udf.dv_id = dmt.dv_id and udf.udf_fileseq = dlf.dlf_fileseqnbr and UDF.UDF_CONNDATE = DLF.DLF_DTCONN
    WHERE CUT_ID IN (1, 5)
    --and cu_dat_inc_puente >= trunc(SYSDATE) /* 1.0 */
    --and cu_dat_inc_puente < trunc(SYSDATE)+1
    and cu_dat_inc_puente = TO_DATE ('06/06/6666 00:00:00', 'dd/mm/yyyy hh24:mi:ss')
    and udf.udf_receivedate >= trunc (sysdate -1)--Agregado 26/10/2022 por CLEARING. Solucion a problema de indice. Tiempo de prosamiento > 40 minutos
    --and cu.cu_datetime >= to_date ('01/10/2022 00:00','dd/mm/yyyy hh24:mi')
    --and cu.cu_datetime <=  sysdate--to_date ('25/10/2022 23:59','dd/mm/yyyy hh24:mi')
    and (app_id, app_iss_id) in
      ( select app_id, iss_id from applications where af_id in (27,28, 30)
      )
  AND cu.app_id <> 1023
  group by cu.pb_id, cu.dlf_id, udf_id;

  cursor c_posSessionFiles
  is
    select pd_code, ps_id, prs_id, to_number( pd_code || ps_id || prs_id) UniqueId, TransCount
    from
      (select ps.pd_code, ps.ps_id, ps.prs_id, count(1) as TransCount
      from pos_session ps
      join pos_sessionxtranmt pstm on ps.ps_id = pstm.ps_id and ps.pd_code = pstm.pd_code
      join pos_trandt ptd on ps.pd_code = ptd.pd_code and pstm.ptm_trannbr = ptd.ptm_trannbr
      join pos_tranmt ptm on ptm.pd_code = pstm.pd_code and ptm.ptm_trannbr = pstm.ptm_trannbr
      where PS.PS_ENDSESSION is not null
      --AND ptd_dat_inc_puente > trunc(sysdate-6) -- actualizado para pruebas en pre-produccion
      --and ptd_dat_inc_puente >= trunc(SYSDATE)
      --and ptd_dat_inc_puente <= trunc(SYSDATE)+1
      and ptd_dat_inc_puente = TO_DATE ('03/03/3333 00:00:00', 'dd/mm/yyyy hh24:mi:ss')
      and ptd_status = 'A'
      and PTM.PTM_REGUSER <> 'COLLECTOR'
      --and rownum < 1
      group by ps.pd_code, ps.ps_id, ps.prs_id
      );

  rUsageDataFile c_UsageDataFiles%Rowtype;
  rPosSessionFile c_posSessionFiles%RowType;
  vCount Numeric(10);
  vProcessInit Date;
  vIterLote number(5);
  err_num NUMBER (10);
  err_msg VARCHAR2(255);
BEGIN

  begin

    /*CPT: Se actualizan los registros que tienen fecha de ingreso a puente en NULO, para que en adelante el proceso tomo dichas
           transacciones con una marca especifica y asi tome el indice que acelera las sentencias sql sobre las tablas cardUsage y Pos_Trandt
    */
       /* UPDATE cardusage
        SET   cu_dat_inc_puente = TO_DATE('03/03/3333 00:00:00','dd/mm/yyyy hh24:mi:ss')
        WHERE cut_id in (1, 5)
        AND (app_id, app_iss_id) in ( select app_id, iss_id from applications where af_id in (27,28, 30) )
        AND app_id <> 1023                                -- revisar
        AND CU_DAT_INC_PUENTE IS NULL;

        COMMIT;

        UPDATE pos_trandt
        SET ptd_dat_inc_puente = TO_DATE('03/03/3333 00:00:00','dd/mm/yyyy hh24:mi:ss')
        WHERE (pd_code, ptm_trannbr) in
              (
                select pstm.pd_code, pstm.ptm_trannbr
                from  pos_session ps
                      join POS_SESSIONXTRANMT PSTM on PS.PS_ID = PSTM.PS_ID and PS.PD_CODE = PSTM.PD_CODE
                      join pos_trandt ptd on pstm.pd_code = ptd.pd_code and pstm.ptm_trannbr = ptd.ptm_trannbr    --CRISTHIAN TORRES. cambiar a  pstm.pd_code = ptd.pd_code
                      join pos_tranmt ptm on ptm.pd_code = pstm.pd_code and ptm.ptm_trannbr = pstm.ptm_trannbr
                where PS.PS_ENDSESSION is not null
                      and nvl(to_char(ptd_dat_inc_puente,'dd/mm/yyyy'),'nulo') = 'nulo'
                      and ptd_status = 'A'
                      and PTM.PTM_REGUSER <> 'COLLECTOR'
                group by pstm.pd_code, pstm.ptm_trannbr
              )
        AND ptd_status = 'A'
        and nvl(to_char(ptd_dat_inc_puente,'dd/mm/yyyy'),'nulo') = 'nulo';

        COMMIT; */

      --/*CPT: 26/05/2013 - En insert de recargas se incorpora join con tabla de medios de pago

    -- Limpiamos la tabla Pre-lote para que no pasemos registros indevidos.
    DELETE
    FROM PRE_PUENTE;
    COMMIT;
    Open c_UsageDataFiles;
    Fetch c_UsageDataFiles into rUsageDataFile;

    WHILE (c_UsageDataFiles%FOUND)
    Loop
      Begin
        vProcessInit := sysdate;
        -- ejecuta insert en la tabla pre-puente para evitar problemas con el uso de funciones particulares entre db_link
        INSERT
        INTO PRE_PUENTE
          (
            APP_ID,
            APP_ISS_ID,
            APPCRD_TSN,
            CRD_SNR,
            CRD_INTSNR,
            CD_ID,
            CARDNUMBER,
            DATAFILE_ID,
            DEV_ID,
            DEV_STAT,
            DEV_TSN,
            DEV_TYPE,
            EMPL_ID,
            EMPL_TYPE,
            ERROR_CODE,
            ERROR_INTCODE,
            FARE_RULE,
            GROUP_FNAME,
            GROUP_ID,
            HL_ACTION,
            ITG_ACCVALUE,
            ITG_APPID,
            ITG_APPTSN,
            ITG_CTR,
            ITG_DATETIME,
            ITG_ID,
            LINE_ID,
            OWNER_ID,
            PLACE_ID,
            PROVIDER_ID,
            PROVIDER_ROLE,
            PURSE_AMOUNT,
            PURSE_BAL,
            PURSE_ID,
            TRX_ID,
            TRX_DATETIME,
            TRX_FAREVALUE,
            TFR_DATETIME,
            PRC_DATETIME,
            CARD_BALANCE,
            FLG_MULTPURSE,
            ID_LOTE
          )
        SELECT cu.app_id,
          cu.app_iss_id,
          cu_tsn,
          cu.crd_snr,
          cu.cu_crdintsnr,
          nvl(cu.cd_id, 0), --CPT: Se modifica esta linea agregando la funcion nvl, para que asigne el valor cero(0) en caso de ser nulo. Antes estaba: "cu.cd_id".
          formatcard (cu.iss_id, cu.cd_id, cu.crd_snr) AS cardnumber,
          udf.udf_id,
          TO_NUMBER (1 || dev.dv_id) AS dev_id,
          cu.dvs_id,
          Nvl(cu.cu_ttc, 0),
          1,
          4,
          cu.cu_prstid,
          Nvl(cu.cu_errorcode,0),
          Nvl(cu.cu_interrorcode, 0),
          nvl(cu.cu_farerule, 1),
          dlf.dlf_filename,
          udf.udf_id,
          cu.cu_hl_action,
          cu.cu_itg_accvalue * 1000,
          cu.cu_itg_appid,
          cu.cu_itg_apptsn,
          cu.cu_itg_ctr,
          cu.cu_itg_datetime,
          cu.cu_itg_id,
          cu.ld_id,
          cu.cu_hrid,
          dlm.veh_id,
          dlm.tp_id,
          1,
          Nvl(cu_partfarevalue,0) * 1000,
          (
          CASE
            WHEN nvl(cu.cu_purseused,0) = 0
            THEN Nvl(cu.cu_purseavalue,0) * 1000
            ELSE nvl(cu.cu_pursebvalue,0) * 1000
          END),
          Nvl(cu.cu_purseused, 0),
          CUT_ID,
          cu.cu_datetime,
          nvl(cu.cu_farevalue,0) * 1000,
          sysdate,
          null,
          Nvl((cu_purseAValue + cu_purseBValue), 0) * 1000 as CARD_BALANCE,
          case
            when cu_partfarevalue = cu_farevalue
            then 0
            else cu_partfareseqnbr
          end,
          udf.udf_id
        FROM cardusage cu
        join devicelogmt dlm on cu.pb_id = dlm.pb_id and cu.dlf_id = dlm.dlf_id and cu.dlmt_id = dlm.dlmt_id
        join devicelogfiles dlf on cu.pb_id = dlf.pb_id and cu.dlf_id = dlf.dlf_id
        join applications app on cu.app_id = app.app_id and cu.app_iss_id = app.iss_id
        join applicationfunctions afu on app.af_id = afu.af_id
        join devices dev on dlm.dvt_id = dev.dvt_id and dlm.dv_id = dev.dv_id
        join usagedatafile udf on udf.pb_ID = DLF.PB_ID and UDF.DV_ID = DLM.DV_ID and UDF.UDF_FILESEQ = DLF.DLF_FILESEQNBR
             and dlf.dlf_filename = udf.udf_filename /*CPT: De acuerdo a Analisis realizado con Pedro Lozano se agrega este filtro pra identificar las trxs univocamente*/
        WHERE cu.pb_id = rUsageDataFile.pb_id
        and cu.dlf_id = rUsageDataFile.dlf_id
        AND cu.cut_id IN (1, 5)
        AND (afu.af_id IN (27, 28, 30) OR cu.app_id = 100)
        AND cu.app_id <> 1023 -- revisar
        --and cu_dat_inc_puente >= trunc(SYSDATE) /* 3.0 */
        --and cu_dat_inc_puente < trunc(SYSDATE)+1;
        and cu_dat_inc_puente = TO_DATE ('06/06/6666 00:00:00', 'dd/mm/yyyy hh24:mi:ss');
        --AND cu.cu_dat_inc_puente > trunc(sysdate-6);
        --and cu_dat_inc_puente >= TO_DATE ('09-06-2011 00:01', 'DD-MM-YYYY HH24:MI')--trunc(sysdate-6) -- actualizado para pruebas en pre-produccion
        --and cu_dat_inc_puente <= TO_DATE ('09-06-2011 23:59', 'DD-MM-YYYY HH24:MI');
        --and cu_dat_inc_puente = TO_DATE ('03/03/3333 00:00:00', 'dd/mm/yyyy hh24:mi:ss');  /* 3.1 */
        -- verifica Iterac?o de lote
        Select count(1)
        into vIterLote
        from lote_tmp
        where ID_LOTE = rUsageDataFile.udf_id;
        -- Marca las transacciones del lote que fueron transferidas.
        insert
        into lote_tmp
          (
            ID_LOTE,
            ITER_LOTE,
            ORIGEN_LOTE,
            CANT_TX_APB,
            DISCR_TX_APB,
            FECHA_INICIO_INGRESO,
            FECHA_FIN_INGRESO
          )
          values
          (
            rUsageDataFile.udf_id,
            vIterLote + 1,
            1,
            rUsageDataFile.TransCount,
            '',
            vProcessInit,
            sysdate
          );
        -- insert en la tabla puente del db-link a traves de la tabla pre-puente.
        INSERT
        INTO puente_tmp
          (
            APP_ID,
            APP_ISS_ID,
            APPCRD_TSN,
            CRD_SNR,
            CRD_INTSNR,
            CD_ID,
            CARDNUMBER,
            DATAFILE_ID,
            DEV_ID,
            DEV_STAT,
            DEV_TSN,
            DEV_TYPE,
            EMPL_ID,
            EMPL_TYPE,
            ERROR_CODE,
            ERROR_INTCODE,
            FARE_RULE,
            GROUP_FNAME,
            GROUP_ID,
            HL_ACTION,
            ITG_ACCVALUE,
            ITG_APPID,
            ITG_APPTSN,
            ITG_CTR,
            ITG_DATETIME,
            ITG_ID,
            LINE_ID,
            OWNER_ID,
            PLACE_ID,
            PROVIDER_ID,
            PROVIDER_ROLE,
            PURSE_AMOUNT,
            PURSE_BAL,
            PURSE_ID,
            TRX_ID,
            TRX_DATETIME,
            TRX_FAREVALUE,
            TFR_DATETIME,
            PRC_DATETIME,
            CARD_BALANCE,
            FLG_MULTPURSE,
            ID_LOTE,
            ITER_LOTE
          )
        SELECT APP_ID,
          APP_ISS_ID,
          APPCRD_TSN,
          CRD_SNR,
          CRD_INTSNR,
          CD_ID,
          CARDNUMBER,
          DATAFILE_ID,
          DEV_ID,
          DEV_STAT,
          DEV_TSN,
          DEV_TYPE,
          EMPL_ID,
          EMPL_TYPE,
          ERROR_CODE,
          ERROR_INTCODE,
          FARE_RULE,
          GROUP_FNAME,
          GROUP_ID,
          HL_ACTION,
          ITG_ACCVALUE,
          ITG_APPID,
          ITG_APPTSN,
          ITG_CTR,
          ITG_DATETIME,
          ITG_ID,
          LINE_ID,
          OWNER_ID,
          PLACE_ID,
          PROVIDER_ID,
          PROVIDER_ROLE,
          PURSE_AMOUNT,
          PURSE_BAL,
          PURSE_ID,
          TRX_ID,
          TRX_DATETIME,
          TRX_FAREVALUE,
          TFR_DATETIME,
          PRC_DATETIME,
          CARD_BALANCE,
          FLG_MULTPURSE,
          ID_LOTE,
          vIterLote + 1 AS ITER_LOTE
        FROM PRE_PUENTE;
        -- comentado para pruebas en pre-produccion
        -- Se asigna la fecha 07/07/7777 como fecha de procesamiento, de manera que sea facil la identificacion de las transacciones
        -- procesadas por Lotes.
        UPDATE cardusage
        SET   cu_dat_inc_puente =  SYSDATE
        --SET   cu_dat_inc_puente = SYSDATE
        WHERE pb_id = rUsageDataFile.pb_id
        and dlf_id = rUsageDataFile.dlf_id
        AND cut_id in (1, 5)
        AND (app_id, app_iss_id) in ( select app_id, iss_id from applications where af_id in (27,28, 30) )
        AND app_id <> 1023                                -- revisar
        --Comentario AND NVL(TO_CHAR(CU_DAT_INC_PUENTE,'dd/mm/yyyy'),'nulo') = 'nulo';
        AND CU_DAT_INC_PUENTE = TO_DATE ('06-06-6666 00:00:00', 'dd/mm/yyyy hh24:mi:ss');

        DELETE
        FROM PRE_PUENTE;
        -- cierra la transaccion;
        commit;
      EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE( 'Erro export Usage DataFile ('|| 'udf_id' || rUsageDataFile.udf_id || ') ' || SQLERRM );
      end;
      FETCH c_UsageDataFiles INTO rUsageDataFile;
    END LOOP;
    Close c_UsageDataFiles;
  EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE( 'Erro on export DataUsages ' || SQLERRM );
  end;

  -- Limpiamos la tabla Pre-lote para que no pasemos registros indevidos.
  DELETE
  FROM PRE_PUENTE;
  COMMIT;
  -- Proccess Sales records
  Begin
    Open c_posSessionFiles;
    Fetch c_posSessionFiles into rPosSessionFile;

    WHILE (c_posSessionFiles%FOUND)
    Loop
      Begin
        vProcessInit := sysdate;

        INSERT
        INTO PRE_PUENTE
          (
            APP_ID,
            APP_ISS_ID,
            APPCRD_TSN,
            CRD_SNR,
            CRD_INTSNR,
            CD_ID,
            CARDNUMBER,
            DATAFILE_ID,
            DEV_ID,
            DEV_STAT,
            DEV_TSN,
            DEV_TYPE,
            EMPL_ID,
            EMPL_TYPE,
            ERROR_CODE,
            ERROR_INTCODE,
            FARE_RULE,
            GROUP_FNAME,
            GROUP_ID,
            HL_ACTION,
            ITG_ACCVALUE,
            ITG_APPID,
            ITG_APPTSN,
            ITG_CTR,
            ITG_DATETIME,
            ITG_ID,
            LINE_ID,
            OWNER_ID,
            PLACE_ID,
            PROVIDER_ID,
            PROVIDER_ROLE,
            PURSE_AMOUNT,
            PURSE_BAL,
            PURSE_ID,
            TRX_ID,
            TRX_DATETIME,
            TRX_FAREVALUE,
            TFR_DATETIME,
            PRC_DATETIME,
            CARD_BALANCE,
            FLG_MULTPURSE,
            ID_LOTE
          )
        SELECT pod.ptd_appid,
          pod.ptd_issid,
          pod.ptd_tsn,
          pod.crd_snr,
          Nvl(crd.crd_intsnr, 0),
          Nvl(pod.cd_id, 0),     --CPT: Se modifica esta linea agregando la funcion nvl, para que asigne el valor cero(0) en caso de ser nulo. Antes estaba: "pod.cd_id".
          nvl(formatcard (pod.iss_id, pod.cd_id, pod.crd_snr), '0') ,
          to_number(rPosSessionFile.UniqueId),
          TO_NUMBER (4 || pod.pd_code),
          NULL,
          Nvl(pod.ptm_trannbr,0),  --CPT: Se modifica esta linea agregando la funcion nvl, para que asigne el valor cero(0) en caso de ser nulo. Antes estaba: "pod.ptm_trannbr".
          4,
          pom.prs_id,
          12,
          decode(nvl(PTD_CONF_DATE,TO_DATE('01-01-2001','DD-MM-YYYY')),TO_DATE('01-01-2001','DD-MM-YYYY'),80,0), --Pedro Lozano 15-05-2013: Actualizacion porque la red externa siempre envia esto en nulo. decode(nvl(PTD_CONF_PDCODE,0),0,80,0),
          0,
          0 ,
          'POS_' || ps.pd_code || '_' || ps.ps_id || '_' || pom.prs_id AS dlf_filename ,
          null,
          null,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          pom.tp_id,
          pod.pd_code,
          pom.tp_id ,
          2,
          pod.ptd_amount * 1000,
          pod.ptd_saldo  * 1000,
          decode( pod.ptd_selectedpurse, 0, 0, 1, 1, 2, 1 ),
/**/        Case
            When (Pyxm.Ppm_Code = 15 And To_Number(4 || Pom.Ptt_Id ) = 41) Then 43
            When (Pyxm.Ppm_Code = 16 And To_Number(4 || Pom.Ptt_Id ) = 41) Then 44
/**/        Else To_Number(4 || Pom.Ptt_Id ) END,
          pom.ptm_date,
          pod.ptd_amount * 1000,
          sysdate,
          null,
          (pod.ptd_balance1 + pod.ptd_balance2) * 10,
          0,
          rPosSessionFile.UniqueId
        FROM pos_sessionxtranmt ps
        join pos_tranmt pom on ps.pd_code = pom.pd_code and ps.ptm_trannbr = pom.ptm_trannbr
        join pos_trandt pod on ps.pd_code = pod.pd_code and ps.ptm_trannbr = pod.ptm_trannbr
        join pos_device pov on pom.pd_code = pov.pd_code
        Left Join Cards Crd On Pod.Iss_Id = Crd.Iss_Id  And Pod.Cd_Id = Crd.Cd_Id And Pod.Crd_Snr = Crd.Crd_Snr
/**/    Join Pos_Tranmtxpaymentmodes Pyxm On Pom.Ptm_Trannbr = Pyxm.Ptm_Trannbr And Pom.Pd_Code = Pyxm.Pd_Code
        --WHERE ps.pd_code = rPosSessionFile.pd_code
        WHERE ps.pd_code = rPosSessionFile.pd_code
        AND ps.ps_id = rPosSessionFile.ps_id
        AND pod.ptd_status = 'A'
        --AND pod.ptd_dat_inc_puente > trunc(sysdate-6)
        --and ptd_dat_inc_puente >= trunc(SYSDATE)
        --and ptd_dat_inc_puente <= trunc(SYSDATE)+1
        AND ptd_dat_inc_puente = TO_DATE ('03/03/3333 00:00:00', 'dd/mm/yyyy hh24:mi:ss')
        --AND ptd_dat_inc_puente = TO_DATE ('03/03/3333 00:00:00', 'dd/mm/yyyy hh24:mi:ss')  /*  4.1  */
        AND pom.ptm_reguser <> 'COLLECTOR';


        -- verifica Iterac?o de lote
        Select count(1)
        into vIterLote
        from lote_tmp
        where ID_LOTE = to_Number(rPosSessionFile.UniqueID);
        insert
        into lote_tmp
          (
            ID_LOTE,
            ITER_LOTE,
            ORIGEN_LOTE,
            CANT_TX_APB,
            DISCR_TX_APB,
            FECHA_INICIO_INGRESO,
            FECHA_FIN_INGRESO
          )
          values
          (
            to_Number(rPosSessionFile.UniqueID),
            vIterLote + 1,
            4,
            rPosSessionFile.TransCount,
            '',
            vProcessInit,
            sysdate
          );
        --Update UsageDataFile set
        INSERT
        INTO puente_tmp
          (
            APP_ID,
            APP_ISS_ID,
            APPCRD_TSN,
            CRD_SNR,
            CRD_INTSNR,
            CD_ID,
            CARDNUMBER,
            DATAFILE_ID,
            DEV_ID,
            DEV_STAT,
            DEV_TSN,
            DEV_TYPE,
            EMPL_ID,
            EMPL_TYPE,
            ERROR_CODE,
            ERROR_INTCODE,
            FARE_RULE,
            GROUP_FNAME,
            GROUP_ID,
            HL_ACTION,
            ITG_ACCVALUE,
            ITG_APPID,
            ITG_APPTSN,
            ITG_CTR,
            ITG_DATETIME,
            ITG_ID,
            LINE_ID,
            OWNER_ID,
            PLACE_ID,
            PROVIDER_ID,
            PROVIDER_ROLE,
            PURSE_AMOUNT,
            PURSE_BAL,
            PURSE_ID,
            TRX_ID,
            TRX_DATETIME,
            TRX_FAREVALUE,
            TFR_DATETIME,
            PRC_DATETIME,
            CARD_BALANCE,
            FLG_MULTPURSE,
            ID_LOTE,
            ITER_LOTE
          )
        SELECT APP_ID,
          APP_ISS_ID,
          APPCRD_TSN,
          CRD_SNR,
          CRD_INTSNR,
          CD_ID,
          CARDNUMBER,
          DATAFILE_ID,
          DEV_ID,
          DEV_STAT,
          DEV_TSN,
          DEV_TYPE,
          EMPL_ID,
          EMPL_TYPE,
          ERROR_CODE,
          ERROR_INTCODE,
          FARE_RULE,
          GROUP_FNAME,
          GROUP_ID,
          HL_ACTION,
          ITG_ACCVALUE,
          ITG_APPID,
          ITG_APPTSN,
          ITG_CTR,
          ITG_DATETIME,
          ITG_ID,
          LINE_ID,
          OWNER_ID,
          PLACE_ID,
          PROVIDER_ID,
          PROVIDER_ROLE,
          PURSE_AMOUNT,
          PURSE_BAL,
          PURSE_ID,
          TRX_ID,
          TRX_DATETIME,
          TRX_FAREVALUE,
          TFR_DATETIME,
          PRC_DATETIME,
          CARD_BALANCE,
          FLG_MULTPURSE,
          ID_LOTE,
          vIterLote + 1 AS ITER_LOTE
        FROM PRE_PUENTE;
        -- comentado para pruebas en pre-produccion

          -- Adicionado por cpt
          -- Se asigna la fecha 07/07/7777 como fecha de procesamiento, de manera que sea facil la identificacion de las transacciones
          -- procesadas por Lotes.
          UPDATE pos_trandt
          SET ptd_dat_inc_puente        = SYSDATE
          --SET ptd_dat_inc_puente        = SYSDATE
          WHERE (pd_code, ptm_trannbr) IN
            (SELECT pd_code,
              ptm_trannbr
            FROM pos_sessionxtranmt
            --WHERE pd_code = rPosSessionFile.pd_code
            WHERE pd_code = rPosSessionFile.pd_code
            AND ps_id     = rPosSessionFile.ps_id
            )
          AND ptd_status         = 'A'
          AND ptd_dat_inc_puente = TO_DATE ('03/03/3333 00:00:00', 'dd/mm/yyyy hh24:mi:ss');
          --AND ptm_reguser <> 'COLLECTOR';


        DELETE  --CRISTHIAN TORRES. desactivar para hacer traza
        FROM PRE_PUENTE;     --CRISTHIAN TORRES. la misma.....
        commit;
      EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE( 'Erro export Sale Session ('|| 'pd_code ' || rPosSessionFile.pd_code || ' Ps_id ' || rPosSessionFile.ps_id || ') ' || SQLERRM );
      end;
      FETCH c_posSessionFiles INTO rPosSessionFile;
    END LOOP;
    Close c_posSessionFiles;
  EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE( 'Erro on export DataSale ' || SQLERRM );
  End;
END;
/
