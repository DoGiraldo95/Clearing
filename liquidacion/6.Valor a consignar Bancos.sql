--************************--
--Valor a consignar bancos--
--************************--
BEGIN
  MERCURY.LIQUIDACIONRT_PKG.VALOR_CONSIGNAR_BANCOS(TO_DATE('25-08-2023', 'DD-MM-YYYY'));
END;
/

--Consulta para generar el dato Valor a Consignar
--VALOR A CONSIGNAR BANCOS
SELECT
  CASE
    WHEN A.TP_ID = 19 THEN
      'BANCO BOGOTA'
    WHEN A.TP_ID = 20 THEN
      'BANCOLOMBIA'
    ELSE
      'OTRO'
  END AS BANCO,
  A.FECHA_LIQ,
  SUM(A.CANT_TRX)                                                                                 USOS,
  SUM(A.MONTO)                                                                                    VALOR
FROM
  MERCURY.TBL_VALOR_CONSIGNAR_MRC A
WHERE
  A.FECHA_LIQ >= TO_DATE('25-08-2023', 'DD-MM-YYYY')
  AND A.FECHA_LIQ <= TO_DATE('25-08-2023', 'DD-MM-YYYY')
  AND A.TP_ID IN (19, 20)
 --AND a.tp_id = 19
GROUP BY
  A.TP_ID, A.FECHA_LIQ
ORDER BY
  2 ASC;