SELECT
  TRUNC(CU.CU_DATETIME)                                                                                                                                                                                                                            AS FECHA_USO,
  TRUNC(CU.CU_DAT_INC_PUENTE)                                                                                                                                                                                                                      FECHA_PUENTE,
  TO_CHAR(CU.CU_DAT_INC_PUENTE, 'hh24')                                                                                                                                                                                                            AS HORA_PUENTE,
  TRUNC(UDF.UDF_RECEIVEDATE)                                                                                                                                                                                                                       FECHA_UDP,
  TO_CHAR(UDF.UDF_RECEIVEDATE, 'hh24')                                                                                                                                                                                                             AS HORA_UDP,
  LD.LD_DESC                                                                                                                                                                                                                                       AS ESTACION,
  CU.CU_ITG_CTR                                                                                                                                                                                                                                    AS INTEGRACION,
  APP.APP_DESCSHORT                                                                                                                                                                                                                                AS PRODUCTO,
  UDF.VEH_ID                                                                                                                                                                                                                                       AS VEH_ID,
  CU.CU_FAREVALUE                                                                                                                                                                                                                                  AS MONTO,
  CASE
    WHEN LENGTH(UDF.VEH_ID) < 5 THEN
      'Estaciones'
    ELSE
      CASE
        WHEN SUBSTR(UDF.VEH_ID, 2, 1) = 2 THEN
          'Padron'
        WHEN SUBSTR(UDF.VEH_ID, 2, 1) = 3 THEN
          'Complementario'
        ELSE
          'Otro'
      END
  END AS                                                         TIPOLOGIA,
  CASE
    WHEN TO_NUMBER(TO_CHAR(CU.CU_DAT_INC_PUENTE, 'hh24')) > 7 THEN
      TRUNC(CU.CU_DAT_INC_PUENTE)
    ELSE
      CASE
        WHEN TRUNC(CU.CU_DAT_INC_PUENTE) = TRUNC(CU.CU_DATETIME) THEN
          TRUNC(CU.CU_DAT_INC_PUENTE)
        ELSE
          TRUNC(CU.CU_DAT_INC_PUENTE) - 1
      END
  END AS FECHA_DIALIQ,
  COUNT(1)                                                                                                                                                                                                                                         AS CANTIDAD_USOS
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
  AND CU.CU_DAT_INC_PUENTE >= TO_DATE('&Fecha_1 07:59:00', 'dd-mm-yyyy hh24:mi:ss') --Fecha Tabla Puente --6am, 12m, 4pm-- dos dias antes de la fecha de proceso (Actual)
  AND CU.CU_DAT_INC_PUENTE <= TO_DATE('&Fecha_2 07:59:00', 'dd-mm-yyyy hh24:mi:ss') --Un dia despues de la fecha consulta de transacciones (Evaluacion de transacciones)
  AND CU.CUT_ID = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
  AND NVL(CU.CU_PARTFARESEQNBR, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
  AND APP.APP_ID = CU.APP_ID
  AND LD.LD_ID = CU.LD_ID
  AND UDF.TP_ID NOT IN (25, 44) --*** 44- MIO Cable
  AND CU.CU_ITG_CTR IS NULL
  AND ((CU.CU_FAREVALUE > 0)
  OR CU.APP_ID IN (920, 902)) -- Solo usos pagos 'BANBOGOTA - BANCOLOMBIA'
 --AND  ((CU.cu_farevalue >= 0 or cu.cu_itg_ctr is not null) or CU.app_id in (920,902) OR app.af_id = 30 )---- Todos los productos
GROUP BY
  LD.LD_DESC, APP.APP_DESCSHORT, CU.CU_ITG_CTR, TRUNC(CU.CU_DATETIME), TRUNC(CU.CU_DAT_INC_PUENTE), APP.APP_DESCSHORT, UDF.VEH_ID, TO_CHAR(CU.CU_DAT_INC_PUENTE, 'hh24'), TRUNC(UDF.UDF_RECEIVEDATE), TO_CHAR(UDF.UDF_RECEIVEDATE, 'hh24'), CU.CU_FAREVALUE;

--*******************************************************************************************
--*************************** VERIFICACION USOS VISA ***************************************
SELECT
  (COUNT(*)) QTRX
FROM
  (
    SELECT
      CASE
        WHEN A.ROUTE_ID = 'BUS NO REG RUTA' THEN
          '236' --Generica P99
        WHEN A.ROUTE_ID = 'ESTACION SIN RUTA' THEN
          '235' -- A99
        WHEN A.ROUTE_ID IS NULL THEN
          '236'
        ELSE
          A.ROUTE_ID
      END AS                                                                                LD_ID,
      'VISA'                                                                                                                                AS APP_DESCSHORT,
      19 AS ISS_ID,
      99 AS CD_ID,
      A.BIN
        || A.LAST4                                                                                                                          AS BIN_LAST4, --crd snr
      A.CARD_NUMBER,
      999 AS APP_ID,
      A.TSN_REG,
      CASE
        WHEN A.IS_TRANSFER = 0 OR A.IS_TRANSFER = 1 THEN
          ''
        WHEN A.IS_TRANSFER = 2 THEN
          '1'
        WHEN A.IS_TRANSFER = 3 THEN
          '2'
        ELSE
          '1'
      END AS CU_ITG_CTR,
      A.ENTRY_DATE,
      A.FECHA_WS,
      A.RESPONSE_DATE,
      A.VISA_DAT_INC_PUENTE,
      A.DEVICE_ID,
      999 AS TP_ID,
 /*CASE
         WHEN a.importe = 2400 THEN 2200
         ELSE a.importe
       END AS IMPORTE,*/
      A.IMPORTE,
      COUNT(*)                                                                                                                              AS QPAX
    FROM
      MERCURY.TBL_TRX_UTRYTOPCS A
    WHERE
      A.STATUS = 'A'
      AND A.PROCESSED IN ('S', 'C')
      AND TRUNC(A.VISA_DAT_INC_PUENTE) = TRUNC(SYSDATE) --to_date('05/05/5555','dd-mm-yyyy')
      AND TRUNC(A.FECHA_WS) >= TRUNC (SYSDATE) -- to_date('05-04-2023 00:01','dd-mm-yyyy hh24:mi') -- Todos los Lunes (sysdate-2)
 --AND a.fecha_ws <= to_date('07-09-2021 23:59','dd-mm-yyyy hh24:mi')--trunc (sysdate)
      AND RESPONSE_DATE IS NOT NULL
    GROUP BY
      A.ROUTE_ID, A.BIN
                    || A.LAST4, A.CARD_NUMBER, A.TSN_REG, A.IS_TRANSFER, A.ENTRY_DATE, A.VISA_DAT_INC_PUENTE, A.DEVICE_ID, A.IMPORTE, A.FECHA_WS, A.RESPONSE_DATE
    ORDER BY
      ENTRY_DATE ASC
  ) T;
