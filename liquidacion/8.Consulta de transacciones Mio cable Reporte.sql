--------------------***********CONSULTAR TRANSACCIONES MIO CABLE V 3.0******----------------

SELECT trunc(p.fecha_uso), sum(p.monto_usos) , sum(p.cantidad_usos) FROM (SELECT CASE
         WHEN (to_char(FECHA, 'yyyy') <> 2023 AND TARIFA = 2700) THEN
          TRUNC(PUENTE - 1)
         WHEN (to_char(FECHA, 'dd-mm-yyyy') < (PUENTE - 16) AND
              TARIFA = 2700) THEN
          TRUNC(PUENTE - 1)
         ELSE
          FECHA
       END FECHA_USO,
       SUM(MONTO) AS MONTO_USOS,
       SUM(CANTIDAD) AS CANTIDAD_USOS

  FROM (SELECT trunc(cu.cu_datetime) AS FECHA,
               count(cu.cu_unique_id) as CANTIDAD,
               CASE -- IDENTIFICA USOS POR TARIFA
                 WHEN ((cu.app_id = 902 OR cu.app_id = 920) AND
                      cu.cu_itg_ctr IS NULL) THEN
                  CASE
                    WHEN (TRUNC(cu.cu_datetime) <
                         to_date('24/01/2022', 'dd-mm-yyyy')) THEN
                     2200
                    WHEN (TRUNC(cu.cu_datetime) BETWEEN
                         to_date('25/01/2022', 'dd-mm-yyyy') AND
                         to_date('22/01/2023', 'dd-mm-yyyy')) THEN
                     2400
                    ELSE
                     2700
                  END
                 ELSE
                  cu.cu_farevalue * 1000
               END AS TARIFA,
               CASE -- MONTO TOTAL DE USOS POR TARIFA
                 WHEN ((cu.app_id = 902 OR cu.app_id = 920) AND
                      cu.cu_itg_ctr IS NULL) THEN
                  CASE
                    WHEN (TRUNC(cu.cu_datetime) <
                         to_date('24/01/2022', 'dd-mm-yyyy')) THEN
                     2200 * COUNT(cu.CU_UNIQUE_ID)
                    WHEN (TRUNC(cu.cu_datetime) BETWEEN
                         to_date('25/01/2022', 'dd-mm-yyyy') AND
                         to_date('22/01/2023', 'dd-mm-yyyy')) THEN
                     2400 * COUNT(cu.CU_UNIQUE_ID)
                    ELSE
                     2700 * COUNT(cu.CU_UNIQUE_ID)
                  END
                 ELSE
                  cu.cu_farevalue * count(cu_unique_id) * 1000
               END AS MONTO,
               cu.cu_dat_inc_puente PUENTE
               --cu.cu_farevalue * count(cu_unique_id) * 1000 as MONTO 
              ,
               ld.ld_desc ESTACION
          FROM mercury.CARDUSAGE        cu,
               mercury.linedetails      ld,
               mercury.USAGEDATATRIPMT  udtm,
               mercury.USAGEDATASERVICE uds,
               mercury.USAGEDATAFILE    udf,
               mercury.applications     app
         WHERE 1 = 1
           AND CU.UDTM_ID = UDTM.UDTM_ID
           AND UDTM.UDS_ID = UDS.UDS_ID
           AND UDS.UDF_ID = UDF.UDF_ID
              
           AND udf.udf_receivedate >=
               to_date('&Fecha1 00:01', 'dd-mm-yyyy hh24:mi') --un dia antes
           AND udf.udf_receivedate <=
               to_date('&Fecha2 23:59', 'dd-mm-yyyy hh24:mi')-- un dia despues
              
           AND cu.cut_id = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
           AND NVL(cu.cu_partfareseqnbr, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
           AND app.app_id = cu.app_id
           AND ld.ld_id = cu.ld_id
              
           AND TRUNC(cu.cu_datetime) NOT IN ( TO_DATE('&Fecha1', 'dd-mm-yyyy') , TO_DATE('&Fecha2', 'dd-mm-yyyy'))
           AND udf.udf_receivedate > (sysdate - 60)
           AND udf.tp_id in (44)
           AND (CU.cu_farevalue > 0 or CU.app_id in (920, 902)) -- Solo usos pagos (efectivo o bancos)
        --AND  ((CU.cu_farevalue >= 0 or cu.cu_itg_ctr is not null) or CU.app_id in (920,902) OR app.af_id = 30 )
        --and cu.cu_itg_ctr is null
        --and cu.cu_farevalue not in ('2.40','2.20' )--0.0
        
         GROUP BY trunc(cu.cu_datetime),
                  cu.cu_farevalue,
                  cu.app_id,
                  cu.cu_itg_ctr,
                  cu.cu_datetime,
                  cu.cu_dat_inc_puente,
                  ld.ld_desc
        
        )

 GROUP BY FECHA, TARIFA, PUENTE, MONTO, CANTIDAD) p
 GROUP BY trunc(p.fecha_uso)

 order by 1 asc;
/*--------------------***********CONSULTAR TRANSACCIONES MIO CABLE V 2.0******----------------
SELECT FECHA,
       SUM (MONTO) AS MONTO_USOS,
       SUM (CANTIDAD) AS CANTIDAD_USOS,
       TARIFA, TRUNC(PUENTE), 
       
    
    FROM(SELECT 
           trunc (cu.cu_datetime) AS FECHA,
           count (cu.cu_unique_id) as CANTIDAD,
           CASE -- IDENTIFICA USOS POR TARIFA
                      WHEN ((cu.app_id = 902 OR cu.app_id = 920) AND cu.cu_itg_ctr IS NULL) THEN
                        CASE WHEN (TRUNC(cu.cu_datetime) < to_date('24/01/2022','dd-mm-yyyy')) THEN
                          2200
                          WHEN (TRUNC(cu.cu_datetime) BETWEEN  to_date('25/01/2022','dd-mm-yyyy') AND to_date('22/01/2023','dd-mm-yyyy')) THEN
                            2400
                        ELSE 
                          2700
                        END 
                      ELSE
                        cu.cu_farevalue * 1000 
                    END AS TARIFA,
           CASE -- MONTO TOTAL DE USOS POR TARIFA
                      WHEN ((cu.app_id = 902 OR cu.app_id = 920) AND cu.cu_itg_ctr IS NULL) THEN
                        CASE WHEN (TRUNC(cu.cu_datetime) < to_date('24/01/2022','dd-mm-yyyy')) THEN
                          2200 * COUNT(cu.CU_UNIQUE_ID)
                          WHEN (TRUNC(cu.cu_datetime) BETWEEN  to_date('25/01/2022','dd-mm-yyyy') AND to_date('22/01/2023','dd-mm-yyyy')) THEN
                            2400 * COUNT(cu.CU_UNIQUE_ID)
                        ELSE 
                          2700 * COUNT (cu.CU_UNIQUE_ID)
                        END 
                      ELSE
                         cu.cu_farevalue * count(cu_unique_id) * 1000 
                    END AS MONTO,
                    cu.cu_dat_inc_puente PUENTE
           --cu.cu_farevalue * count(cu_unique_id) * 1000 as MONTO 
                             
      FROM 
           mercury.CARDUSAGE        cu,
           mercury.linedetails      ld,
           mercury.USAGEDATATRIPMT  udtm,
           mercury.USAGEDATASERVICE uds,
           mercury.USAGEDATAFILE    udf,
           mercury.applications     app
     WHERE 1 = 1
           AND CU.UDTM_ID = UDTM.UDTM_ID
           AND UDTM.UDS_ID = UDS.UDS_ID
           AND UDS.UDF_ID = UDF.UDF_ID
           AND cu.cu_datetime >= to_Date('16-06-2023 00:01', 'dd-mm-yyyy hh24:mi') --trunc (sysdate -1) Dias liquidados
            AND cu.cu_datetime <= to_Date('30-06-2023 23:59', 'dd-mm-yyyy hh24:mi') --trunc (sysdate)    Dias liquidados
--            AND     udf.udf_receivedate >= to_date('16-06-2023 00:01','dd-mm-yyyy hh24:mi')
--             AND     udf.udf_receivedate <= to_date('30-06-2023 23:59','dd-mm-yyyy hh24:mi')
           --AND cu.cu_dat_inc_puente >= to_Date('16-07-2022 00:01', 'dd-mm-yyyy hh24:mi') --trunc (sysdate -1) Dias liquidados
           --AND cu.cu_dat_inc_puente <= to_Date('31-07-2022 23:59', 'dd-mm-yyyy hh24:mi')
           AND cu.cut_id = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
           AND NVL(cu.cu_partfareseqnbr, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
           AND app.app_id = cu.app_id
           AND ld.ld_id = cu.ld_id
          --AND     udf.tp_id not in (25,44)
--           AND TO_CHAR(cu.cu_datetime, 'yyyy')<>2023
             AND udf.udf_receivedate > (sysdate-60)
       AND udf.tp_id in (44,45) --
       AND (CU.cu_farevalue > 0 or CU.app_id in (920, 902))  -- Solo usos pagos (efectivo o bancos)
       --AND  ((CU.cu_farevalue >= 0 or cu.cu_itg_ctr is not null) or CU.app_id in (920,902) OR app.af_id = 30 )
       --and cu.cu_itg_ctr is null
       --and cu.cu_farevalue not in ('2.40','2.20' )--0.0

     GROUP BY 
              trunc (cu.cu_datetime),cu.cu_farevalue, cu.app_id, cu.cu_itg_ctr, cu.cu_datetime, cu.cu_dat_inc_puente
              
     )
    
GROUP BY FECHA, TARIFA, TRUNC(PUENTE)
       --CANTIDAD_USOS,
       --MONTO_USOS --trunc(cu.cu_datetime),cu.cu_farevalue, cu.app_id, cu.cu_itg_ctr, cu.cu_datetime
          
          order by 1 asc;
/
--------------------***********CONSULTAR TRANSACCIONES MIO CABLE V 1.0******----------------
SELECT 
       to_char(cu.cu_datetime, 'DD/MM/YYYY') AS FECHA,
       count (app.app_descshort) as CANTIDAD,
       count (app.app_descshort)*2400 as total
  FROM 
       mercury.CARDUSAGE        cu,
       mercury.linedetails      ld,
       mercury.USAGEDATATRIPMT  udtm,
       mercury.USAGEDATASERVICE uds,
       mercury.USAGEDATAFILE    udf,
       mercury.applications     app
 WHERE 1 = 1
       AND CU.UDTM_ID = UDTM.UDTM_ID
       AND UDTM.UDS_ID = UDS.UDS_ID
       AND UDS.UDF_ID = UDF.UDF_ID
       AND cu.cu_datetime >= to_Date('01-12-2022 00:01', 'dd-mm-yyyy hh24:mi') --trunc (sysdate -1) Dias liquidados
       AND cu.cu_datetime <= to_Date('15-12-2022 23:59', 'dd-mm-yyyy hh24:mi') --trunc (sysdate)    Dias liquidados
       AND cu.cut_id = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
       AND NVL(cu.cu_partfareseqnbr, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
       AND app.app_id = cu.app_id
       AND ld.ld_id = cu.ld_id
      --AND     udf.tp_id not in (25,44)
   AND udf.tp_id = 44 --
   AND (CU.cu_farevalue > 0 or CU.app_id in (920, 902))  -- Solo usos pagos (efectivo o bancos)
   --and cu.cu_farevalue = 2.40

 GROUP BY 
          to_char(cu.cu_datetime, 'DD/MM/YYYY')
          order by 1 asc
          ;
/

--DETALLE DE USOS MIO CABLE
SELECT  trunc(cu.cu_datetime) AS FECHA_USO,
--        trunc(cu.cu_dat_inc_puente)  AS FECHA_PUENTE,
--        to_char(cu.cu_dat_inc_puente, 'HH24') AS HORA_PUENTE,
        
--        to_char(cu.cu_datetime, 'YYYY') AS ANO,
--        to_char(cu.cu_datetime, 'MM') AS MES,
--        to_char(cu.cu_datetime, 'HH24') AS HORA,
        ld.ld_desc      AS ESTACION,
--        app.app_descshort    AS PRODUCTO,
        cu.crd_snr,
        cu.cd_id,
--        cu.cu_itg_ctr        AS INTEGRACION,
        --to_char(cu.cu_datetime, 'YYYY-MM-DD') AS FECHA,
       
--        udf.veh_id as VEH_ID,
--        cu.cu_farevalue AS CU_FAREVALUE ,
        COUNT(1)                     AS QPAX    
  FROM  mercury.CARDUSAGE           cu,
        mercury.linedetails         ld,
        mercury.USAGEDATATRIPMT     udtm,
        mercury.USAGEDATASERVICE    uds,  
        mercury.USAGEDATAFILE       udf,
        mercury.applications        app    
  WHERE 1=1          
  AND     CU.UDTM_ID = UDTM.UDTM_ID
  AND     UDTM.UDS_ID = UDS.UDS_ID
  AND     UDS.UDF_ID = UDF.UDF_ID
  AND     cu.cu_datetime >= TO_DATE('01-01-2023 00:01', 'dd-mm-yyyy hh24:mi')
  AND     cu.cu_datetime <= TO_DATE('31-01-2023 23:59', 'dd-mm-yyyy hh24:mi')
--  AND     udf.udf_receivedate >= to_date('23-01-2023 00:01','dd-mm-yyyy hh24:mi')
  --AND     udf.udf_receivedate <= to_date('01-07-2022 09:00','dd-mm-yyyy hh24:mi')

  AND     cu.cut_id = 1                      -- Tipos de uso -> 1: Passenger use, 5: On-board sale
  AND     NVL(cu.cu_partfareseqnbr,0) <> 2   -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
  AND     app.app_id = cu.app_id
  AND     ld.ld_id = cu.ld_id
  AND     udf.tp_id in (44) --*** 44- MIO Cable
 
  ---  AND     udf.tp_id > 4
  AND  (CU.cu_farevalue > 0 or CU.app_id in (920,902) ) -- Solo usos pagos y funcionario

 
GROUP BY  ld.ld_desc,
--app.app_descshort,
--cu.cu_itg_ctr,
--cu.crd_snr,
--cu.cd_id,
--to_char(cu.cu_datetime, 'YYYY-MM-DD'),
trunc(cu.cu_datetime),
to_char(cu.cu_datetime, 'YYYY'),
to_char(cu.cu_datetime, 'MM'),
cu.crd_snr,
cu.cd_id
--to_char(cu.cu_datetime, 'HH24')
--trunc(cu.cu_dat_inc_puente),
--to_char(cu.cu_dat_inc_puente, 'HH24'),

--,udf.veh_id
--,cu.cu_farevalue
ORDER BY 1 ASC
;

;
SELECT  TRUNC(cu.cu_datetime) AS FECHA_USO,
        --to_char(CU.cu_datetime, 'hh24') HORA,
        TRUNC(CU.cu_dat_inc_puente) FECHA_PUENTE,
        --to_char(CU.cu_dat_inc_puente, 'hh24') as HORA_PUENTE,
        TRUNC(UDF.udf_receivedate) FECHA_UDP,
        --to_char(UDF.udf_receivedate, 'hh24') as HORA_UDP,
        ld.ld_desc      AS ESTACION,
        --cu.cu_itg_ctr   AS INTEGRACION,
        --app.app_descshort    AS PRODUCTO,
        --udf.veh_id      AS VEH_ID,
        CASE 
          WHEN ((cu.app_id = 902 OR cu.app_id = 920) AND cu.cu_itg_ctr IS NULL) THEN
                CASE WHEN (TRUNC(cu.cu_datetime) < to_date('24/01/2022','dd-mm-yyyy')) THEN
                  2200
                ELSE 
                  2400
                END 
              ELSE
                cu.cu_farevalue * 1000
            END AS Monto,
       

       \* CASE
          WHEN to_number(to_char(CU.cu_dat_inc_puente, 'hh24')) > 7 THEN TRUNC(CU.cu_dat_inc_puente)
          ELSE
            CASE
              WHEN TRUNC(CU.cu_dat_inc_puente) = TRUNC(cu.cu_datetime) THEN TRUNC(CU.cu_dat_inc_puente)
              ELSE TRUNC(CU.cu_dat_inc_puente)-1
            END
        END AS FECHA_DIALIQ*\
        COUNT(1)        AS CANTIDAD_USOS

  FROM  mercury.CARDUSAGE           cu,
        mercury.linedetails         ld,
        mercury.USAGEDATATRIPMT     udtm,
        mercury.USAGEDATASERVICE    uds,
        mercury.USAGEDATAFILE       udf,
        mercury.applications        app
  WHERE   CU.UDTM_ID = UDTM.UDTM_ID
  AND     UDTM.UDS_ID = UDS.UDS_ID
  AND     UDS.UDF_ID = UDF.UDF_ID
  AND     cu.cu_datetime >= TO_DATE('01-03-2022 00:01', 'dd-mm-yyyy hh24:mi')
  AND     cu.cu_datetime <= TO_DATE('31-03-2022 23:59', 'dd-mm-yyyy hh24:mi')
  --AND  TRUNC (CU.cu_dat_inc_puente) = to_date('03-08-2022','dd-mm-yyyy') --Fecha Tabla Puente --6am, 12pm, 4pm
  --AND  CU.cu_dat_inc_puente <= to_date('16-07-2022 07:59:00','dd-mm-yyyy hh24:mi:ss')
  AND     cu.cut_id = 1       -- Tipos de uso -> 1: Passenger use, 5: On-board sale
  AND     NVL(cu.cu_partfareseqnbr,0) <> 2   -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
  AND     app.app_id = cu.app_id
  AND     ld.ld_id = cu.ld_id
  AND     udf.tp_id in (25,44,45) --* 44 MIO Cable, 45 Cañaveral, 25 DISPENSADORES KAWY 
  AND  ((CU.cu_farevalue >= 0 or cu.cu_itg_ctr is not null) or CU.app_id in (920,902) OR app.af_id = 30 )
  --AND  cu.cu_itg_ctr is null
  --AND ((CU.cu_farevalue > 0) or CU.app_id in (920,902)) -- Solo usos pagos
  --HAVING COUNT(*) = 1

GROUP BY ld.ld_desc,
app.app_descshort,
cu.app_id,
cu.cu_itg_ctr,
trunc(cu.cu_datetime),
--to_char(CU.cu_datetime, 'hh24'),
TRUNC(CU.cu_dat_inc_puente),
--app.app_descshort,
--udf.veh_id,
to_char(CU.cu_dat_inc_puente, 'hh24'),
TRUNC(UDF.udf_receivedate),
to_char(UDF.udf_receivedate, 'hh24'),
cu.cu_farevalue
;
*/
