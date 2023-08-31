SELECT CASE
         WHEN a.tp_id = 19 THEN
          'BANCO BOGOTA'
          WHEN a.tp_id = 20 THEN 'BANCOLOMBIA'
       END AS BANCO,
       a.fecha_liq,
       SUM(a.cant_trx) USOS,
       SUM(a.MONTO) VALOR
  FROM Mercury.Tbl_Valor_Consignar_Mrc a
 WHERE a.fecha_liq >= TO_DATE('09-06-2023', 'DD-MM-YYYY')
   and a.fecha_liq <= TO_DATE('09-06-2023', 'DD-MM-YYYY')
   AND a.tp_id IN (19, 20)
--AND a.tp_id = 19
 GROUP BY a.tp_id, a.fecha_liq

UNION

SELECT CASE
       --          WHEN a.tp_id = 19 THEN 'BANCO BOGOTA'
         WHEN a.tp_id = 20 THEN
          'BANCOLOMBIA'
       END AS BANCO,
       a.fecha_liq,
       SUM(a.cant_trx) USOS,
       SUM(a.MONTO) VALOR
  FROM Mercury.Tbl_Valor_Consignar_Mrc a
 WHERE a.fecha_liq IN (TO_DATE('07-06-2023', 'DD-MM-YYYY'),
                       TO_DATE('08-06-2023', 'DD-MM-YYYY'),
                       TO_DATE('09-06-2023', 'DD-MM-YYYY'))
   AND a.tp_id = (20)
--AND a.tp_id = 19
 GROUP BY a.tp_id, a.fecha_liq
