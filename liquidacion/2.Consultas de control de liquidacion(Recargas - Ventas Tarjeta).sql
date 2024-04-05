-----------------**************-------------------
-----------------CONSULTAS DE CONTROL-------------
-----------------**************-------------------

--********************************
--*** QUERY RECARGAS TOTAL *************
SELECT
	--A.TP_ID TP_ID,
	TO_CHAR(B.PTD_REGDATE, 'DD/MM/YYYY') FECHA,
	COUNT(TO_CHAR(B.PTD_REGDATE, 'DD/MM/YYYY HH24:MI:SS')) CANT,
	-- FECHA,
	SUM(B.PTD_AMOUNT * 1000) MONTO
FROM
	MERCURY.POS_TRANMT A
JOIN MERCURY.POS_TRANDT B ON
	(A.PTM_TRANNBR = B.PTM_TRANNBR
		AND A.PTM_TRANNBR = A.PTM_TRANNBR
		AND A.PD_CODE = B.PD_CODE)
JOIN MERCURY.POS_DEVICE C ON
	(B.PD_CODE = C.PD_CODE)
JOIN MERCURY.POS_PRODUCTS D ON
	(B.PP_CODE = D.PP_CODE)
WHERE
	B.PTD_STATUS = 'A'
	AND B.PTD_REGDATE >= TO_DATE('03-04-2024 00:01', 'DD-MM-YYYY HH24:MI')
	--DIAS LIQUIDADOS
	AND B.PTD_REGDATE <= TO_DATE('03-04-2024 23:59', 'DD-MM-YYYY HH24:MI')
	--DIAS LIQUIDADOS
	--AND (B.PP_CODE IN (24,29,30,22) OR  B.PTD_CONF_DATE IS NOT NULL)  --*** CON VENTA DE TARJETAS
	AND (B.PP_CODE IN (22)
		OR B.PTD_CONF_DATE IS NOT NULL)
	--*** SOLAMENTE RECARGAS
	AND A.PTM_STATUS = 'Z'
	AND A.TP_ID IN (16, 44, 34)
GROUP BY
	--A.TP_ID,
	TO_CHAR(B.PTD_REGDATE, 'DD/MM/YYYY')
UNION
SELECT
	--A.PRV_MASTER_ID AS TP_ID,
	TO_CHAR(A.TR_TRANDATE, 'DD/MM/YYYY') FECHA,
	COUNT(TO_CHAR(A.TR_TRANDATE, 'DD/MM/YYYY HH24:MI:SS')) CANT,
	SUM(A.TR_AMOUNT) MONTO
FROM
	MERCURY.TBL_VENTAS_NETSALES A
WHERE
	A.TR_TRANDATE >= TO_DATE('03-04-2024 00:01', 'DD-MM-YYYY HH24:MI')
	--DIAS LIQUIDADOS                  
	AND A.TR_TRANDATE <= TO_DATE('03-04-2024 23:59', 'DD-MM-YYYY HH24:MI')
	--DIAS LIQUIDADOS             
GROUP BY
	--A.PRV_MASTER_ID,
	TO_CHAR(A.TR_TRANDATE, 'DD/MM/YYYY');

/
--****  QUERY VENTAS ACTUALIZADO 2.0 ****
  SELECT
	--B.PD_DESC, 
	TO_CHAR(A.PTD_REGDATE, 'DD MONTH, YYYY') AS FECHA,
	COUNT(*) AS CANTIDAD,
	--(COUNT(*)*4000) AS MONTO
	TO_CHAR(SUM(A.PTD_AMOUNT) * 1000, '$999,999,999') AS MONTO,
	A.PTD_AMOUNT * 1000 AS TARIFA
FROM
	MERCURY.POS_TRANDT A
JOIN MERCURY.POS_DEVICE B
		USING(PD_CODE)
WHERE
	PP_CODE IN (24, 29, 30, 34, 37)
	AND A.PTD_REGDATE >= TO_DATE('03-04-2024 00:01', 'DD-MM-YYYY HH24:MI')
	--DIAS LIQUIDADOS
	AND A.PTD_REGDATE <= TO_DATE('03-04-2024 23:59', 'DD-MM-YYYY HH24:MI')
	--DIAS LIQUIDADOS
	-- AND A.PD_CODE = B.PD_CODE
	AND A.PTD_STATUS = 'A'
GROUP BY
	--B.PD_DESC, 
	TO_CHAR(A.PTD_REGDATE, 'DD MONTH, YYYY'),
	A.PTD_AMOUNT
ORDER BY
	1;
/

--****  Query Ventas Actualizado ****
/*select --b.pd_desc, 
       TRUNC(a.ptd_regdate)  AS FECHA,
       count(*) AS CANTIDAD,
       (count(*)*4000) AS MONTO
from mercury.pos_trandt a, mercury.pos_device b
where pp_code in (24,29,30,34,37)
and a.ptd_regdate >= to_date('19-08-2022 00:01','dd-mm-yyyy hh24:mi')   --DIAS LIQUIDADOS
and a.ptd_regdate <= to_date('21-08-2022 23:59','dd-mm-yyyy hh24:mi')   --DIAS LIQUIDADOS
and a.pd_code = b.pd_code 
and a.ptd_status = 'A' 
group by --b.pd_desc, 
         TRUNC(a.ptd_regdate)
order by 1 ASC
;
/
*/

----*****LIQUIDACION DE USOS******---------
/* SELECT a.clearing_date,
       trunc(a.cu_datetime) as fecha_uso,
       sum(a.qpax) as CANT
FROM MERCURY.tbl_liquidacionryt_usos A  --TBL_LIQUIDACIONRYT A
WHERE A.CLEARING_DATE >= TO_DATE('07-12-2020','DD-MM-YYYY')--Fecha de Liquidacion
  AND a.cu_itg_ctr is null
  AND a.tp_id not in (44)
GROUP BY a.clearing_date,trunc(a.cu_datetime)
ORDER BY 2 asc;*/

--**************************************************
-----**** CONTROL UPDATE USOS VISA*******------------
/*SELECT max (a.att3_num) from Mercury.tbl_trx_utrytopcs a
--UPDATE  Mercury.tbl_trx_utrytopcs a
SET     a.visa_dat_inc_puente = SYSDATE, a.att3_num =9 , a.att1_dat = to_date('05/05/5555','dd-mm-yyyy')
--select * from Mercury.tbl_trx_utrytopcs a
    WHERE a.status = 'A'
      AND a.processed = 'S'
      AND trunc(a.visa_dat_inc_puente) = to_date('05/05/5555','dd-mm-yyyy')
      AND a.fecha_ws >= TRUNC(SYSDATE)
     -- AND a.fecha_ws < TRUNC(SYSDATE)
      AND a.att3_num is null
;*/

/
