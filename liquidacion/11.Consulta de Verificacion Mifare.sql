SELECT TRUNC(sw.trx_date) AS "Fecha Uso",
       TRUNC(sw.created) AS "Fecha Puente",
       TO_CHAR(sw.created, 'hh24') AS "Hora Puente",
       ln.ld_desc AS Estacion,
       sw.use_type AS Integracion,
       app.app_descshort AS Aplicacion,
       c.ISS_ID || c.CD_ID || c.CRD_SNR AS Tarjeta,
       (sw.fee * 10) AS Monto,
       CASE
         WHEN length(sw.bus_id) < 5 THEN
          'Estaciones'
         ELSE
          CASE
            WHEN substr(sw.bus_id, 2, 1) = 2 THEN
             'Padron'
            WHEN substr(sw.bus_id, 2, 1) = 3 THEN
             'Complementario'
            ELSE
             'Otro'
          END
       END AS tipologia,
       COUNT(1) AS Cantidad
  FROM mercury.sw_mifare_trx sw
  JOIN mercury.cards c
    ON (sw.uuid = c.crd_intsnr)
  JOIN mercury.applications app
    ON (sw.app_id = app.app_id)
  JOIN mercury.linedetails ln
    ON (sw.line_id = ln.ld_id)
 WHERE sw.created >= TO_DATE('&Fecha_1 07:59:00', 'dd/mm/yyyy hh24:mi:ss')
   AND sw.created <= TO_DATE('&Fecha_2 07:59:00', 'dd/mm/yyyy hh24:mi:ss')
   AND sw.bus_id NOT IN (85001, 85002, 85003, 85004, 85005)
   AND sw.Terminal_Id <> 1500030409
   AND (sw.use_type = 0 OR sw.FEE > 0)
/*   AND TRUNC(sw.cu_dat_inc_puente) = TRUNC(sysdate)*/
     AND TRUNC(sw.trx_date) <> TRUNC(SYSDATE)
 GROUP BY TRUNC(sw.trx_date),
          TRUNC(sw.created),
          TO_CHAR(sw.created, 'hh24'),
          ln.ld_desc,
          sw.use_type,
          app.app_descshort,
          (sw.fee * 10),
          sw.bus_id,
          c.iss_id || c.cd_id || c.crd_snr
ORDER BY "Fecha Uso"  ;        
   
 

    SELECT TRUNC(sw.trx_date), COUNT(1)AS Cantidad, 
     ln.ld_desc AS Estacion,
   sw.use_type AS Integracion,
   app.app_descshort AS Aplicacion,
   (sw.fee * 10) AS Monto
    FROM sw_mifare_trx sw
  JOIN mercury.applications app
    ON (sw.app_id = app.app_id)
  JOIN mercury.linedetails ln
    ON (sw.line_id = ln.ld_id)
  JOIN cards c
  ON (sw.uuid = c.crd_intsnr)
    WHERE sw.created >= TO_DATE('&Fecha_1 07:59:00', 'dd/mm/yyyy hh24:mi:ss')
   AND sw.created <= TO_DATE('&Fecha_2 07:59:00', 'dd/mm/yyyy hh24:mi:ss')
    AND sw.bus_id NOT IN (85001, 85002, 85003, 85004, 85005)
   AND sw.Terminal_Id <> 1500030409
   AND (sw.use_type = 0 OR sw.FEE > 0)
   GROUP BY TRUNC(sw.trx_date),
     ln.ld_desc ,
   sw.use_type ,
   app.app_descshort,
   (sw.fee * 10) 
   
