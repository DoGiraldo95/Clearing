SELECT a.fecha_liq, a.monto, a.tp_id
  FROM Mercury.Tbl_Valor_Consignar_Mrc a
 WHERE a.fecha_liq >= TO_DATE('01-05-2023', 'DD-MM-YYYY')
   AND a.fecha_liq < TO_DATE('01-06-2023', 'DD-MM-YYYY') -- RECIBE COMO PARAMETRO LA FECHA DE PROCESO(FECHA_LIQ)
   AND a.tp_id IN ( 44, 45 )

 order by 1;
/

---------------------------------------- CONSULTA DE CONTROL------------------------------------------


 SELECT CASE 
                    WHEN  TO_CHAR(B.FECHA, 'MM') = '03'
                    THEN 'MARZO'
                    WHEN  TO_CHAR(B.FECHA, 'MM') = '04'
                      THEN 'ABRIL'
                          WHEN  TO_CHAR(B.FECHA, 'MM') = '05'
                      THEN 'MAYO'
                        ELSE 'OTRO'
                          END MES ,  
                                        SUM(B.MONTO)
                                         FROM (SELECT a.tp_id TP_ID,
       TRUNC(b.ptd_regdate) FECHA,
COUNT(to_char(b.ptd_regdate, 'DD/MM/YYYY HH24:MI:SS')) CANT, -- FECHA,
SUM(b.ptd_amount*1000) MONTO
from mercury.pos_tranmt a, mercury.pos_trandt b, mercury.pos_device c, mercury.pos_products d
where a.ptm_trannbr = b.ptm_trannbr
and a.pd_code = b.pd_code
and b.ptd_status = 'A'
and b.ptd_regdate >= TO_DATE('01-03-2023 00:01', 'DD-MM-YYYY HH24:MI') -- TRX - liquidacion
and b.ptd_regdate <= TO_DATE('31-05-2023 23:59', 'DD-MM-YYYY HH24:MI') --TRX- liquidacion 
and b.pd_code = c.pd_code
and b.pp_code = d.pp_code
and (b.pp_code in (24,29,30,22,34,37) or  b.ptd_conf_date is not null)  --*** CON Venta de Tarjetas 
--and (b.pp_code in (22) or  b.ptd_conf_date is not null) --*** Solamente Recargas
AND b.PTM_TRANNBR = a.PTM_TRANNBR
AND b.PD_CODE = a.PD_CODE
AND a.PTM_STATUS = 'Z'
AND a.tp_id in (44, 45)

GROUP BY a.tp_id,
         TRUNC(b.ptd_regdate)
UNION
SELECT a.prv_master_id AS TP_ID,
       TRUNC(a.tr_trandate) FECHA,
       Count(to_char(a.tr_trandate, 'DD/MM/YYYY HH24:MI:SS')) CANT,
       SUM(a.TR_AMOUNT) MONTO

  FROM mercury.tbl_ventas_netsales a
 WHERE a.tr_trandate >= TO_DATE('01-03-2023 00:01', 'DD-MM-YYYY HH24:MI')       --*********  FECHA                  
   AND a.tr_trandate <= TO_DATE('31-05-2023 23:59', 'DD-MM-YYYY HH24:MI') -- liquidacion
   AND a.prv_master_id = 745       --Puntos Externos        
                                  
 GROUP BY TRUNC(a.tr_trandate),
          a.prv_master_id

ORDER BY 1 ASC) b
GROUP BY B.FECHA, B.MONTO, B.TP_ID;


