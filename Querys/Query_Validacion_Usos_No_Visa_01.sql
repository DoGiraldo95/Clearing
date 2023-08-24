SELECT TRUNC(t.cu_datetime), COUNT (t.qpax)
/*MAX (t.cu_dat_inc_puente)*/ FROM(SELECT ld.ld_id,
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
                  ELSE
                   2700
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
         AND CU.cu_dat_inc_puente >= to_date('30-06-2023 7:59', 'dd-mm-yyyy hh24:mi') --Fecha Tabla Puente
         AND CU.cu_dat_inc_puente <=  to_date('04-07-2023 7:59', 'dd-mm-yyyy hh24:mi')
            -- to_date('31-07-2020 09:59', 'dd-mm-yyyy hh24:mi')
         AND cu.cut_id = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
         AND NVL(cu.cu_partfareseqnbr, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
         AND app.app_id = cu.app_id
         AND ld.ld_id = cu.ld_id
         AND udf.tp_id not in (25, 44) --*** 52 -
         AND ((CU.cu_farevalue > 0 or cu.cu_itg_ctr is not null) or
             CU.app_id in (920, 902)) -- Solo usos pagos
--       GROUP BY cu.cu_datetime;
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
                udf.tp_id) t
                WHERE t.cu_farevalue = 2700
                 GROUP BY TRUNC (t.cu_datetime);
