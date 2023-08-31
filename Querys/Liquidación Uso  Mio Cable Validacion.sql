SELECT fecha,
       SUM(monto) AS monto_usos,
       SUM(cantidad) AS cantidad_usos,
       tarifa,
       puente
  FROM (SELECT trunc(cu.cu_datetime) AS fecha,
               COUNT(cu.cu_unique_id) AS cantidad,
               CASE -- IDENTIFICA USOS POR TARIFA
                 WHEN ((cu.app_id = 902 OR cu.app_id = 920) AND
                      cu.cu_itg_ctr IS NULL) THEN
                  CASE
                    WHEN (trunc(cu.cu_datetime) <
                         TO_DATE('24/01/2022', 'dd-mm-yyyy')) THEN
                     2200
                    WHEN (trunc(cu.cu_datetime) BETWEEN
                         TO_DATE('25/01/2022', 'dd-mm-yyyy') AND
                         TO_DATE('22/01/2023', 'dd-mm-yyyy')) THEN
                     2400
                    ELSE
                     2700
                  END
                 ELSE
                  cu.cu_farevalue * 1000
               END AS tarifa,
               CASE -- MONTO TOTAL DE USOS POR TARIFA
                 WHEN ((cu.app_id = 902 OR cu.app_id = 920) AND
                      cu.cu_itg_ctr IS NULL) THEN
                  CASE
                    WHEN (trunc(cu.cu_datetime) <
                         TO_DATE('24/01/2022', 'dd-mm-yyyy')) THEN
                     2200 * COUNT(cu.cu_unique_id)
                    WHEN (trunc(cu.cu_datetime) BETWEEN
                         TO_DATE('25/01/2022', 'dd-mm-yyyy') AND
                         TO_DATE('22/01/2023', 'dd-mm-yyyy')) THEN
                     2400 * COUNT(cu.cu_unique_id)
                    ELSE
                     2700 * COUNT(cu.cu_unique_id)
                  END
                 ELSE
                  cu.cu_farevalue * COUNT(cu_unique_id) * 1000
               END AS monto,
               cu.cu_dat_inc_puente puente
          FROM mercury.cardusage        cu,
               mercury.linedetails      ld,
               mercury.usagedatatripmt  udtm,
               mercury.usagedataservice uds,
               mercury.usagedatafile    udf,
               mercury.applications     app
         WHERE 1 = 1
           AND cu.udtm_id = udtm.udtm_id
           AND udtm.uds_id = uds.uds_id
           AND uds.udf_id = udf.udf_id
           AND udf.udf_receivedate >=
               TO_DATE('16-06-2023 00:01', 'dd-mm-yyyy hh24:mi')
           AND udf.udf_receivedate <=
               TO_DATE('01-07-2023 23:59', 'dd-mm-yyyy hh24:mi')
           AND cu.cut_id = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
           AND nvl(cu.cu_partfareseqnbr, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
           AND app.app_id = cu.app_id
           AND ld.ld_id = cu.ld_id
           AND udf.tp_id IN (44, 45)
           AND (cu.cu_farevalue > 0 OR cu.app_id IN (920, 902)) -- Solo usos pagos (efectivo o bancos)
        --            AND to_char(cu.cu_datetime, 'yyyy') <> '2023'
        
         GROUP BY trunc(cu.cu_datetime),
                  cu.cu_farevalue,
                  cu.app_id,
                  cu.cu_itg_ctr,
                  cu.cu_datetime,
                  cu.cu_dat_inc_puente)
 GROUP BY fecha, tarifa, puente
 ORDER BY 1 ASC;
