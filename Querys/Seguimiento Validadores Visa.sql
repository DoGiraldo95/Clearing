SELECT *
  FROM (SELECT TRUNC(UT.DATE_CREATED) fecha,
               COUNT(DISTINCT(UT.DEVICE_ID)) "CANT_ESTACION",
               /* COUNT(*) "CANT_USOS",*/
               'ESTACIONES' TIPO
          FROM TBL_TRX_UTRYTOPCS UT
         WHERE UT.FECHA_WS >=
               TO_DATE('02-10-2023 00:01', 'dd-mm-yyyy hh24:mi')
           AND UT.METROCALI = 0
         GROUP BY TRUNC(UT.DATE_CREATED)
        UNION
        SELECT TRUNC(UT.DATE_CREATED) fecha,
               COUNT(DISTINCT(UT.DEVICE_ID)) "CANT_ESTACION",
               /*COUNT(*) "CANT_USOS",*/
               'BUSES'
          FROM TBL_TRX_UTRYTOPCS UT
         WHERE UT.FECHA_WS >=
               TO_DATE('02-10-2023 00:01', 'dd-mm-yyyy hh24:mi')
           AND UT.METROCALI <> 0
         GROUP BY TRUNC(UT.DATE_CREATED)) t
PIVOT(SUM(t.cant_estacion)
   FOR TIPO IN('ESTACIONES', 'BUSES'))
 ORDER BY 1