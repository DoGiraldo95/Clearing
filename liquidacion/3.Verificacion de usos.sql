--***********************************************************************************--
--************************ VERIFICACION USOS NO VISA POR TARIFA************************
/*SELECT  TRUNC(cu.cu_datetime) AS FECHA_USO,
        TRUNC(CU.cu_dat_inc_puente) FECHA_PUENTE,
        --to_char(CU.cu_dat_inc_puente, 'hh24') as HORA_PUENTE,
        TRUNC(UDF.udf_receivedate) FECHA_UDP,
        to_char(UDF.udf_receivedate, 'hh24') as HORA_UDP,
        ld.ld_desc      AS ESTACION,
        cu.cu_itg_ctr   AS INTEGRACION,
        app.app_descshort    AS PRODUCTO,
        udf.veh_id      AS VEH_ID,
        CASE
                   WHEN ((cu.app_id = 902 OR cu.app_id = 920) AND
                        cu.cu_itg_ctr IS NULL) THEN
                    CASE
                       WHEN (TRUNC(cu.cu_datetime) <
                            to_date('24/01/2022', 'dd-mm-yyyy')) THEN
                        2200
             WHEN (
                (TRUNC(cu.cu_datetime) >= to_date('24/01/2022', 'dd-mm-yyyy')) and 
                (TRUNC(cu.cu_datetime) <= to_date('22/01/2023', 'dd-mm-yyyy'))
              ) THEN 2400
                       ELSE
                        2700
            END
                   ELSE
                    cu.cu_farevalue * 1000
                END AS Monto,
        CASE
          WHEN LENGTH(udf.veh_id) < 5 THEN 'Estaciones'
          ELSE
            CASE
              WHEN SUBSTR(udf.veh_id,2,1) = 2 THEN 'Padron'
              WHEN SUBSTR(udf.veh_id,2,1) = 3 THEN 'Complementario'
              ELSE 'Otro'
            END
        END AS TIPOLOGIA,

        CASE
          WHEN to_number(to_char(CU.cu_dat_inc_puente, 'hh24')) > 7 THEN TRUNC(CU.cu_dat_inc_puente)
          ELSE
            CASE
              WHEN TRUNC(CU.cu_dat_inc_puente) = TRUNC(cu.cu_datetime) THEN TRUNC(CU.cu_dat_inc_puente)
              ELSE TRUNC(CU.cu_dat_inc_puente)-1
            END
        END AS FECHA_DIALIQ,
        COUNT(*)        AS CANTIDAD_USOS

  FROM  mercury.CARDUSAGE           cu,
        mercury.linedetails         ld,
        mercury.USAGEDATATRIPMT     udtm,
        mercury.USAGEDATASERVICE    uds,
        mercury.USAGEDATAFILE       udf,
        mercury.applications        app
  WHERE   CU.UDTM_ID = UDTM.UDTM_ID
  AND     UDTM.UDS_ID = UDS.UDS_ID
  AND     UDS.UDF_ID = UDF.UDF_ID
  --AND     cu.cu_datetime >= TO_DATE('18-05-2022 00:01', 'dd-mm-yyyy hh24:mi')
  --AND     cu.cu_datetime <= TO_DATE('18-05-2022 23:59', 'dd-mm-yyyy hh24:mi')
  AND  CU.cu_dat_inc_puente >= to_date('22-03-2023 07:59:00','dd-mm-yyyy hh24:mi:ss') --Fecha Tabla Puente --6am, 12pm, 4pm
  AND  CU.cu_dat_inc_puente <= to_date('24-03-2023 07:59:00','dd-mm-yyyy hh24:mi:ss')
  AND     cu.cut_id = 1       -- Tipos de uso -> 1: Passenger use, 5: On-board sale
  AND     NVL(cu.cu_partfareseqnbr,0) <> 2   -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
  AND     app.app_id = cu.app_id
  AND     ld.ld_id = cu.ld_id
  AND     udf.tp_id not in (25,44) --*** 44- MIO Cable
  AND  cu.cu_itg_ctr is null
  AND ((CU.cu_farevalue > 0) or CU.app_id in (920,902)) -- Solo usos pagos
  HAVING COUNT(*) = 1

GROUP BY ld.ld_desc,
app.app_descshort,
cu.app_id,
cu.cu_itg_ctr,
trunc(cu.cu_datetime),
TRUNC(CU.cu_dat_inc_puente),
app.app_descshort,
udf.veh_id,
to_char(CU.cu_dat_inc_puente, 'hh24'),
TRUNC(UDF.udf_receivedate),
to_char(UDF.udf_receivedate, 'hh24'),
cu.cu_farevalue
;*/
--***********************************************************************************--
--******************************** VERIFICACION USOS NO VISA ************************

--Fecha de Transaccion
SELECT trunc(cu.cu_datetime) AS fecha_uso,
       trunc(cu.cu_dat_inc_puente) fecha_puente,
       to_char(cu.cu_dat_inc_puente, 'hh24') AS hora_puente,
       trunc(udf.udf_receivedate) fecha_udp,
       to_char(udf.udf_receivedate, 'hh24') AS hora_udp,
       ld.ld_desc AS estacion,
       cu.cu_itg_ctr AS integracion,
       app.app_descshort AS producto,
       udf.veh_id AS veh_id,
       cu.cu_farevalue AS monto,
       CASE
         WHEN length(udf.veh_id) < 5 THEN
          'Estaciones'
         ELSE
          CASE
            WHEN substr(udf.veh_id, 2, 1) = 2 THEN
             'Padron'
            WHEN substr(udf.veh_id, 2, 1) = 3 THEN
             'Complementario'
            ELSE
             'Otro'
          END
       END AS tipologia,
       CASE
         WHEN TO_NUMBER(to_char(cu.cu_dat_inc_puente, 'hh24')) > 7 THEN
          trunc(cu.cu_dat_inc_puente)
         ELSE
          CASE
            WHEN trunc(cu.cu_dat_inc_puente) = trunc(cu.cu_datetime) THEN
             trunc(cu.cu_dat_inc_puente)
            ELSE
             trunc(cu.cu_dat_inc_puente) - 1
          END
       END AS fecha_dialiq,
       COUNT(1) AS cantidad_usos
  FROM mercury.cardusage        cu,
       mercury.linedetails      ld,
       mercury.usagedatatripmt  udtm,
       mercury.usagedataservice uds,
       mercury.usagedatafile    udf,
       mercury.applications     app
 WHERE cu.udtm_id = udtm.udtm_id
   AND udtm.uds_id = uds.uds_id
   AND uds.udf_id = udf.udf_id
      --AND     cu.cu_datetime >= TO_DATE('22-08-2022 00:01', 'dd-mm-yyyy hh24:mi')
      --AND     cu.cu_datetime <= TO_DATE('22-08-2022 23:59', 'dd-mm-yyyy hh24:mi')
   AND cu.cu_dat_inc_puente >=
       TO_DATE('&Fecha_1 07:59:00', 'dd-mm-yyyy hh24:mi:ss') --Fecha Tabla Puente --6am, 12m, 4pm-- dos dias antes de la fecha de proceso (Actual)
   AND cu.cu_dat_inc_puente <=
       TO_DATE('&Fecha_2 07:59:00', 'dd-mm-yyyy hh24:mi:ss') --Un dia despues de la fecha consulta de transacciones (Evaluacion de transacciones)
   AND cu.cut_id = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
   AND nvl(cu.cu_partfareseqnbr, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
   AND app.app_id = cu.app_id
   AND ld.ld_id = cu.ld_id
   AND udf.tp_id NOT IN (25, 44) --*** 44- MIO Cable
   AND ld.ld_id <> 215 --Temporal 
   AND cu.cu_itg_ctr IS NULL
   AND ((cu.cu_farevalue > 0) OR cu.app_id IN (920, 902)) -- Solo usos pagos 'BANBOGOTA - BANCOLOMBIA'
--AND  ((CU.cu_farevalue >= 0 or cu.cu_itg_ctr is not null) or CU.app_id in (920,902) OR app.af_id = 30 )---- Todos los productos

 GROUP BY ld.ld_desc,
          app.app_descshort,
          cu.cu_itg_ctr,
          trunc(cu.cu_datetime),
          trunc(cu.cu_dat_inc_puente),
          app.app_descshort,
          udf.veh_id,
          to_char(cu.cu_dat_inc_puente, 'hh24'),
          trunc(udf.udf_receivedate),
          to_char(udf.udf_receivedate, 'hh24'),
          cu.cu_farevalue;

--*******************************************************************************************
--*************************** VERIFICACION USOS VISA ***************************************
SELECT (COUNT(*)) QTRX FROM (
SELECT CASE
         WHEN a.route_id = 'BUS NO REG RUTA' THEN
          '236' --Generica P99
         WHEN a.route_id = 'ESTACION SIN RUTA' THEN
          '235' -- A99
         WHEN a.route_id IS NULL THEN
          '236'
         ELSE
          a.route_id
       END AS ld_id,
       'VISA' AS app_descshort,
       19 AS iss_id,
       99 AS cd_id,
       a.bin || a.last4 AS bin_last4, --crd snr
       a.card_number,
       999 AS app_id,
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
       END AS cu_itg_ctr,
       a.entry_date,
       a.fecha_ws,
       a.response_date,
       a.visa_dat_inc_puente,
       a.device_id,
       999 AS tp_id,
       /*CASE
         WHEN a.importe = 2400 THEN 2200
         ELSE a.importe
       END AS IMPORTE,*/
       a.importe,
       COUNT(*) AS qpax
  FROM mercury.tbl_trx_utrytopcs a
 WHERE a.status = 'A'
   AND a.processed IN ('S', 'C')
   AND trunc(a.visa_dat_inc_puente) = trunc(sysdate) --to_date('05/05/5555','dd-mm-yyyy')
   AND trunc(a.fecha_ws) >= trunc(sysdate) -- to_date('05-04-2023 00:01','dd-mm-yyyy hh24:mi') -- Todos los Lunes (sysdate-2)
      --AND a.fecha_ws <= to_date('07-09-2021 23:59','dd-mm-yyyy hh24:mi')--trunc (sysdate)
   AND response_date IS NOT NULL
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
          a.response_date
 ORDER BY entry_date ASC) t;
--ORDER BY 10,6,8 ASC;

/

--*******************************************************************************************
--*************************** VERIFICACION USOS VISA POR TARIFA***************************************

  SELECT *
    FROM mercury.tbl_trx_utrytopcs a
   WHERE a.status = 'A'
     AND a.processed = 'S'
     AND a.response_date IS NOT NULL
     AND trunc(a.visa_dat_inc_puente) = trunc(sysdate)
     AND a.importe = 2200;
