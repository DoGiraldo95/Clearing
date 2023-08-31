-------------------------------------------- ULTIMA FECHA DE REGISTRO / USO  ----------------------------------

SELECT a.bin, a.last4, a.date_created, a.entry_date, a.response_date, a.processed,a.status, a.descripcion_rta,  a.importe, a.authorization_id, a.card_number,a.fecha_ws, a.device_id, a.att4_chr
FROM mercury.tbl_trx_utrytopcs a
 WHERE /*trunc(a.response_date) >= to_date('&fecha_minima', 'dd/mm/yyyy') ----- RANGO FECHA DE REGISTRO
 AND trunc(a.response_date) <= to_date('&fecha_maxima', 'dd/mm/yyyy')
  a.entry_date >= to_date('01-04-2023 00:01', 'dd/mm/yyyy:hh24:mi') ----- RANGO FECHA DE USO 
 AND a.entry_date <= to_date('26-04-2023 23:59', 'dd/mm/yyyy:hh24:mi')*/
   a.bin =  491511 
  AND a.last4 = 3900
  AND a.entry_id = '2308101232416937706'
--    AND a.processed = 'R'
 ORDER BY a.response_date;
--  AND a.date_created = (SELECT MAX(b.date_created)
--                    FROM mercury.tbl_trx_utrytopcs b
--                   WHERE b.bin = 491511
--                     AND b.last4 = 1622);
                    

