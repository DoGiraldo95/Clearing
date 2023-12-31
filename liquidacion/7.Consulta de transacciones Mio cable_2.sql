--------------------***********CONSULTAR TRANSACCIONES MIO CABLE V 2.0******----------------
SELECT
   FECHA,
   SUM(MONTO)    AS MONTO_USOS,
   SUM(CANTIDAD) AS CANTIDAD_USOS
 --        ,TARIFA
 --          ,PUENTE
 --         ,ESTACION
FROM
   (
      SELECT
         TRUNC(CU.CU_DATETIME)                                                                                                                                                    AS FECHA,
         COUNT(CU.CU_UNIQUE_ID)                                                                                                                                                   AS CANTIDAD,
         CASE -- IDENTIFICA USOS POR TARIFA
            WHEN ((CU.APP_ID = 902
            OR CU.APP_ID = 920)
            AND CU.CU_ITG_CTR IS NULL) THEN
               CASE
                  WHEN (TRUNC(CU.CU_DATETIME) < TO_DATE('24/01/2022', 'dd-mm-yyyy')) THEN
                     2200
                  WHEN (TRUNC(CU.CU_DATETIME) BETWEEN TO_DATE('25/01/2022', 'dd-mm-yyyy')
                  AND TO_DATE('22/01/2023', 'dd-mm-yyyy')) THEN
                     2400
                  ELSE
                     2700
               END
            ELSE
               CU.CU_FAREVALUE * 1000
         END AS                                                                         TARIFA,
         CASE -- MONTO TOTAL DE USOS POR TARIFA
            WHEN ((CU.APP_ID = 902
            OR CU.APP_ID = 920)
            AND CU.CU_ITG_CTR IS NULL) THEN
               CASE
                  WHEN (TRUNC(CU.CU_DATETIME) < TO_DATE('24/01/2022', 'dd-mm-yyyy')) THEN
                     2200 * COUNT(CU.CU_UNIQUE_ID)
                  WHEN (TRUNC(CU.CU_DATETIME) BETWEEN TO_DATE('25/01/2022', 'dd-mm-yyyy')
                  AND TO_DATE('22/01/2023', 'dd-mm-yyyy')) THEN
                     2400 * COUNT(CU.CU_UNIQUE_ID)
                  ELSE
                     2700 * COUNT(CU.CU_UNIQUE_ID)
               END
            ELSE
               CU.CU_FAREVALUE * COUNT(CU_UNIQUE_ID) * 1000
         END AS MONTO,
         CU.CU_DAT_INC_PUENTE                                                                                                                                                     PUENTE
 --cu.cu_farevalue * count(cu_unique_id) * 1000 as MONTO
,
         LD.LD_DESC                                                                                                                                                               ESTACION
      FROM
         MERCURY.CARDUSAGE        CU,
         MERCURY.LINEDETAILS      LD,
         MERCURY.USAGEDATATRIPMT  UDTM,
         MERCURY.USAGEDATASERVICE UDS,
         MERCURY.USAGEDATAFILE    UDF,
         MERCURY.APPLICATIONS     APP
      WHERE
         1 = 1
         AND CU.UDTM_ID = UDTM.UDTM_ID
         AND UDTM.UDS_ID = UDS.UDS_ID
         AND UDS.UDF_ID = UDF.UDF_ID
         AND CU.CU_DATETIME >= TO_DATE('01-08-2023 00:01', 'dd-mm-yyyy hh24:mi') --trunc (sysdate -1) paso 1
         AND CU.CU_DATETIME <= TO_DATE('15-08-2023 23:59', 'dd-mm-yyyy hh24:mi') --trunc (sysdate)    Dias liquidados

 /*  AND     udf.udf_receivedate >= to_date('16-06-2023 00:01','dd-mm-yyyy hh24:mi') 
             AND     udf.udf_receivedate <= to_date('01-07-2023 23:59','dd-mm-yyyy hh24:mi') --paso 2*/
 --AND cu.cu_dat_inc_puente >= to_Date('16-07-2022 00:01', 'dd-mm-yyyy hh24:mi') --trunc (sysdate -1) Dias liquidados
 --AND cu.cu_dat_inc_puente <= to_Date('31-07-2022 23:59', 'dd-mm-yyyy hh24:mi')
         AND CU.CUT_ID = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
         AND NVL(CU.CU_PARTFARESEQNBR, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
         AND APP.APP_ID = CU.APP_ID
         AND LD.LD_ID = CU.LD_ID
 --AND     udf.tp_id not in (25,44)
 --            AND TO_CHAR(cu.cu_datetime, 'yyyy')<>2023
 --            AND TRUNC (cu.cu_datetime) <> TO_DATE('01-07-2023', 'dd-mm-yyyy')
 --             AND udf.udf_receivedate > (sysdate - 60)
         AND UDF.TP_ID IN (44) --
         AND (CU.CU_FAREVALUE > 0
         OR CU.APP_ID IN (920, 902)) -- Solo usos pagos (efectivo o bancos)
 --AND  ((CU.cu_farevalue >= 0 or cu.cu_itg_ctr is not null) or CU.app_id in (920,902) OR app.af_id = 30 )
 --and cu.cu_itg_ctr is null
 --and cu.cu_farevalue not in ('2.40','2.20' )--0.0
      GROUP BY
         TRUNC(CU.CU_DATETIME), CU.CU_FAREVALUE, CU.APP_ID, CU.CU_ITG_CTR, CU.CU_DATETIME, CU.CU_DAT_INC_PUENTE, LD.LD_DESC
   )
GROUP BY
   FECHA /*, TARIFA,ESTACION ,PUENTE*/
 --CANTIDAD_USOS,
 --MONTO_USOS --trunc(cu.cu_datetime),cu.cu_farevalue, cu.app_id, cu.cu_itg_ctr, cu.cu_datetime
ORDER BY
   1 ASC;

/

--------------------***********CONSULTAR TRANSACCIONES MIO CABLE V 1.0******----------------
SELECT
   TO_CHAR(CU.CU_DATETIME, 'DD/MM/YYYY') AS FECHA,
   COUNT(APP.APP_DESCSHORT)              AS CANTIDAD,
   COUNT(APP.APP_DESCSHORT) * 2400 AS TOTAL
FROM
   MERCURY.CARDUSAGE        CU,
   MERCURY.LINEDETAILS      LD,
   MERCURY.USAGEDATATRIPMT  UDTM,
   MERCURY.USAGEDATASERVICE UDS,
   MERCURY.USAGEDATAFILE    UDF,
   MERCURY.APPLICATIONS     APP
WHERE
   1 = 1
   AND CU.UDTM_ID = UDTM.UDTM_ID
   AND UDTM.UDS_ID = UDS.UDS_ID
   AND UDS.UDF_ID = UDF.UDF_ID
   AND CU.CU_DATETIME >= TO_DATE('01-12-2022 00:01', 'dd-mm-yyyy hh24:mi') --trunc (sysdate -1) Dias liquidados
   AND CU.CU_DATETIME <= TO_DATE('15-12-2022 23:59', 'dd-mm-yyyy hh24:mi') --trunc (sysdate)    Dias liquidados
   AND CU.CUT_ID = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
   AND NVL(CU.CU_PARTFARESEQNBR, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
   AND APP.APP_ID = CU.APP_ID
   AND LD.LD_ID = CU.LD_ID
 --AND     udf.tp_id not in (25,44)
   AND UDF.TP_ID = 44 --
   AND (CU.CU_FAREVALUE > 0
   OR CU.APP_ID IN (920, 902)) -- Solo usos pagos (efectivo o bancos)
 --and cu.cu_farevalue = 2.40
GROUP BY
   TO_CHAR(CU.CU_DATETIME, 'DD/MM/YYYY')
ORDER BY
   1 ASC;

/

--DETALLE DE USOS MIO CABLE
SELECT
   TRUNC(CU.CU_DATETIME) AS FECHA_USO,
 --        trunc(cu.cu_dat_inc_puente)  AS FECHA_PUENTE,
 --        to_char(cu.cu_dat_inc_puente, 'HH24') AS HORA_PUENTE,
 --        to_char(cu.cu_datetime, 'YYYY') AS ANO,
 --        to_char(cu.cu_datetime, 'MM') AS MES,
 --        to_char(cu.cu_datetime, 'HH24') AS HORA,
   LD.LD_DESC            AS ESTACION,
 --        app.app_descshort    AS PRODUCTO,
   CU.CRD_SNR,
   CU.CD_ID,
 --        cu.cu_itg_ctr        AS INTEGRACION,
 --to_char(cu.cu_datetime, 'YYYY-MM-DD') AS FECHA,
 --        udf.veh_id as VEH_ID,
 --        cu.cu_farevalue AS CU_FAREVALUE ,
   COUNT(1)              AS QPAX
FROM
   MERCURY.CARDUSAGE        CU,
   MERCURY.LINEDETAILS      LD,
   MERCURY.USAGEDATATRIPMT  UDTM,
   MERCURY.USAGEDATASERVICE UDS,
   MERCURY.USAGEDATAFILE    UDF,
   MERCURY.APPLICATIONS     APP
WHERE
   1 = 1
   AND CU.UDTM_ID = UDTM.UDTM_ID
   AND UDTM.UDS_ID = UDS.UDS_ID
   AND UDS.UDF_ID = UDF.UDF_ID
   AND CU.CU_DATETIME >= TO_DATE('01-01-2023 00:01', 'dd-mm-yyyy hh24:mi')
   AND CU.CU_DATETIME <= TO_DATE('31-01-2023 23:59', 'dd-mm-yyyy hh24:mi')
 --  AND     udf.udf_receivedate >= to_date('23-01-2023 00:01','dd-mm-yyyy hh24:mi')
 --AND     udf.udf_receivedate <= to_date('01-07-2022 09:00','dd-mm-yyyy hh24:mi')
   AND CU.CUT_ID = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
   AND NVL(CU.CU_PARTFARESEQNBR, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
   AND APP.APP_ID = CU.APP_ID
   AND LD.LD_ID = CU.LD_ID
   AND UDF.TP_ID IN (44) --*** 44- MIO Cable
 ---  AND     udf.tp_id > 4
   AND (CU.CU_FAREVALUE > 0
   OR CU.APP_ID IN (920, 902)) -- Solo usos pagos y funcionario
GROUP BY
   LD.LD_DESC,
 --app.app_descshort,
 --cu.cu_itg_ctr,
 --cu.crd_snr,
 --cu.cd_id,
 --to_char(cu.cu_datetime, 'YYYY-MM-DD'),
   TRUNC(CU.CU_DATETIME), TO_CHAR(CU.CU_DATETIME, 'YYYY'), TO_CHAR(CU.CU_DATETIME, 'MM'), CU.CRD_SNR, CU.CD_ID
 --to_char(cu.cu_datetime, 'HH24')
 --trunc(cu.cu_dat_inc_puente),
 --to_char(cu.cu_dat_inc_puente, 'HH24'),
 --,udf.veh_id
 --,cu.cu_farevalue
ORDER BY
   1 ASC;;

SELECT
   TRUNC(CU.CU_DATETIME)                                                                                                                                           AS FECHA_USO,
 --to_char(CU.cu_datetime, 'hh24') HORA,
   TRUNC(CU.CU_DAT_INC_PUENTE)                                                                                                                                     FECHA_PUENTE,
 --to_char(CU.cu_dat_inc_puente, 'hh24') as HORA_PUENTE,
   TRUNC(UDF.UDF_RECEIVEDATE)                                                                                                                                      FECHA_UDP,
 --to_char(UDF.udf_receivedate, 'hh24') as HORA_UDP,
   LD.LD_DESC                                                                                                                                                      AS ESTACION,
 --cu.cu_itg_ctr   AS INTEGRACION,
 --app.app_descshort    AS PRODUCTO,
 --udf.veh_id      AS VEH_ID,
   CASE
      WHEN ((CU.APP_ID = 902
      OR CU.APP_ID = 920)
      AND CU.CU_ITG_CTR IS NULL) THEN
         CASE
            WHEN (TRUNC(CU.CU_DATETIME) < TO_DATE('24/01/2022', 'dd-mm-yyyy')) THEN
               2200
            ELSE
               2400
         END
      ELSE
         CU.CU_FAREVALUE * 1000
   END AS MONTO,
 /* CASE
         WHEN to_number(to_char(CU.cu_dat_inc_puente, 'hh24')) > 7 THEN TRUNC(CU.cu_dat_inc_puente)
         ELSE
           CASE
             WHEN TRUNC(CU.cu_dat_inc_puente) = TRUNC(cu.cu_datetime) THEN TRUNC(CU.cu_dat_inc_puente)
             ELSE TRUNC(CU.cu_dat_inc_puente)-1
           END
       END AS FECHA_DIALIQ*/
   COUNT(1)                                                                                                                                                        AS CANTIDAD_USOS
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
   AND CU.CU_DATETIME >= TO_DATE('01-03-2022 00:01', 'dd-mm-yyyy hh24:mi')
   AND CU.CU_DATETIME <= TO_DATE('31-03-2022 23:59', 'dd-mm-yyyy hh24:mi')
 --AND  TRUNC (CU.cu_dat_inc_puente) = to_date('03-08-2022','dd-mm-yyyy') --Fecha Tabla Puente --6am, 12pm, 4pm
 --AND  CU.cu_dat_inc_puente <= to_date('16-07-2022 07:59:00','dd-mm-yyyy hh24:mi:ss')
   AND CU.CUT_ID = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
   AND NVL(CU.CU_PARTFARESEQNBR, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
   AND APP.APP_ID = CU.APP_ID
   AND LD.LD_ID = CU.LD_ID
   AND UDF.TP_ID IN (25, 44, 45) --* 44 MIO Cable, 45 Ca�averal, 25 DISPENSADORES KAWY
   AND ((CU.CU_FAREVALUE >= 0
   OR CU.CU_ITG_CTR IS NOT NULL)
   OR CU.APP_ID IN (920, 902)
   OR APP.AF_ID = 30)
 --AND  cu.cu_itg_ctr is null
 --AND ((CU.cu_farevalue > 0) or CU.app_id in (920,902)) -- Solo usos pagos
 --HAVING COUNT(*) = 1
GROUP BY
   LD.LD_DESC, APP.APP_DESCSHORT, CU.APP_ID, CU.CU_ITG_CTR, TRUNC(CU.CU_DATETIME),
 --to_char(CU.cu_datetime, 'hh24'),
   TRUNC(CU.CU_DAT_INC_PUENTE),
 --app.app_descshort,
 --udf.veh_id,
   TO_CHAR(CU.CU_DAT_INC_PUENTE, 'hh24'), TRUNC(UDF.UDF_RECEIVEDATE), TO_CHAR(UDF.UDF_RECEIVEDATE, 'hh24'), CU.CU_FAREVALUE;