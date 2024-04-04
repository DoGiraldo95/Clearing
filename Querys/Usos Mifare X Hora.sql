WITH usos_mifare AS
 (SELECT ln.ld_descshort AS ESTACION,
         TRUNC(smt.TRX_DATE) "FECHA USO",
         TO_CHAR(smt.TRX_DATE, 'hh24') AS HORA,
         COUNT(*) QPX
    FROM mercury.sw_mifare_trx smt JOIN mercury.linedetails ln ON (smt.line_id = ln.ld_id)
   WHERE TRUNC(smt.trx_date) >= TRUNC(SYSDATE - 3)
     AND smt.bus_id NOT IN (85001, 85002, 85003, 85004, 85005)
     AND smt.Terminal_Id <> 1500030409
     AND smt.uuid <> 3012078720
     AND (smt.use_type = 0 OR smt.FEE > 0)
   GROUP BY ln.ld_descshort, TRUNC(smt.TRX_DATE), TO_CHAR(smt.TRX_DATE, 'hh24'))

SELECT *
  FROM usos_mifare
PIVOT (SUM(QPX) FOR HORA IN('05',
                       '06',
                       '07',
                       '08',
                       '09',
                       '10',
                       '11',
                       '12',
                       '13',
                       '14',
                       '15',
                       '16',
                       '17',
                       '18',
                       '19',
                       '20',
                       '21',
                       '22'))
 ORDER BY 2;