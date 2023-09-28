----------------------------------------------------
--:::usos visa transmitidos::::
-----------------------------------------------------
select * from Mercury.tbl_trx_utrytopcs
-------------------------------------------------------
SELECT    
            trunc(a.date_created) as fecha_creacion,
           a.device_id    as serial_validador,
           trunc(a.entry_date)   as fecha_entrada,     
           a.visa_dat_inc_puente ,
           a.fecha_ws as fecha_comunicacion,
         
case       a.metrocali
when       '0' 
then       '_____'-----bus   
else         a.metrocali
end        as NUMERO_VEHICULO ,

case    a.ROUTE_ID
when    '236'
then    'NO_IDENTIFICA'
else   case a.METROCALI
         when   '0'
         then   'ESTACION'
         else case
        WHEN SUBSTR(a.METROCALI, 1, 1) = '1' THEN
          'BUS_GIT'
        WHEN SUBSTR(a.METROCALI, 1, 1) = '2' THEN
          'BUS_BYN'
          WHEN SUBSTR(a.metrocali, 1, 1)= '3' THEN
          'BUS_ETM'
          WHEN SUBSTR(a.metrocali, 1,1)= '5' THEN
          'BUS_BYN'
        ELSE
          'Otro'
          END
          END
 END AS TIPOLOGIA,

case    a.short_txt
when   'null'
then   'BUS_NO_REGISTRA'
else   a.short_txt
end  as estacion ,
count (*) as qtrx

FROM MERCURY.TBL_TRX_UTRYTOPCS a

where 1=1
and  TRUNC (a.date_created) >= TRUNC (to_date('28-09-2023 00:01:00','dd-mm-yyyy hh24:mi:ss'))
and  TRUNC (a.date_created) <= TRUNC (to_date('28-09-2023 23:59:00','dd-mm-yyyy hh24:mi:ss'))
--and  trunc(a.VISA_DAT_INC_PUENTE) = trunc(SYSDATE)
--and a.short_txt='UNIVERSIDA'
--and a.DEVICE_ID in  (986861466)

group by   
             a.short_txt,
             a.route_id,
             trunc(a.date_created) ,
             a.device_id,
             trunc(a.entry_date),
             a.metrocali,
             a.visa_dat_inc_puente,
              a.fecha_ws
order by  trunc(a.date_created) ;


------------------------------
select CASE
        WHEN SUBSTR(a.METROCALI, 1, 1) = '1' THEN
          'bus1'
        WHEN SUBSTR(a.METROCALI, 1, 1) = '2' THEN
          'bus2'
        ELSE
          'Otro'
      END as tipo

           
from MERCURY.TBL_TRX_UTRYTOPCS a;



-------------------------------------------------------------------------------
::::::::::::::::::::::::CONSULTA DE USOS NO VISA POR VALIDADOR ESTACIONES::::::::::::::::::::::::::

---------------------------------------------------------------------------------

SELECT
  TRUNC(CU.CU_DATETIME)                                                                                                                                                                                                                          AS FECHA_USO,
  LD.LD_DESC                                                                                                                                                                                                                                     AS ESTACION,
  UDF.VEH_ID                                                                                                                                                                                                                                     AS VEH_ID,
  CASE
    WHEN TO_NUMBER(TO_CHAR(CU.CU_DAT_INC_PUENTE, 'hh24')) > 7 THEN
      TRUNC(CU.CU_DAT_INC_PUENTE)
    ELSE
      CASE
        WHEN TRUNC(CU.CU_DAT_INC_PUENTE) = TRUNC(CU.CU_DATETIME) THEN
          TRUNC(CU.CU_DAT_INC_PUENTE)
        ELSE
          TRUNC(CU.CU_DAT_INC_PUENTE)-1
      END
  END AS FECHA_DIALIQ,
  COUNT(1)                                                                                                                                                                                                                                       AS CANTIDAD_USOS
FROM
  MERCURY.CARDUSAGE        CU,
  MERCURY.LINEDETAILS      LD,
  MERCURY.USAGEDATATRIPMT  UDTM,
  MERCURY.USAGEDATASERVICE UDS,
  MERCURY.USAGEDATAFILE    UDF,
  MERCURY.APPLICATIONS     APP
WHERE
  CU.UDTM_ID = UDTM.UDTM_ID
  AND UDTM.UDS_ID = UDS.UDS_ID
  AND UDS.UDF_ID = UDF.UDF_ID
 --AND     cu.cu_datetime >= TO_DATE('22-08-2022 00:01', 'dd-mm-yyyy hh24:mi')
 --AND     cu.cu_datetime <= TO_DATE('22-08-2022 23:59', 'dd-mm-yyyy hh24:mi')
  AND CU.CU_DAT_INC_PUENTE >= TO_DATE('18-09-2023 07:59:00', 'dd-mm-yyyy hh24:mi:ss') --Fecha Tabla Puente --6am, 12m, 4pm-- dos dias antes de la fecha de proceso (Actual)
  AND CU.CU_DAT_INC_PUENTE <= TO_DATE('27-09-2023 07:59:00', 'dd-mm-yyyy hh24:mi:ss') --Un dia despues de la fecha consulta de transacciones (Evaluacion de transacciones)
  AND CU.CUT_ID = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale------------------------------
  AND NVL(CU.CU_PARTFARESEQNBR, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
  AND APP.APP_ID = CU.APP_ID
  AND LD.LD_ID = CU.LD_ID
 --  AND     udf.tp_id not in (16)--udf.tp_id not in (25,44) --*** 44- MIO Cable empresa
  AND UDF.VEH_ID IN (1304) ----VALIDADOR
  AND CU.CU_ITG_CTR IS NULL
  AND ((CU.CU_FAREVALUE > 0)
  OR CU.APP_ID IN (920, 902)) -- Solo usos pagos 'BANBOGOTA - BANCOLOMBIA'
 --AND  ((CU.cu_farevalue >= 0 or cu.cu_itg_ctr is not null) or CU.app_id in (920,902) OR app.af_id = 30 )---- Todos los productos
GROUP BY
  LD.LD_DESC, APP.APP_DESCSHORT, CU.CU_ITG_CTR, TRUNC(CU.CU_DATETIME), 
  TRUNC(CU.CU_DAT_INC_PUENTE), APP.APP_DESCSHORT, UDF.VEH_ID, 
  TO_CHAR(CU.CU_DAT_INC_PUENTE, 'hh24'), TRUNC(UDF.UDF_RECEIVEDATE), 
  TO_CHAR(UDF.UDF_RECEIVEDATE, 'hh24'), CU.CU_FAREVALUE;



--------------------------
select

            trunc(ut.fecha_ws),
            ut.device_id,
            ut.metrocali veh_id,
 case
   when ut.short_txt = 'null' then
    'P99'
   else
    ut.short_txt
 end estacion,
 count(2) cantidad
  from tbl_trx_utrytopcs ut
 where /*to_char(ut.visa_dat_inc_puente, 'dd-mm-yy') = '05-05-55'
 and*/
 trunc(ut.fecha_ws) between to_date('01-09-2023', 'dd-mm-yyyy') AND
 to_date('14-09-2023', 'dd-mm-yyyy')
 AND ut.short_txt = 'UNIVERSIDA'
/* and ut.status = 'A'
and ut.processed in ('S', 'C')*/
 group by ut.device_id, ut.metrocali, ut.short_txt, trunc(ut.fecha_ws)
 order by 1"
----
SELECT z.FECHA,
       COUNT (z.equipo) CANT_EQUIPOS,
       SUM (z.CANT) CANT_TRX
FROM (
SELECT TRUNC(a.date_created) as FECHA,
       a.device_id as EQUIPO,
       count(*) as CANT
FROM Mercury.tbl_trx_utrytopcs a
--WHERE a.entry_id = '2109011821545685679' --'2109011821305685678'
WHERE a.fecha_ws >= TRUNC(SYSDATE - 20)
GROUP BY TRUNC(a.date_created), a.device_id
) Z
GROUP BY Z.FECHA
ORDER BY 1 ASC
;