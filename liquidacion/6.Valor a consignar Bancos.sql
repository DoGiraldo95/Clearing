--************************--
--Valor a consignar bancos--
--************************--
BEGIN
	MERCURY.LIQUIDACIONRT_PKG.VALOR_CONSIGNAR_BANCOS(TO_DATE('05-04-2024', 'DD-MM-YYYY'));
END;

/
--Consulta para generar el dato Valor a Consignar
--VALOR A CONSIGNAR BANCOS
SELECT
	/*CASE
		WHEN A.TP_ID = 19 THEN
      'BANCO BOGOTA'
		WHEN A.TP_ID = 20 THEN
      'BANCOLOMBIA'
		ELSE
      'OTRO'
	END AS BANCO,*/
	DECODE(a.TP_ID, 19, 'BANCO BOGOTA', 20, 'BANCOLOMBIA', 'OTRO') AS BANCO,
	TO_CHAR(A.FECHA_LIQ, 'dd Mon, YYYY') "FECHA LIQUIDACION",
	SUM(A.CANT_TRX) USOS,
	TO_CHAR(SUM(A.MONTO), '$999,999,999') VALOR
FROM
	MERCURY.TBL_VALOR_CONSIGNAR_MRC A
WHERE
	A.FECHA_LIQ >= TO_DATE('05-04-2024', 'DD-MM-YYYY')
	AND A.FECHA_LIQ <= TO_DATE('05-04-2024', 'DD-MM-YYYY')
	AND A.TP_ID IN (19, 20)
	--AND a.tp_id = 19
GROUP BY
	A.TP_ID,
	TO_CHAR(A.FECHA_LIQ, 'dd Mon, YYYY')
ORDER BY
	2;
