-----------------**************-------------------
-----------------CONSULTAS DE CONTROL-------------
-----------------**************-------------------

--********************************
--*** QUERY RECARGAS TOTAL *************
SELECT --a.tp_id TP_ID,
 to_char(b.ptd_regdate, 'DD/MM/YYYY') fecha,
 COUNT(to_char(b.ptd_regdate, 'DD/MM/YYYY HH24:MI:SS')) cant, -- FECHA,
 SUM(b.ptd_amount * 1000) monto
  FROM mercury.pos_tranmt   a,
       mercury.pos_trandt   b,
       mercury.pos_device   c,
       mercury.pos_products d
 WHERE a.ptm_trannbr = b.ptm_trannbr
   AND a.pd_code = b.pd_code
   AND b.ptd_status = 'A'
   AND b.ptd_regdate >= TO_DATE('&Fecha_1 00:01', 'DD-MM-YYYY HH24:MI') --DIAS LIQUIDADOS
   AND b.ptd_regdate <= TO_DATE('&Fecha_2 23:59', 'DD-MM-YYYY HH24:MI') --DIAS LIQUIDADOS
   AND b.pd_code = c.pd_code
   AND b.pp_code = d.pp_code
      --and (b.pp_code in (24,29,30,22) or  b.ptd_conf_date is not null)  --*** CON Venta de Tarjetas
   AND (b.pp_code IN (22) OR b.ptd_conf_date IS NOT NULL) --*** Solamente Recargas
   AND b.ptm_trannbr = a.ptm_trannbr
   AND b.pd_code = a.pd_code
   AND a.ptm_status = 'Z'
   AND a.tp_id IN (16, 44, 34)
 GROUP BY --a.tp_id,
          to_char(b.ptd_regdate, 'DD/MM/YYYY')
UNION
SELECT --a.prv_master_id AS TP_ID,
 to_char(a.tr_trandate, 'dd/mm/yyyy') fecha,
 COUNT(to_char(a.tr_trandate, 'DD/MM/YYYY HH24:MI:SS')) cant,
 SUM(a.tr_amount) monto
  FROM mercury.tbl_ventas_netsales a
 WHERE a.tr_trandate >= TO_DATE('&Fecha_1 00:01', 'DD-MM-YYYY HH24:MI') --DIAS LIQUIDADOS                  
   AND a.tr_trandate <= TO_DATE('&Fecha_2 23:59', 'DD-MM-YYYY HH24:MI') --DIAS LIQUIDADOS             

 GROUP BY --a.prv_master_id,
          to_char(a.tr_trandate, 'dd/mm/yyyy');
/
--****  Query Ventas Actualizado 2.0 ****
  SELECT --b.pd_desc, 
   trunc(a.ptd_regdate) AS fecha,
   COUNT(*) AS cantidad,
   --(count(*)*4000) AS MONTO
   SUM(a.ptd_amount) * 1000 AS monto,
   a.ptd_amount * 1000 AS tarifa
    FROM mercury.pos_trandt a, mercury.pos_device b
   WHERE pp_code IN (24, 29, 30, 34, 37)
     AND a.ptd_regdate >= TO_DATE('&Fecha_1 00:01', 'dd-mm-yyyy hh24:mi') --DIAS LIQUIDADOS
     AND a.ptd_regdate <= TO_DATE('&Fecha_2 23:59', 'dd-mm-yyyy hh24:mi') --DIAS LIQUIDADOS
     AND a.pd_code = b.pd_code
     AND a.ptd_status = 'A'
   GROUP BY --b.pd_desc, 
            trunc(a.ptd_regdate),
            a.ptd_amount
   ORDER BY 1 ASC;
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
