--SELECT lq.app_id, lq.app_descshort, lq.cu_farevalue, COUNT(*) QTX FROM mercury.tbl_liquidacionryt_usos lq

UPDATE MERCURY.TBL_LIQUIDACIONRYT_USOS LQ
SET
    LQ.CLEARING_DATE = TO_DATE(
        '22-02-2222',
        'dd-mm-yyyy'
    )
 --SELECT * FROM mercury.tbl_liquidacionryt_usos lq
WHERE
    LQ.LD_ID = 215
    AND LQ.TP_ID = 45
    AND (LQ.CU_FAREVALUE > 0
    OR LQ.APP_ID IN (920, 902))
    AND LQ.CU_FAREVALUE = 2700
    AND TRUNC(LQ.CLEARING_REG) >= TO_DATE('&Fecha_1', 'dd-mm-yyyy')
    AND TRUNC(LQ.CLEARING_REG) <= TO_DATE('&Fecha_2', 'dd-mm-yyyy')
    AND LQ.CLEARING_DATE <> TO_DATE('22-02-2222', 'dd-mm-yyyy' ) GROUP BY LQ.APP_ID, LQ.APP_DESCSHORT, LQ.CU_FAREVALUE;

SELECT
    *
FROM
    MERCURY.LINEDETAILS LN
WHERE
    LN.LD_ID = 215;