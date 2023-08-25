SELECT * FROM user_triggers ut WHERE ut.TRIGGER_NAME = 'TRG_TSN_UTRYTOPCS';
/
--------------------------CONCILIACION EKTEC VISA ------------------------------
SELECT p.usos,
       NVL(p.trx_f, 0) trx_f,
       NVL(p.trx_c, 0) trx_c,
       NVL(p.trx_r, 0) trx_r,
       NVL(p.trx_s, 0) trx_s,
       NVL(p.total, 0) total
  FROM (SELECT *
          FROM (SELECT TRUNC(ut.response_date) USOS,
                       COUNT(*) TRX_F,
                       'TRANSACCIONS FAIL' TIPO
                  FROM mercury.tbl_trx_utrytopcs ut
                 WHERE ut.processed = 'F'
                   AND TRUNC(ut.response_date) >=
                       TO_DATE('&DIA1', 'DD-MM-YYYY')
                   AND TRUNC(ut.response_date) <=
                       TO_DATE('&DIA2', 'DD-MM-YYYY')
                 GROUP BY TRUNC(ut.response_date)
                
                UNION
                
                SELECT TRUNC(ut.response_date) USOS,
                       COUNT(*) TRX_C,
                       'TRANSACCIONS COLEDED'
                  FROM mercury.tbl_trx_utrytopcs ut
                 WHERE ut.processed = 'C'
                   AND TRUNC(ut.response_date) >=
                       TO_DATE('&DIA1', 'DD-MM-YYYY')
                   AND TRUNC(ut.response_date) <=
                       TO_DATE('&DIA2', 'DD-MM-YYYY')
                 GROUP BY TRUNC(ut.response_date)
                
                UNION
                
                SELECT TRUNC(ut.response_date) USOS,
                       COUNT(*) TRX_R,
                       'TRANSACCIONS TURN OF' TIPO
                  FROM mercury.tbl_trx_utrytopcs ut
                 WHERE ut.processed = 'R'
                   AND TRUNC(ut.response_date) >=
                       TO_DATE('&DIA1', 'DD-MM-YYYY')
                   AND TRUNC(ut.response_date) <=
                       TO_DATE('&DIA2', 'DD-MM-YYYY')
                 GROUP BY TRUNC(ut.response_date)
                
                UNION
                
                SELECT TRUNC(ut.response_date) USOS,
                       COUNT(*) TOTAL,
                       'TOTAL' TIPO
                  FROM mercury.tbl_trx_utrytopcs ut
                 WHERE ut.processed IN ('S', 'C', 'R', 'F')
                   AND TRUNC(ut.response_date) >=
                       TO_DATE('&DIA1', 'DD-MM-YYYY')
                   AND TRUNC(ut.response_date) <=
                       TO_DATE('&DIA2', 'DD-MM-YYYY')
                 GROUP BY TRUNC(ut.response_date)
                
                UNION
                
                SELECT TRUNC(ut.response_date) USOS,
                       COUNT(*) TRX_R,
                       'TRANSACCIONS SUCCESS FUL' TIPO
                  FROM mercury.tbl_trx_utrytopcs ut
                 WHERE ut.processed = 'S'
                   AND TRUNC(ut.response_date) >=
                       TO_DATE('&DIA1', 'DD-MM-YYYY')
                   AND TRUNC(ut.response_date) <=
                       TO_DATE('&DIA2', 'DD-MM-YYYY')
                 GROUP BY TRUNC(ut.response_date)) T
        
        PIVOT(SUM(TRX_F)
           FOR TIPO IN('TRANSACCIONS FAIL' TRX_F,
                      'TRANSACCIONS COLEDED' TRX_C,
                      'TRANSACCIONS TURN OF' TRX_R,
                      'TRANSACCIONS SUCCESS FUL' TRX_S,
                      'TOTAL' TOTAL))
         ORDER BY 1) p;
