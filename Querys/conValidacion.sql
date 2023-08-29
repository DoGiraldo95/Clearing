SELECT
  ROWID,
  A.*
FROM
  MERCURY.TBL_LIQUIDACIONRYT_DATE A
WHERE
  A.DATE_LIQ = /* BETWEEN (TO_DATE(sysdate-2)) AND (TO_DATE(sysdate))  ;*/ (
    SELECT
      MAX(B.DATE_LIQ)
    FROM
      MERCURY.TBL_LIQUIDACIONRYT_DATE B
  )
ORDER BY
  2 ASC;

/

-- Contador USO NO VISA

SELECT
  COUNT(*)
FROM
  MERCURY.TBL_LIQUIDACIONRYT_USOS A
WHERE
  TRUNC(A.CLEARING_REG) = TRUNC(SYSDATE)
  AND TRUNC(A.CLEARING_DATE) = TRUNC(SYSDATE)
  AND A.TP_ID <> 999;

-- 290753

/

-- Contador USO VISA

SELECT
  *
FROM
  MERCURY.TBL_LIQUIDACIONRYT_USOS A
WHERE
  TRUNC(A.CLEARING_DATE) = TRUNC(SYSDATE)
 --- AND TRUNC(A.CLEARING_DATE) = TRUNC(SYSDATE)
  AND A.TP_ID = 999;

--  583
/

SELECT COUNT(*) 
    FROM MERCURY.TBL_TRX_UTRYTOPCS a
   WHERE trunc(a.fecha_ws) >= trunc(sysdate)
     AND trunc(a.ENTRY_DATE) = to_date(sysdate, 'dd-mm-yyyy')
     AND a.status = 'A'
     AND a.processed IN ('S', 'C')
--      AND a.response_date IS NULL;

--  1379

/

SELECT
  B.DIA,
  SUM(B.CANT)
FROM
  (
    SELECT
      TRUNC(A.PTD_REGDATE)                                   DIA,
      COUNT(TO_CHAR(A.PTD_REGDATE, 'DD/MM/YYYY HH24:MI:SS')) CANT
    FROM
      MERCURY.TBL_LIQUIDACIONRYT_REC A
    WHERE
      TRUNC(A.CLEARING_DATE) = TRUNC(SYSDATE)
      AND TRUNC(A.PTD_DAT_INC_PUENTE) >= TO_DATE('03-05-2023', 'DD-MM-YYYY')
      AND TRUNC(A.PTD_DAT_INC_PUENTE) <= TO_DATE('03-05-2023', 'DD-MM-YYYY')
      AND A.PP_CODE NOT IN (24, 29, 30, 34, 37)
      AND A.TP_ID IN (16, 44, 34)
 --      AND a.sta
    GROUP BY
      TRUNC(A.PTD_REGDATE) UNION
      SELECT --a.prv_master_id AS TP_ID,
        TRUNC(A.TR_TRANDATE)                                   FECHA,
        COUNT(TO_CHAR(A.TR_TRANDATE, 'DD/MM/YYYY'))            CANT
 --        SUM(a.TR_AMOUNT) MONTO
      FROM
        MERCURY.TBL_VENTAS_NETSALES    A
      WHERE
        A.TR_TRANDATE >= TO_DATE('03-05-2023', 'DD-MM-YYYY') --DIAS LIQUIDADOS
        AND A.TR_TRANDATE <= TO_DATE('03-05-2023', 'DD-MM-YYYY') --DIAS LIQUIDADOS
      GROUP BY --a.prv_master_id,
        TRUNC(A.TR_TRANDATE)
  )                              B
GROUP BY
  B.DIA;

-- Contador Recargas

SELECT
  SUM(B.CANT_RECARGAS)
FROM
  (
    SELECT
      TRUNC(A.PTD_REGDATE)                       FECHA,
      TO_CHAR(COUNT(A.QTRX), '999,999')          CANT_RECARGAS,
      TO_CHAR(SUM(A.PTD_AMOUNT), '$999,999,999') SUMA
    FROM
      MERCURY.TBL_LIQUIDACIONRYT_REC A
    WHERE
      TRUNC(A.CLEARING_DATE) = TRUNC(SYSDATE)
      AND TRUNC(A.PTD_DAT_INC_PUENTE) >= TO_DATE('15-06-2023', 'DD-MM-YYYY')
      AND TRUNC(A.PTD_DAT_INC_PUENTE) <= TO_DATE('15-06-2023', 'DD-MM-YYYY')
      AND A.PP_CODE NOT IN (24, 29, 30, 34, 37)
 --    AND a.tp_id in (16, 44, 34)
    GROUP BY
      TRUNC(A.PTD_REGDATE)
  ) B;

--193472

/

SELECT
  *
FROM
  (
    SELECT
      A.OPCS_ID,
      A.START_TIME,
      A.END_TIME        DAY_CONSULTED,
      A.TRX_QUANTITY,
      A.TRX_TRANSMITTED,
      A.TRX_FAILED,
      A.STATUS_CODE,
      B.DETAIL          DESCRIPCION
    FROM
      MERCURY.TBL_LOG_UTRYTOPCS        A,
      MERCURY.TBL_LOG_UTRYTOPCS_ERRORS B
    WHERE
      A.STATUS_CODE = B.ID
    ORDER BY
      OPCS_ID DESC
  )
WHERE
  ROWNUM = 1;