SELECT *
  FROM (SELECT TO_CHAR(a.CU_DATETIME, 'dd Mont, YYYY') AS "Fecha Uso",
               COUNT(CU_DATETIME) AS "cantidad de usos",
               'USOS'
          FROM MERCURY.TBL_LIQUIDACIONRYT_USOS A
         WHERE a.APP_ID <> 999
           AND TO_CHAR(a.CU_DATETIME, 'dd-mm-yyyy') = '01-04-2023'
         GROUP BY TO_CHAR(a.CU_DATETIME, 'dd Mont, YYYY')
        HAVING COUNT(CU_DATETIME) > 0
         ORDER BY TO_CHAR(a.CU_DATETIME, 'dd Mont, YYYY')
        UNION
        SELECT TO_CHAR(a.CU_DATETIME, 'dd Mont, YYYY') AS "Fecha Usos Visa",
               COUNT(CU_DATETIME) AS "cantidad de usos", 
               "USOS VISA"
               
          FROM MERCURY.TBL_LIQUIDACIONRYT_USOS A
         WHERE a.APP_ID = 999
           AND TO_CHAR(a.CU_DATETIME, 'dd-mm-yyyy') = '01-04-2023'
         GROUP BY TO_CHAR(a.CU_DATETIME, 'dd Mont, YYYY')
        HAVING COUNT(CU_DATETIME) > 0
         ORDER BY TO_CHAR(a.CU_DATETIME, 'dd Mont, YYYY')) USOS
PIVOT(SUM("cantidad de usos")
