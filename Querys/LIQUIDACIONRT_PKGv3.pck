CREATE OR REPLACE PACKAGE LIQUIDACIONRT_PKG AS

   procedure LIQUIDACIONRYT_USOS(FECHA_LIM DATE);
   PROCEDURE LIQUIDACION_REC(FECHA_LIM DATE);
   PROCEDURE VALOR_CONSIGNAR_BANCOS(P_FECHA_LIQ DATE);
   PROCEDURE LIQUIDACIONRYT_USOS_VISA(FECHA_LIM DATE);
   PROCEDURE LIQUIDACIONRYT_USOS_SW_MIFARE(FECHA_LIM DATE);

END LIQUIDACIONRT_PKG;
/
CREATE OR REPLACE PACKAGE BODY LIQUIDACIONRT_PKG AS

  /*******************************************************************************
  Objeto          : procedure
  Nombre          : LIQUIDACIONRYT
  Descripcion     :
  
  Parametros      :
  Realizado por   : Gustavo Adolfo Cortes Ayala
  Fecha           : 03-08-2020
  Actualizado por : CLEARING
  Fecha           : 24-01-2023
  *******************************************************************************/

  procedure LIQUIDACIONRYT_USOS(FECHA_LIM DATE) IS
  
    -- CURSOR FECHAS LIMITES DE LIQUIDACION
    CURSOR C_FECHAS_LIQUIDACION(FECHA_LIM IN DATE) IS
      SELECT A.DATE_LIQ_MIN, A.DATE_LIQ_MAX
        FROM MERCURY.TBL_LIQUIDACIONRYT_DATE A
       WHERE A.DATE_LIQ = FECHA_LIM --TO_DATE('31-07-2020', 'DD-MM-YYYY')
         AND A.USOS IS NULL;
  
    --CURSOR USOS LIQUIDABLES, EXTRAE TODOS LOS USOS CORRESPONDIENTES A LA FECHA DE CONCILIACION
    CURSOR C_REGISTROS(FECHA_MIN IN DATE, FECHA_MAX IN DATE) IS
      SELECT ld.ld_id,
             app.app_descshort,
             CU.ISS_ID,
             CU.CD_ID,
             CU.CRD_SNR,
             CU.APP_ID,
             cu.cu_tsn,
             cu.cu_itg_ctr,
             cu.cu_datetime,
             cu_dat_inc_puente,
             udf.veh_id,
             udf.tp_id,
             --cu.cu_farevalue * 1000 AS CU_FAREVALUE,
             CASE
               WHEN ((cu.app_id = 902 OR cu.app_id = 920) AND
                    cu.cu_itg_ctr IS NULL) THEN
                CASE
                  WHEN (TRUNC(cu.cu_datetime) <
                       to_date('24/01/2022', 'dd-mm-yyyy')) THEN
                   2200
                  WHEN ((TRUNC(cu.cu_datetime) >=
                       to_date('24/01/2022', 'dd-mm-yyyy')) and
                       (TRUNC(cu.cu_datetime) <=
                       to_date('22/01/2023', 'dd-mm-yyyy'))) THEN
                   2400
                   /*WHEN ((TRUNC(cu.cu_datetime) >=
                       to_date('22/01/2023', 'dd-mm-yyyy')) and
                       (TRUNC(cu.cu_datetime) <=
                       to_date('14/02/2024', 'dd-mm-yyyy'))) THEN
                   2700*/
                  ELSE
                   2700
                   /*2900*/
                END
               ELSE
                cu.cu_farevalue * 1000
             END AS CU_FAREVALUE, --***** Modificacion Farevalue
             COUNT(1) AS QPAX
        FROM mercury.CARDUSAGE        cu,
             mercury.linedetails      ld,
             mercury.USAGEDATATRIPMT  udtm,
             mercury.USAGEDATASERVICE uds,
             mercury.USAGEDATAFILE    udf,
             mercury.applications     app
       WHERE 1 = 1
         AND CU.UDTM_ID = UDTM.UDTM_ID
         AND UDTM.UDS_ID = UDS.UDS_ID
         AND UDS.UDF_ID = UDF.UDF_ID
         AND CU.cu_dat_inc_puente >= FECHA_MIN
            /* AND CU.cu_dat_inc_puente = TO_DATE ('08/08/8888 00:00', 'dd/mm/yyyy hh24:mi') -- Contingencia 12-12-2023*/
            /* AND CU.cu_dat_inc_puente = TO_DATE ('09/09/9999 00:00', 'dd/mm/yyyy hh24:mi') -- Contingencia 13-12-2023*/
            -- to_date('30-07-2020 06:59', 'dd-mm-yyyy hh24:mi') --Fecha Tabla Puente
         AND CU.cu_dat_inc_puente <= FECHA_MAX
            -- to_date('31-07-2020 09:59', 'dd-mm-yyyy hh24:mi')
         AND cu.cut_id = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
         AND NVL(cu.cu_partfareseqnbr, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
         AND app.app_id = cu.app_id
         AND ld.ld_id = cu.ld_id
         AND udf.tp_id not in (25, 52) --*** 52 - 
         AND ((CU.cu_farevalue > 0 or cu.cu_itg_ctr is not null) or
             CU.app_id in (920, 902)) -- Solo usos pagos
      
       GROUP BY ld.ld_id,
                app.app_descshort,
                cu.cu_itg_ctr,
                -- to_char(cu.cu_datetime, 'YYYY-MM-DD'),
                cu.cu_datetime,
                cu_dat_inc_puente,
                udf.veh_id,
                cu.cu_farevalue * 1000,
                CU.ISS_ID,
                CU.CD_ID,
                CU.CRD_SNR,
                CU.APP_ID,
                cu.cu_tsn,
                udf.tp_id
      -- TO_DATE('31-07-2020 10:00:00', 'DD-MM-YYYY HH24:MI:SS')
      ;
  
    -- BUSCA USOS QUE NO TIENEN FECHA DE LIQUIDACION, ESTO SE DEBE AL MOMENTO DE TRANSMISION TENIAN LA MISMA FECHA, QUEDAN PENDIENTES PARA EL
    -- SIGUIENTE CICLO DE CONCILIACION
  
    CURSOR C_USOS_PENDIENTES IS
      SELECT *
        FROM MERCURY.TBL_LIQUIDACIONRYT_USOS A
       WHERE A.CLEARING_DATE IS NULL
         AND A.TP_ID NOT IN (999) --Nuevo
      ;
  
    R_USOSLIQUIDADOS MERCURY.TBL_LIQUIDACIONRYT_USOS%ROWTYPE;
    EXISTE_TRX_TSN   NUMBER(1) := 3;
  
  BEGIN
  
    FOR RCDATE IN C_FECHAS_LIQUIDACION(FECHA_LIM) LOOP
    
      -- MARCA EN EL CALENDARIO QUE YA PROCESO USOS PARA EL DIA DE LIQUIDACION
    
      UPDATE MERCURY.TBL_LIQUIDACIONRYT_DATE A
         SET A.USOS = 1
       WHERE A.DATE_LIQ = FECHA_LIM --TO_DATE('31-07-2020', 'DD-MM-YYYY')
      ;
    
      FOR RCLIQUIDACION IN C_REGISTROS(RCDATE.DATE_LIQ_MIN, RCDATE.DATE_LIQ_MAX) LOOP
      
        R_USOSLIQUIDADOS.LD_ID             := RCLIQUIDACION.LD_ID;
        R_USOSLIQUIDADOS.APP_DESCSHORT     := RCLIQUIDACION.APP_DESCSHORT;
        R_USOSLIQUIDADOS.ISS_ID            := RCLIQUIDACION.ISS_ID;
        R_USOSLIQUIDADOS.CD_ID             := RCLIQUIDACION.CD_ID;
        R_USOSLIQUIDADOS.CRD_SNR           := RCLIQUIDACION.CRD_SNR;
        R_USOSLIQUIDADOS.APP_ID            := RCLIQUIDACION.APP_ID;
        R_USOSLIQUIDADOS.CU_TSN            := RCLIQUIDACION.CU_TSN;
        R_USOSLIQUIDADOS.CU_ITG_CTR        := RCLIQUIDACION.CU_ITG_CTR;
        R_USOSLIQUIDADOS.CU_DATETIME       := RCLIQUIDACION.CU_DATETIME;
        R_USOSLIQUIDADOS.CU_DAT_INC_PUENTE := RCLIQUIDACION.CU_DAT_INC_PUENTE;
        R_USOSLIQUIDADOS.VEH_ID            := RCLIQUIDACION.VEH_ID;
        R_USOSLIQUIDADOS.CU_FAREVALUE      := RCLIQUIDACION.CU_FAREVALUE;
        R_USOSLIQUIDADOS.QPAX              := RCLIQUIDACION.QPAX;
        R_USOSLIQUIDADOS.CLEARING_DATE     := FECHA_LIM; --TO_DATE('31-07-2020','DD-MM-YYYY');
        R_USOSLIQUIDADOS.TP_ID             := RCLIQUIDACION.TP_ID;
        R_USOSLIQUIDADOS.CLEARING_REG      := SYSDATE;
      
        /*****************************************(21/07/2022)********************************************************
        *****Control de duplicidad de ISS_ID, CD_ID, CRD_SNR, APP_ID y CU_TSN en la tabla TBL_LIQUIDACIONRYT_USOS*****   
        ******************************************(21/07/2022)*******************************************************/
      
        SELECT COUNT(1)
          INTO EXISTE_TRX_TSN
          FROM DUAL
         WHERE EXISTS (SELECT 1
                  FROM MERCURY.TBL_LIQUIDACIONRYT_USOS A
                 WHERE A.ISS_ID = RCLIQUIDACION.ISS_ID
                   AND A.CD_ID = RCLIQUIDACION.CD_ID
                   AND A.CRD_SNR = RCLIQUIDACION.CRD_SNR
                   AND A.APP_ID = RCLIQUIDACION.APP_ID
                   AND A.CU_TSN = RCLIQUIDACION.CU_TSN);
      
        IF EXISTE_TRX_TSN = 0 THEN
        
          INSERT INTO MERCURY.TBL_LIQUIDACIONRYT_USOS
          VALUES R_USOSLIQUIDADOS;
        
          COMMIT;
        END IF;
      END LOOP;
    END LOOP;
  
    --- BUSCA TRANSACCIONES QUE NO TIENEN FECHA DE LIQUIDACION Y LAS ACTUALIZA CON EL CICLO ACTUAL
  
    FOR RPENDIENTE IN C_USOS_PENDIENTES LOOP
    
      -- Dbms_Output.Put_Line ('RPENDIENTE.CU_DATETIME: ' || RPENDIENTE.CU_DATETIME);
      -- Dbms_Output.Put_Line ('FECHA_LIM: ' || FECHA_LIM);
    
      IF RPENDIENTE.CU_DATETIME < FECHA_LIM THEN
      
        UPDATE MERCURY.TBL_LIQUIDACIONRYT_USOS A
           SET A.CLEARING_DATE = FECHA_LIM
         WHERE RPENDIENTE.ISS_ID = A.ISS_ID
           AND RPENDIENTE.CD_ID = A.CD_ID
           AND RPENDIENTE.CRD_SNR = A.CRD_SNR
           AND RPENDIENTE.APP_ID = A.APP_ID
           AND RPENDIENTE.CU_TSN = A.CU_TSN
           AND RPENDIENTE.CU_DATETIME = A.CU_DATETIME;
      
        COMMIT;
      END IF;
    END LOOP;
  
    --- ACTUALIZA FECHA DE LIQUIDACION, USOS QUE CORESPONDEN AL MISMO DIA CONCILIADO
    UPDATE MERCURY.TBL_LIQUIDACIONRYT_USOS A
       SET A.CLEARING_DATE = NULL
     WHERE TRUNC(A.CU_DATETIME) = A.CLEARING_DATE
       AND A.TP_ID NOT IN (999);
  
    COMMIT;
  
  end LIQUIDACIONRYT_USOS;

  --////////////////////////////////////////////////////////////////
  -- PROCEDIMIENTO PARA LIQUIDAR RECARGAS DE MERCURY Y NETSALES ///
  --///////////////////////////////////////////////////////////////

  PROCEDURE LIQUIDACION_REC(FECHA_LIM DATE) IS
  
    -- CURSOR FECHAS LIMITES DE LIQUIDACION
    CURSOR C_FECHAS_LIQUIDACION(FECHA_LIM IN DATE) IS
      SELECT A.DATE_LIQ_MIN, A.DATE_LIQ_MAX
        FROM MERCURY.TBL_LIQUIDACIONRYT_DATE A
       WHERE A.DATE_LIQ = FECHA_LIM --TO_DATE('31-07-2020', 'DD-MM-YYYY')
         AND A.REC IS NULL;
  
    --CURSOR recargas LIQUIDABLES, EXTRAE TODOS LOS USOS CORRESPONDIENTES A LA FECHA DE CONCILIACION
    CURSOR C_REGISTROS(FECHA_MIN IN DATE, FECHA_MAX IN DATE) IS
      SELECT T.*
        FROM (SELECT a.tp_id,
                     b.ptd_regdate,
                     b.ptd_dat_inc_puente,
                     b.iss_id,
                     b.cd_id,
                     b.crd_snr,
                     b.pp_code,
                     b.pd_code,
                     b.ptd_tsn,
                     b.ptd_amount * 1000 AS ptd_amount,
                     count(*) QTRX
                from mercury.pos_tranmt   a,
                     mercury.pos_trandt   b,
                     mercury.pos_device   c,
                     mercury.pos_products d
               where a.ptm_trannbr = b.ptm_trannbr
                 and a.pd_code = b.pd_code
                 and b.ptd_status = 'A'
                 and b.ptd_dat_inc_puente >= FECHA_MIN -- TO_DATE('01-08-2020 06:01', 'DD-MM-YYYY HH24:MI')
                 and b.ptd_dat_inc_puente <= FECHA_MAX --TO_DATE('03-08-2020 06:59', 'DD-MM-YYYY HH24:MI')
                    --and b.ptd_regdate >= TO_DATE('16-07-2020 00:01', 'DD-MM-YYYY HH24:MI') --trunc(sysdate -1)
                    --and b.ptd_regdate <= TO_DATE('02-08-2020 23:59', 'DD-MM-YYYY HH24:MI') --trunc(sysdate)
                 and b.pd_code = c.pd_code
                 and b.pp_code = d.pp_code
                 and (b.pp_code in (24, 29, 30, 34, 37, 41) or
                     b.ptd_conf_date is not null) --*** CON Venta de Tarjetas
                    -- and (b.pp_code in (22) or b.ptd_conf_date is not null) --*** Solamente Recargas
                 AND b.PTM_TRANNBR = a.PTM_TRANNBR
                 AND b.PD_CODE = a.PD_CODE
                 AND a.PTM_STATUS = 'Z'
                 AND a.tp_id in (16, 44, 34)
               GROUP BY a.tp_id,
                        b.ptd_regdate,
                        b.ptd_dat_inc_puente,
                        b.iss_id,
                        b.cd_id,
                        b.crd_snr,
                        b.pp_code,
                        b.pd_code,
                        b.ptd_tsn,
                        b.ptd_amount * 1000
              
              UNION
              
              SELECT a.prv_master_id,
                     a.tr_trandate,
                     a.tr_trandate,
                     19,
                     a.trm_cd_id,
                     a.trm_crd_snr,
                     3,
                     a.pos_id,
                     a.trm_tsn,
                     a.tr_amount,
                     count(*)
                FROM mercury.tbl_ventas_netsales a
               WHERE a.tr_trandate >= TRUNC(FECHA_MIN) --TO_DATE('16-07-2020 00:01', 'DD-MM-YYYY HH24:MI')
                 AND a.tr_trandate <= TRUNC(FECHA_MAX) --TO_DATE('02-08-2020 23:59', 'DD-MM-YYYY HH24:MI')
               group by a.prv_master_id,
                        a.tr_trandate,
                        19,
                        a.trm_cd_id,
                        a.trm_crd_snr,
                        3,
                        a.pos_id,
                        a.trm_tsn,
                        a.tr_amount) T;
  
    -- BUSCA RECARGAS QUE NO TIENEN FECHA DE LIQUIDACION, ESTO SE DEBE AL MOMENTO DE TRANSMISION TENIAN LA MISMA FECHA, QUEDAN PENDIENTES PARA EL
    -- SIGUIENTE CICLO DE CONCILIACION
  
    CURSOR C_USOS_PENDIENTES IS
      SELECT *
        FROM MERCURY.TBL_LIQUIDACIONRYT_REC A
       WHERE A.CLEARING_DATE IS NULL
         AND ((A.PTD_TSN IS NOT NULL) OR (A.PP_CODE IN (24, 34))) --NO TRAE VENTAS DE TARJETAS CON LIQUIDACION REZAGADA
      ;
  
    R_RECLIQUIDADOS MERCURY.TBL_LIQUIDACIONRYT_REC%ROWTYPE;
  
  BEGIN
  
    FOR RCDATE IN C_FECHAS_LIQUIDACION(FECHA_LIM) LOOP
    
      -- MARCA EN EL CALENDARIO QUE YA PROCESO RECARGAS PARA EL DIA DE LIQUIDACION
    
      UPDATE MERCURY.TBL_LIQUIDACIONRYT_DATE A
         SET A.REC = 1
       WHERE A.DATE_LIQ = FECHA_LIM --TO_DATE('31-07-2020', 'DD-MM-YYYY')
      ;
      COMMIT;
    
      --DBMS_OUTPUT.PUT_LINE( 'Antes de insertar registros REC');
    
      FOR RECLIQUIDACION IN C_REGISTROS(RCDATE.DATE_LIQ_MIN, RCDATE.DATE_LIQ_MAX) LOOP
      
        R_RECLIQUIDADOS.TP_ID              := RECLIQUIDACION.TP_ID;
        R_RECLIQUIDADOS.PTD_REGDATE        := RECLIQUIDACION.PTD_REGDATE;
        R_RECLIQUIDADOS.PTD_DAT_INC_PUENTE := RECLIQUIDACION.PTD_DAT_INC_PUENTE;
        R_RECLIQUIDADOS.ISS_ID             := RECLIQUIDACION.ISS_ID;
        R_RECLIQUIDADOS.CD_ID              := RECLIQUIDACION.CD_ID;
        R_RECLIQUIDADOS.CRD_SNR            := RECLIQUIDACION.CRD_SNR;
        R_RECLIQUIDADOS.PP_CODE            := RECLIQUIDACION.PP_CODE;
        R_RECLIQUIDADOS.PD_CODE            := RECLIQUIDACION.PD_CODE;
        R_RECLIQUIDADOS.PTD_TSN            := RECLIQUIDACION.PTD_TSN;
        R_RECLIQUIDADOS.PTD_AMOUNT         := RECLIQUIDACION.PTD_AMOUNT;
        R_RECLIQUIDADOS.QTRX               := RECLIQUIDACION.QTRX;
        R_RECLIQUIDADOS.CLEARING_DATE      := FECHA_LIM;
      
        INSERT INTO MERCURY.TBL_LIQUIDACIONRYT_REC VALUES R_RECLIQUIDADOS;
      
      END LOOP;
    END LOOP;
    COMMIT;
  
    --DBMS_OUTPUT.PUT_LINE( 'Despues de insertar registros REC');
  
    FOR RPENDIENTE IN C_USOS_PENDIENTES LOOP
    
      --DBMS_OUTPUT.PUT_LINE( 'EMPIEZA CON CICLO LOOP');
    
      IF RPENDIENTE.PTD_REGDATE < FECHA_LIM THEN
      
        UPDATE MERCURY.TBL_LIQUIDACIONRYT_REC A
           SET A.CLEARING_DATE = FECHA_LIM
         WHERE RPENDIENTE.ISS_ID = A.ISS_ID
           AND RPENDIENTE.CD_ID = A.CD_ID
           AND RPENDIENTE.CRD_SNR = A.CRD_SNR
           AND RPENDIENTE.PTD_TSN = A.PTD_TSN
           AND RPENDIENTE.PTD_REGDATE = A.PTD_REGDATE;
      
      END IF;
    END LOOP;
    COMMIT;
  
    --DBMS_OUTPUT.PUT_LINE( 'Despues de marcar registros pendientes liq para REC');
  
    /*****************************************(04/08/2022)********************************************************
    *****CONTROL DE MEDIOS DE PAGO INGRESADOS ANTES DE REALIZAR LIQUIDACI? POR CAMBIO DE TURNO DE TAQUILLERAS***** 
    ******************************************(04/08/2022)*******************************************************/
    /*UPDATE MERCURY.TBL_LIQUIDACIONRYT_REC A
       SET A.CLEARING_DATE = TRUNC(SYSDATE)
     WHERE A.PP_CODE IN (24, 34)
       AND A.CLEARING_DATE IS NULL;
    */
  
    --- ACTUALIZA FECHA DE LIQUIDACION, USOS QUE CORESPONDEN AL MISMO DIA CONCILIADO
  
    UPDATE MERCURY.TBL_LIQUIDACIONRYT_REC A
       SET A.CLEARING_DATE = NULL
     WHERE TRUNC(A.PTD_REGDATE) = A.CLEARING_DATE;
  
    COMMIT;
    --DBMS_OUTPUT.PUT_LINE( 'Despues de marcar registros pendientes manana para REC');
  
  END LIQUIDACION_REC;

  --***************************************************************************
  -- Created : 20/05/2021 04:00:00 p.m.
  -- Purpose : Realiza la liquidacion de USOS VISA
  PROCEDURE LIQUIDACIONRYT_USOS_VISA(FECHA_LIM DATE) IS
  
    -- CURSOR FECHAS LIMITES DE LIQUIDACION
    CURSOR C_FECHAS_LIQUIDACION(FECHA_LIM IN DATE) IS
      SELECT A.DATE_LIQ_MIN, A.DATE_LIQ_MAX
        FROM MERCURY.TBL_LIQUIDACIONRYT_DATE A
       WHERE A.DATE_LIQ = FECHA_LIM
         AND A.USOS_VISA IS NULL;
  
    --CURSOR USOS LIQUIDABLES
    CURSOR C_REGISTROS(FECHA_MIN IN DATE, FECHA_MAX IN DATE) IS
      SELECT CASE
               WHEN a.route_id = 'BUS NO REG RUTA' THEN
                '236' --Generica P99
               WHEN a.route_id = 'ESTACION SIN RUTA' THEN
                '235' -- A99
               WHEN a.route_id = 'P000' THEN
                '164'
               WHEN a.route_id IS NULL THEN
                '236'
               ELSE
                a.route_id
             END AS LD_ID,
             'VISA' AS APP_DESCSHORT,
             19 AS ISS_ID,
             99 AS CD_ID,
             a.bin || a.last4 AS BIN_LAST4, --crd snr
             a.card_number,
             999 AS APP_ID,
             a.tsn_reg,
             CASE
               WHEN a.is_transfer = 0 OR a.is_transfer = 1 THEN
                ''
               WHEN a.is_transfer = 2 THEN
                '1'
               WHEN a.is_transfer = 3 THEN
                '2'
               ELSE
                '1'
             END AS CU_ITG_CTR,
             a.entry_date,
             a.fecha_ws,
             a.response_date,
             a.visa_dat_inc_puente,
             a.device_id,
             999 AS TP_ID,
             a.importe AS IMPORTE,
             a.att2_dat AS COLLEC_DATE,
             --CASE
             --   WHEN a.importe = 2400 THEN
             --    2200
             --   ELSE
             --    a.importe
             --END AS IMPORTE,
             COUNT(*) AS QPAX
      
        FROM Mercury.tbl_trx_utrytopcs a
       WHERE a.status = 'A'
         AND a.processed = 'S'
         AND trunc(a.visa_dat_inc_puente) =
             to_date('05/05/5555', 'dd-mm-yyyy')
         AND a.fecha_ws >= TRUNC(FECHA_MIN)
      --AND a.att2_dat is not null
      --AND a.fecha_ws >= FECHA_MIN
      --AND a.fecha_ws <= FECHA_MAX
      
       GROUP BY a.route_id,
                a.bin || a.last4,
                a.card_number,
                a.tsn_reg,
                a.is_transfer,
                a.entry_date,
                a.visa_dat_inc_puente,
                a.device_id,
                a.importe,
                a.fecha_ws,
                a.response_date,
                a.att2_dat
      
      UNION
      
      SELECT CASE
               WHEN a.route_id = 'BUS NO REG RUTA' THEN
                '236' --Generica P99
               WHEN a.route_id = 'ESTACION SIN RUTA' THEN
                '235' -- A99
               WHEN a.route_id = 'P000' THEN
                '164'
               WHEN a.route_id IS NULL THEN
                '236'
               ELSE
                a.route_id
             END AS LD_ID,
             'VISA' AS APP_DESCSHORT,
             19 AS ISS_ID,
             99 AS CD_ID,
             a.bin || a.last4 AS BIN_LAST4, --crd snr
             a.card_number,
             999 AS APP_ID,
             a.tsn_reg,
             CASE
               WHEN a.is_transfer = 0 OR a.is_transfer = 1 THEN
                ''
               WHEN a.is_transfer = 2 THEN
                '1'
               WHEN a.is_transfer = 3 THEN
                '2'
               ELSE
                '1'
             END AS CU_ITG_CTR,
             a.entry_date,
             a.fecha_ws,
             a.response_date,
             a.visa_dat_inc_puente,
             a.device_id,
             999 AS TP_ID,
             a.importe AS IMPORTE,
             a.att2_dat AS COLLEC_DATE,
             --CASE
             --   WHEN a.importe = 2400 THEN
             --    2200
             --   ELSE
             --    a.importe
             --END AS IMPORTE,
             COUNT(*) AS QPAX
      
        FROM Mercury.tbl_trx_utrytopcs a
       WHERE a.status = 'A'
         AND a.processed = 'C'
         AND trunc(a.visa_dat_inc_puente) =
             To_date('05/05/5555', 'dd-mm-yyyy')
         AND a.fecha_ws >= TRUNC(FECHA_MIN)
         AND a.att2_dat is not null
      --AND a.fecha_ws >= FECHA_MIN
      --AND a.fecha_ws <= FECHA_MAX
      
       GROUP BY a.route_id,
                a.bin || a.last4,
                a.card_number,
                a.tsn_reg,
                a.is_transfer,
                a.entry_date,
                a.visa_dat_inc_puente,
                a.device_id,
                a.importe,
                a.fecha_ws,
                a.response_date,
                a.att2_dat
       ORDER BY 10, 6, 8 ASC;
  
    CURSOR C_USOS_PENDIENTES_VISA IS
      SELECT *
        FROM MERCURY.TBL_LIQUIDACIONRYT_USOS A
       WHERE A.CLEARING_DATE IS NULL
         AND A.TP_ID = 999;
  
    R_USOSLIQUIDADOS MERCURY.TBL_LIQUIDACIONRYT_USOS%ROWTYPE;
  
  BEGIN
  
    FOR RCDATE IN C_FECHAS_LIQUIDACION(FECHA_LIM) LOOP
    
      FOR RCLIQUIDACION IN C_REGISTROS(RCDATE.DATE_LIQ_MIN, RCDATE.DATE_LIQ_MAX) LOOP
      
        R_USOSLIQUIDADOS.LD_ID             := RCLIQUIDACION.LD_ID;
        R_USOSLIQUIDADOS.APP_DESCSHORT     := RCLIQUIDACION.APP_DESCSHORT;
        R_USOSLIQUIDADOS.ISS_ID            := RCLIQUIDACION.ISS_ID;
        R_USOSLIQUIDADOS.CD_ID             := RCLIQUIDACION.CD_ID;
        R_USOSLIQUIDADOS.CRD_SNR           := RCLIQUIDACION.BIN_LAST4;
        R_USOSLIQUIDADOS.CARD_NUMBER_VISA  := RCLIQUIDACION.CARD_NUMBER;
        R_USOSLIQUIDADOS.APP_ID            := RCLIQUIDACION.APP_ID;
        R_USOSLIQUIDADOS.CU_TSN            := RCLIQUIDACION.TSN_REG;
        R_USOSLIQUIDADOS.CU_ITG_CTR        := RCLIQUIDACION.CU_ITG_CTR;
        R_USOSLIQUIDADOS.CU_DATETIME       := RCLIQUIDACION.ENTRY_DATE;
        R_USOSLIQUIDADOS.CU_DAT_INC_PUENTE := RCLIQUIDACION.FECHA_WS;
        R_USOSLIQUIDADOS.VEH_ID            := RCLIQUIDACION.DEVICE_ID;
        R_USOSLIQUIDADOS.CU_FAREVALUE      := RCLIQUIDACION.IMPORTE;
        R_USOSLIQUIDADOS.QPAX              := RCLIQUIDACION.QPAX;
        R_USOSLIQUIDADOS.CLEARING_DATE     := FECHA_LIM; --TO_DATE('31-07-2020','DD-MM-YYYY');
        R_USOSLIQUIDADOS.TP_ID             := RCLIQUIDACION.TP_ID;
        R_USOSLIQUIDADOS.CLEARING_REG      := SYSDATE;
      
        INSERT INTO MERCURY.TBL_LIQUIDACIONRYT_USOS
        VALUES R_USOSLIQUIDADOS;
      END LOOP;
    
      COMMIT;
    
      -- MARCA LAS TRANSACCIONES LIQUIDADAS TIPO S
      UPDATE Mercury.tbl_trx_utrytopcs a
         SET a.visa_dat_inc_puente = SYSDATE,
             a.att3_num            = 10,
             a.att1_dat            = to_date('05/05/5555', 'dd-mm-yyyy')
       WHERE a.status = 'A'
         AND a.processed = 'S'
         AND trunc(a.visa_dat_inc_puente) =
             to_date('05/05/5555', 'dd-mm-yyyy')
         AND a.fecha_ws >= TRUNC(RCDATE.DATE_LIQ_MIN) -- AND a.fecha_ws < TRUNC(SYSDATE)
         AND a.att3_num is null;
    
      COMMIT;
    
      -- MARCA LAS TRANSACCIONES LIQUIDADAS TIPO C (MODIFICADO : 15/11/2022)
      UPDATE Mercury.tbl_trx_utrytopcs a
         SET a.visa_dat_inc_puente = SYSDATE,
             a.att3_num            = 10,
             a.att1_dat            = to_date('05/05/5555', 'dd-mm-yyyy')
       WHERE a.status = 'A'
         AND a.processed = 'C'
         AND trunc(a.visa_dat_inc_puente) =
             to_date('05/05/5555', 'dd-mm-yyyy')
         AND a.att2_dat is not null -- AND a.fecha_ws < TRUNC(SYSDATE)
         AND a.att3_num is null;
    
      COMMIT;
    
    END LOOP;
  
    -- MARCA EN EL CALENDARIO QUE YA PROCESO USOS PARA EL DIA DE LIQUIDACION
    UPDATE MERCURY.TBL_LIQUIDACIONRYT_DATE A
       SET A.USOS_VISA = 1
     WHERE A.DATE_LIQ = FECHA_LIM;
    COMMIT;
  
    --- BUSCA TRANSACCIONES QUE NO TIENEN FECHA DE LIQUIDACION Y LAS ACTUALIZA CON EL CICLO ACTUAL
    FOR RPENDIENTE IN C_USOS_PENDIENTES_VISA LOOP
    
      IF RPENDIENTE.CU_DATETIME < FECHA_LIM THEN
      
        UPDATE MERCURY.TBL_LIQUIDACIONRYT_USOS A
           SET A.CLEARING_DATE = FECHA_LIM
         WHERE RPENDIENTE.ISS_ID = A.ISS_ID
           AND RPENDIENTE.CD_ID = A.CD_ID
           AND RPENDIENTE.CRD_SNR = A.CRD_SNR
           AND RPENDIENTE.CARD_NUMBER_VISA = A.CARD_NUMBER_VISA
           AND RPENDIENTE.APP_ID = A.APP_ID
           AND RPENDIENTE.CU_TSN = A.CU_TSN
           AND RPENDIENTE.CU_DATETIME = A.CU_DATETIME;
      
        COMMIT;
      END IF;
    END LOOP;
  
    --- ACTUALIZA FECHA DE LIQUIDACION, USOS QUE CORESPONDEN AL MISMO DIA CONCILIADO
    UPDATE MERCURY.TBL_LIQUIDACIONRYT_USOS A
       SET A.CLEARING_DATE = NULL
     WHERE TRUNC(A.CU_DATETIME) = A.CLEARING_DATE
       AND A.TP_ID = 999;
  
    COMMIT;
  
  END LIQUIDACIONRYT_USOS_VISA;
  --***************************************************************************
  -- Created : 02/05/2024 04:00:00 p.m.
  -- Purpose : Realiza la liquidacion de USOS MIFARE
  PROCEDURE LIQUIDACIONRYT_USOS_SW_MIFARE(FECHA_LIM DATE) IS
  
    CURSOR C_FECHAS_LIQUIDACION(FECHA_LIM IN DATE) IS
      SELECT A.DATE_LIQ_MIN, A.DATE_LIQ_MAX
        FROM MERCURY.TBL_LIQUIDACIONRYT_DATE A
       WHERE A.DATE_LIQ = FECHA_LIM
         AND A.USOS_MIFARE IS NULL;
  
    CURSOR C_REGISTROS(FECHA_MIN IN DATE, FECHA_MAX IN DATE) IS
      SELECT *
        FROM (WITH
             -- Consulta a tarjetas 
             TARJETA AS (SELECT c.ISS_ID, c.CD_ID, c.CRD_SNR, c.CRD_INTSNR
                           FROM MERCURY.CARDS c
                           WHERE c.CRD_INTSNR <> 3012078720),
             -- Consulta a aplicaciones
             APLICACIONES AS (SELECT a.APP_ID, a.APP_DESCSHORT
                                FROM MERCURY.APPLICATIONS a),
             -- Consulta a sw_mifare_trx condicionado, se  agrega campos tp_id = 16 y convirtiendo valor real a pesos
             SW_MIFARE AS (SELECT sw.*,
                                  16 AS TP_ID,
                                  (sw.FEE * 10) AS FAREVALUE
                             FROM MERCURY.sw_mifare_trx sw
                            WHERE TRUNC(SW.CU_DAT_INC_PUENTE) =
                                  TO_DATE('06/06/6666', 'dd-mm-yyyy')
                              AND sw.CREATED >= FECHA_MIN
                              AND sw.CREATED <= FECHA_MAX
                              AND sw.BUS_ID NOT IN
                                  (85001, 85002, 85003, 85004, 85005)
                              AND SW.TERMINAL_ID <> 1500030409
                              AND (sw.USE_TYPE = 0 OR sw.FEE > 0))
               SELECT sw.LINE_ID,
                      a.APP_DESCSHORT,
                      t.ISS_ID,
                      t.CD_ID,
                      t.CRD_SNR,
                      sw.APP_ID,
                      sw.TSN,
                      sw.USE_TYPE,
                      -- control de integracion 0 -> 'uso pago' 1 -> integracion
                      sw.TRX_DATE,
                      sw.CREATED,
                      sw.BUS_ID,
                      sw.TP_ID,
                      sw.FAREVALUE,
                      COUNT(1) AS QPAX
                 FROM SW_MIFARE sw
                 JOIN TARJETA t
                   ON (sw.UUID = t.CRD_INTSNR)
                 JOIN APLICACIONES a
                   ON (sw.APP_ID = a.APP_ID)
                 JOIN LINEDETAILS l
                   ON (sw.line_id = l.ld_id)
                WHERE 1 = 1
                GROUP BY sw.LINE_ID,
                         a.APP_DESCSHORT,
                         t.ISS_ID,
                         t.CD_ID,
                         t.CRD_SNR,
                         sw.APP_ID,
                         sw.TSN,
                         sw.USE_TYPE,
                         sw.TRX_DATE,
                         sw.CREATED,
                         sw.BUS_ID,
                         sw.TP_ID,
                         sw.FAREVALUE);
  
  
    -- BUSCA USOS QUE NO TIENEN FECHA DE LIQUIDACION, ESTO SE DEBE AL MOMENTO DE TRANSMISION TENIAN LA MISMA FECHA, QUEDAN PENDIENTES PARA EL
    -- SIGUIENTE CICLO DE CONCILIACION
  
    CURSOR C_USOS_PENDIENTES IS
      SELECT *
        FROM MERCURY.TBL_LIQUIDACIONRYT_USOS A
       WHERE A.CLEARING_DATE IS NULL
         AND A.TP_ID NOT IN (999);
  
    R_USOSLIQUIDADOS MERCURY.TBL_LIQUIDACIONRYT_USOS%ROWTYPE;
  
    EXISTE_TRX_TSN NUMBER(1) := 3;
  
  BEGIN
    FOR RCDATE IN C_FECHAS_LIQUIDACION(FECHA_LIM) LOOP
      --Abre y recorre CURSOR fechas de liquidacion 
      UPDATE MERCURY.TBL_LIQUIDACIONRYT_DATE A
         SET A.USOS_MIFARE = 1
       WHERE A.DATE_LIQ = FECHA_LIM;
    
      FOR RCLIQUIDACION IN C_REGISTROS(RCDATE.DATE_LIQ_MIN, RCDATE.DATE_LIQ_MAX) LOOP
      
        R_USOSLIQUIDADOS.LD_ID := RCLIQUIDACION.LINE_ID;
      
        R_USOSLIQUIDADOS.APP_DESCSHORT := RCLIQUIDACION.APP_DESCSHORT;
      
        R_USOSLIQUIDADOS.ISS_ID := RCLIQUIDACION.ISS_ID;
      
        R_USOSLIQUIDADOS.CD_ID := RCLIQUIDACION.CD_ID;
      
        R_USOSLIQUIDADOS.CRD_SNR := RCLIQUIDACION.CRD_SNR;
      
        R_USOSLIQUIDADOS.APP_ID := RCLIQUIDACION.APP_ID;
      
        R_USOSLIQUIDADOS.CU_TSN := RCLIQUIDACION.TSN;
      
        R_USOSLIQUIDADOS.CU_ITG_CTR := RCLIQUIDACION.USE_TYPE;
      
        R_USOSLIQUIDADOS.CU_DATETIME := RCLIQUIDACION.TRX_DATE;
      
        R_USOSLIQUIDADOS.CU_DAT_INC_PUENTE := RCLIQUIDACION.CREATED;
      
        R_USOSLIQUIDADOS.VEH_ID := RCLIQUIDACION.BUS_ID;
      
        R_USOSLIQUIDADOS.CU_FAREVALUE := RCLIQUIDACION.FAREVALUE;
      
        R_USOSLIQUIDADOS.QPAX := RCLIQUIDACION.QPAX;
      
        R_USOSLIQUIDADOS.CLEARING_DATE := FECHA_LIM; -- fecha que se ejecuta el procedure
        R_USOSLIQUIDADOS.TP_ID         := RCLIQUIDACION.TP_ID;
      
        R_USOSLIQUIDADOS.CLEARING_REG := SYSDATE;
      
        /*****Control de duplicidad de ISS_ID, CD_ID, CRD_SNR, APP_ID y CU_TSN en la tabla TBL_LIQUIDACIONRYT_USOS*****/
        SELECT COUNT(1)
          INTO EXISTE_TRX_TSN
          FROM DUAL
         WHERE EXISTS (SELECT 1
                  FROM MERCURY.TBL_LIQUIDACIONRYT_USOS A
                 WHERE A.ISS_ID = RCLIQUIDACION.ISS_ID
                   AND A.CD_ID = RCLIQUIDACION.CD_ID
                   AND A.CRD_SNR = RCLIQUIDACION.CRD_SNR
                   AND A.APP_ID = RCLIQUIDACION.APP_ID
                   AND A.CU_TSN = RCLIQUIDACION.TSN);
      
        IF EXISTE_TRX_TSN = 0 THEN
          INSERT INTO MERCURY.TBL_LIQUIDACIONRYT_USOS
          VALUES R_USOSLIQUIDADOS;
        
          COMMIT;
        END IF;
      END LOOP;
      UPDATE Mercury.sw_mifare_trx sw
         SET sw.cu_dat_inc_puente = SYSDATE
       WHERE TRUNC(sw.cu_dat_inc_puente) =
             TO_DATE('06/06/6666', 'dd-mm-yyyy')
         AND TRUNC(sw.created) >= TRUNC(RCDATE.DATE_LIQ_MIN) -- AND a.fecha_ws < TRUNC(SYSDATE)
         AND TRUNC(sw.trx_date) <> SYSDATE;
      
       COMMIT;
    END LOOP;
    --- BUSCA TRANSACCIONES QUE NO TIENEN FECHA DE LIQUIDACION Y LAS ACTUALIZA CON EL CICLO ACTUAL
  
    FOR RPENDIENTE IN C_USOS_PENDIENTES LOOP
    
      IF RPENDIENTE.CU_DATETIME < FECHA_LIM THEN
      
        UPDATE MERCURY.TBL_LIQUIDACIONRYT_USOS A
           SET A.CLEARING_DATE = FECHA_LIM
         WHERE RPENDIENTE.ISS_ID = A.ISS_ID
           AND RPENDIENTE.CD_ID = A.CD_ID
           AND RPENDIENTE.CRD_SNR = A.CRD_SNR
           AND RPENDIENTE.APP_ID = A.APP_ID
           AND RPENDIENTE.CU_TSN = A.CU_TSN
           AND RPENDIENTE.CU_DATETIME = A.CU_DATETIME;
      
        COMMIT;
      END IF;
    END LOOP;
    --- ACTUALIZA FECHA DE LIQUIDACION, USOS QUE CORESPONDEN AL MISMO DIA CONCILIADO
    UPDATE MERCURY.TBL_LIQUIDACIONRYT_USOS A
       SET A.CLEARING_DATE = NULL
     WHERE TRUNC(A.CU_DATETIME) = A.CLEARING_DATE
       AND A.TP_ID NOT IN (999);
  
    COMMIT;
  END LIQUIDACIONRYT_USOS_SW_MIFARE;

  --***************************************************************************
  -- Created : 25/08/2020 06:10:16 p.m.
  -- Purpose : Registra el Valor a Consignar de Bancos por fecha de liquidacion
  PROCEDURE VALOR_CONSIGNAR_BANCOS(P_FECHA_LIQ DATE) is
  
    --Consulta fecha liquidacion
    CURSOR C_FECHA_LIQ(P_FECHA IN DATE) IS
      SELECT A.DATE_LIQ_MIN, A.DATE_LIQ_MAX, A.USOS
        FROM MERCURY.TBL_LIQUIDACIONRYT_DATE A
       WHERE A.DATE_LIQ = P_FECHA
         AND A.USOS = 1;
  
    --Cursor que consulta informacion liquidada de bancos.
    CURSOR C_BANCOS(P_FECHA DATE) IS
      SELECT CASE
               WHEN a.app_id = 902 THEN
                20
               WHEN a.app_id = 920 THEN
                19
               ELSE
                0
             END AS TP_ID,
             TRUNC(a.clearing_date) AS FECHA_LIQ,
             TRUNC(a.clearing_date) AS FECHA, --TRUNC(a.cu_datetime)
             SUM(a.qpax) AS CANT_TRX,
             SUM(a.qpax * a.cu_farevalue) AS MONTO
      ---SUM(a.qpax) * 2200 AS MONTO  --***** REVISAR ****
      
        FROM mercury.tbl_liquidacionryt_usos a,
             mercury.cards                   b,
             mercury.userdocuments           c,
             mercury.cardsxusers             e
       WHERE a.app_id in (902, 920)
         AND TRUNC(a.clearing_date) = P_FECHA
         AND (a.cu_itg_ctr is null  or a.cu_itg_ctr = 0)
         and a.iss_id = b.iss_id
         and a.cd_id = b.cd_id
         and a.crd_snr = b.crd_snr
         and a.iss_id = e.iss_id
         and a.cd_id = e.cd_id
         and a.crd_snr = e.crd_snr
         and e.usr_id = c.usr_id
         and c.dt_id = 1
         and a.veh_id not in (85003) -- VALIDADOR DE PRUEBAS
      
       GROUP BY TRUNC(a.clearing_date), a.app_id;
  
    V_COUNT     NUMBER := 0;
    R_BANCOS    C_BANCOS%ROWTYPE;
    R_FECHA_LIQ C_FECHA_LIQ%ROWTYPE;
    R_TBL_VALOR Mercury.TBL_VALOR_CONSIGNAR_MRC%ROWTYPE;
  
  BEGIN
  
    --Consultamos fecha de liq
    OPEN C_FECHA_LIQ(P_FECHA_LIQ);
    LOOP
      FETCH C_FECHA_LIQ
        INTO R_FECHA_LIQ;
      EXIT WHEN C_FECHA_LIQ%Notfound;
    
      --Validamos que no se haya insertado registros para esta fecha
      SELECT count(*)
        INTO V_COUNT
        FROM Mercury.TBL_VALOR_CONSIGNAR_MRC a
       WHERE rownum = 1
         AND a.fecha_liq = P_FECHA_LIQ
         AND a.tp_id in (19, 20);
    
      IF V_COUNT = 0 THEN
      
        OPEN C_BANCOS(P_FECHA_LIQ);
        LOOP
          FETCH C_BANCOS
            INTO R_BANCOS;
          EXIT WHEN C_BANCOS%Notfound;
        
          R_TBL_VALOR.TP_ID     := R_BANCOS.TP_ID;
          R_TBL_VALOR.FECHA_LIQ := P_FECHA_LIQ;
          R_TBL_VALOR.FECHA_TRX := R_BANCOS.FECHA;
          R_TBL_VALOR.CANT_TRX  := R_BANCOS.CANT_TRX;
          R_TBL_VALOR.MONTO     := R_BANCOS.MONTO;
          R_TBL_VALOR.REGDATE   := SYSDATE;
          R_TBL_VALOR.REGUSER   := 'ADMIN';
        
          BEGIN
            INSERT INTO Mercury.TBL_VALOR_CONSIGNAR_MRC values R_TBL_VALOR;
            COMMIT;
          
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              DBMS_OUTPUT.PUT_LINE('No existe');
            WHEN OTHERS THEN
              DBMS_OUTPUT.PUT_LINE('Error Ejecutando el Proceso ' ||
                                   SQLERRM);
              ROLLBACK;
              RAISE;
          END;
        
        END LOOP;
        CLOSE C_BANCOS;
      
      END IF;
    
    END LOOP;
    CLOSE C_FECHA_LIQ;
  
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error Ejecutando el Proceso ' || SQLERRM);
      ROLLBACK;
    
  END VALOR_CONSIGNAR_BANCOS; --Fin procedure

END LIQUIDACIONRT_PKG;
/
