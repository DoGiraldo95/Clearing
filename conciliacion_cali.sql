--Para conciliacion red interna Cali
SELECT a.fecha_liq, SUM(a.MONTO) VALOR
 FROM Mercury.Tbl_Valor_Consignar_Mrc a
 WHERE a.fecha_liq >= TO_DATE('01-09-2023', 'DD-MM-YYYY') --fecha hoy
 AND a.fecha_liq <= TO_DATE('12-09-2023', 'DD-MM-YYYY')
 AND a.tp_id in (16,44)
 GROUP BY a.fecha_liq;

--Para conciliacion bancolombia
SELECT
  A.FECHA_LIQ,
  CASE
    WHEN A.TP_ID = 20 THEN
      'BANCOLOMBIA'
  END AS BANCO,
  A.CANT_TRX,
  A.MONTO
FROM
  MERCURY.TBL_VALOR_CONSIGNAR_MRC A
WHERE
  A.FECHA_LIQ >= TO_DATE('01-09-2023', 'DD-MM-YYYY') --Fecha de proceso
  AND A.FECHA_LIQ <= TO_DATE('12-09-2023', 'DD-MM-YYYY') --Fecha de proceso
  AND A.TP_ID = 20
ORDER BY
  FECHA_LIQ DESC;

*
/

--Para conciliacion banco de bogota
SELECT
  A.FECHA_LIQ,
  CASE
    WHEN A.TP_ID = 19 THEN
      'BANCO BOGOTA'
  END AS BANBOGOTA,
  A.CANT_TRX,
  A.MONTO
FROM
  MERCURY.TBL_VALOR_CONSIGNAR_MRC A
WHERE
  A.FECHA_LIQ >= TO_DATE('01-09-2023', 'DD-MM-YYYY') --Fecha de proceso
  AND A.FECHA_LIQ <= TO_DATE('12-09-2023', 'DD-MM-YYYY') --Fecha de proceso
  AND A.TP_ID = 19
ORDER BY
  FECHA_LIQ DESC;