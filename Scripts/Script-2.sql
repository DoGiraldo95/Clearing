SELECT
	TO_CHAR(FECHA, 'dd Mon, YY'),
	TO_CHAR(SUM(MONTO), '$999,999,999,999') AS MONTO_USOS,
	SUM(CANTIDAD) AS CANTIDAD_USOS,
	TARIFA,
	TO_CHAR(PUENTE, 'hh:mm:ss pm'),
	ESTACION
FROM
	(
	SELECT
		TRUNC(CU.CU_DATETIME) AS FECHA,
		COUNT(CU.CU_UNIQUE_ID) AS CANTIDAD,
		CASE
			-- IDENTIFICA USOS POR TARIFA
                 WHEN ((CU.APP_ID = 902
			OR CU.APP_ID = 920)
			AND
                      CU.CU_ITG_CTR IS NULL) THEN
                  CASE
				WHEN (TRUNC(CU.CU_DATETIME) <
                         TO_DATE('24/01/2022', 'dd-mm-yyyy')) THEN
                     2200
				WHEN (TRUNC(CU.CU_DATETIME) BETWEEN
                         TO_DATE('25/01/2022', 'dd-mm-yyyy') AND
                         TO_DATE('22/01/2023', 'dd-mm-yyyy')) THEN
                     2400
				ELSE
                     2700
			END
			ELSE
                  CU.CU_FAREVALUE * 1000
		END AS TARIFA,
		CASE
			-- MONTO TOTAL DE USOS POR TARIFA
                 WHEN ((CU.APP_ID = 902
			OR CU.APP_ID = 920)
			AND
                      CU.CU_ITG_CTR IS NULL) THEN
                  CASE
				WHEN (TRUNC(CU.CU_DATETIME) <
                         TO_DATE('24/01/2022', 'dd-mm-yyyy')) THEN
                     2200 * COUNT(CU.CU_UNIQUE_ID)
				WHEN (TRUNC(CU.CU_DATETIME) BETWEEN
                         TO_DATE('25/01/2022', 'dd-mm-yyyy') AND
                         TO_DATE('22/01/2023', 'dd-mm-yyyy')) THEN
                     2400 * COUNT(CU.CU_UNIQUE_ID)
				ELSE
                     2700 * COUNT(CU.CU_UNIQUE_ID)
			END
			ELSE
                  CU.CU_FAREVALUE * COUNT(CU_UNIQUE_ID) * 1000
		END AS MONTO,
		CU.CU_DAT_INC_PUENTE PUENTE
		--cu.cu_farevalue * count(cu_unique_id) * 1000 as MONTO
              ,
		LD.LD_DESC ESTACION
	FROM
		MERCURY.CARDUSAGE CU JOIN MERCURY.USAGEDATATRIPMT UDTM ON (cu.UDTM_ID = UDTM.UDTM_ID)
		JOIN MERCURY.APPLICATIONS APP ON (cu.APP_ID = APP.APP_ID)
		JOIN MERCURY.LINEDETAILS LD ON (CU.LD_ID = ld.LD_ID)
		JOIN MERCURY.USAGEDATASERVICE UDS ON (UDTM.UDS_ID = UDS.UDS_ID) ,
		JOIN MERCURY.USAGEDATAFILE UDF ON (UDS.UDF_ID = UDF.UDF_ID)
		
	WHERE
		1 = 1
	--	AND CU.UDTM_ID = UDTM.UDTM_ID
	--	AND UDTM.UDS_ID = UDS.UDS_ID
	--	AND UDS.UDF_ID = UDF.UDF_ID
              /*AND cu.cu_datetime >=
                  to_Date('01-07-2023 00:01', 'dd-mm-yyyy hh24:mi') --trunc (sysdate -1) paso 1
              AND cu.cu_datetime <=
                  to_Date('15-07-2023 23:59', 'dd-mm-yyyy hh24:mi') --trunc (sysdate)    Dias liquidados*/
		AND UDF.UDF_RECEIVEDATE >=
               TO_DATE('15-10-2023 00:01', 'dd-mm-yyyy hh24:mi')
		AND UDF.UDF_RECEIVEDATE <=
               TO_DATE('01-11-2023 23:59', 'dd-mm-yyyy hh24:mi')
		--paso 2
		--AND cu.cu_dat_inc_puente >= to_Date('16-07-2022 00:01', 'dd-mm-yyyy hh24:mi') --trunc (sysdate -1) Dias liquidados
		--AND cu.cu_dat_inc_puente <= to_Date('31-07-2022 23:59', 'dd-mm-yyyy hh24:mi')
		AND CU.CUT_ID = 1
		-- Tipos de uso -> 1: Passenger use, 5: On-board sale
		AND NVL(CU.CU_PARTFARESEQNBR, 0) <> 2
		-- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
	--	AND APP.APP_ID = CU.APP_ID
	--	AND LD.LD_ID = CU.LD_ID
		--AND     udf.tp_id not in (25,44)
		--AND TO_CHAR(cu.cu_datetime, 'yyyy')<> 2023
		AND TRUNC(CU.CU_DATETIME) NOT IN
               (TO_DATE('31-10-2023', 'dd-mm-yyyy'),
                TO_DATE('16-11-2023', 'dd-mm-yyyy'))
		--             AND udf.udf_receivedate > (sysdate - 60)
		AND UDF.TP_ID IN (44)
		--
              
              /*     AND to_char(cu.cu_datetime, 'yyyy') <> 2023*/
		AND (CU.CU_FAREVALUE > 0
			OR CU.APP_ID IN (920, 902))
		-- Solo usos pagos (efectivo o bancos)
		--AND  ((CU.cu_farevalue >= 0 or cu.cu_itg_ctr is not null) or CU.app_id in (920,902) OR app.af_id = 30 )
		--and cu.cu_itg_ctr is null
		--and cu.cu_farevalue not in ('2.40','2.20' )--0.0
	GROUP BY
		TRUNC(CU.CU_DATETIME),
		CU.CU_FAREVALUE,
		CU.APP_ID,
		CU.CU_ITG_CTR,
		CU.CU_DATETIME,
		CU.CU_DAT_INC_PUENTE,
		LD.LD_DESC)
GROUP BY
	TO_CHAR(FECHA, 'dd Mon, YY'),
	ESTACION,
	PUENTE ,
	TARIFA ,
	TO_CHAR(PUENTE, 'hh:mm:ss pm')
	--CANTIDAD_USOS,
	--MONTO_USOS --trunc(cu.cu_datetime),cu.cu_farevalue, cu.app_id, cu.cu_itg_ctr, cu.cu_datetime
ORDER BY
	1 ASC;