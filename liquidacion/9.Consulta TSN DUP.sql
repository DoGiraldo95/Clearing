--TSN Duplicados

SELECT
  A.CU_DATETIME,
  A.CD_ID,
  A.CRD_SNR,
  A.CU_TSN,
  COUNT(*)
FROM
  MERCURY.TBL_TSN_DUPLICADOS A
WHERE
  TRUNC(A.CU_DATETIME) >= TRUNC(SYSDATE - 1)
  AND TRUNC(A.CU_DATETIME) < TRUNC(SYSDATE)
  AND CD_ID IN (5, 6)
 --HAVING COUNT(*) > 1
GROUP BY
  A.CU_DATETIME, A.CRD_SNR, A.CD_ID, A.CU_TSN
ORDER BY
  5 ASC;

/

SELECT
  CADENA,
  COUNT(*)
FROM
  (
    SELECT
      LD.LD_ID,
      APP.APP_DESCSHORT,
      CU.ISS_ID,
      CU.CD_ID,
      CU.CRD_SNR,
 --CU.CU_CRDINTSNR,
      CU.APP_ID,
      CU.CU_TSN,
      CU.CU_ITG_CTR,
 --cu.cu_datetime,
 --cu_dat_inc_puente,
      UDF.VEH_ID,
      UDF.TP_ID,
 --cu.cu_farevalue * 1000 AS CU_FAREVALUE,
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
      END AS CU_FAREVALUE, --* Modificacion Farevalue
      CU.APP_ID
                                     || '-'
                                     || CU.CRD_SNR
                                     || '-'
                                     || CU.CU_TSN
                                     || '-'
                                     || CU.CD_ID                                                                                                                                                  AS CADENA,
      COUNT(1)                                                                                                                                                        AS QPAX
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
      AND CU.CU_DAT_INC_PUENTE >= TO_DATE('&Fecha_Minima 07:59', 'dd-mm-yyyy hh24:mi') --FECHA_MIN --Fecha Tabla Puente
      AND CU.CU_DAT_INC_PUENTE <= TO_DATE('&Fecha_Maxima 07:59', 'dd-mm-yyyy hh24:mi') --FECHA_MAX
      AND CU.CUT_ID = 23 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
      AND NVL(CU.CU_PARTFARESEQNBR, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
      AND APP.APP_ID = CU.APP_ID
      AND LD.LD_ID = CU.LD_ID
      AND UDF.TP_ID NOT IN (25, 52) --* 52 -
      AND ((CU.CU_FAREVALUE > 0
      OR CU.CU_ITG_CTR IS NOT NULL)
      OR CU.APP_ID IN (920, 902)) -- Solo usos pagos
 --AND cu.app_id = 500
 --AND cu.CU_CRDINTSNR = 1530383786
 --AND cu.cu_tsn = 16
 --AND cu.cd_id = 6
    GROUP BY
      LD.LD_ID, APP.APP_DESCSHORT, CU.CU_ITG_CTR,
 -- to_char(cu.cu_datetime, 'YYYY-MM-DD'),
      CU.CU_DATETIME,
 --cu_dat_inc_puente,
      UDF.VEH_ID, CU.CU_FAREVALUE * 1000, CU.ISS_ID, CU.CD_ID, CU.CRD_SNR,
 --cu.CU_CRDINTSNR,
      CU.APP_ID, CU.CU_TSN, UDF.TP_ID, CU.APP_ID
                                          || CU.CRD_SNR
                                          || CU.CU_TSN
                                          || CU.CD_ID
  )
HAVING
  COUNT(*) > 1
GROUP BY
  CADENA;