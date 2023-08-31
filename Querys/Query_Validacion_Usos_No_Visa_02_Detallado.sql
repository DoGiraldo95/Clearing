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
       TO_DATE('29-06-2023 07:59:00', 'dd-mm-yyyy hh24:mi:ss') --Fecha Tabla Puente --6am, 12m, 4pm-- dos dias antes de la fecha de proceso (Actual)
   AND cu.cu_dat_inc_puente <=
       TO_DATE('04-07-2023 07:59:00', 'dd-mm-yyyy hh24:mi:ss') --Un dia despues de la fecha consulta de transacciones (Evaluacion de transacciones)
   AND cu.cut_id = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
   AND nvl(cu.cu_partfareseqnbr, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
   AND app.app_id = cu.app_id
   AND ld.ld_id = cu.ld_id
   AND udf.tp_id NOT IN (25, 44) --*** 44- MIO Cable
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