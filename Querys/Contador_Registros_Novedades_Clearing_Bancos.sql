/*contador de registro novedades banco de bogota por archivo de registros */

SELECT trunc(a.nv_regdate) AS "Registro novedades Bogota",
       COUNT(*) QNV,
       a.file_origen
  FROM CPT_ANALISIS.TBL_NOVEDADES_BANBOGOTA a
 WHERE /* trunc(a.nv_regdate) between trunc(sysdate, 'month') and trunc(last_day(sysdate))*/
 trunc(a.nv_regdate) between trunc(sysdate, 'month') and last_day(sysdate)
 AND a.nv_prcdate = a.nv_ackdate HAVING COUNT(*) > 1
 GROUP BY trunc(a.nv_regdate), a.file_origen
 ORDER BY 1
          
          ---------------------------------------------------------------------------------------------------------------
          
          /*contador de registro novedades banco colombia por archivo de registros */
          
            SELECT trunc(a.nv_regdate) AS "Registro novedades Bancolombia",
                   COUNT(*) QNV,
                   a.file_origen
              FROM CPT_ANALISIS.TBL_NOVEDADES_BANCOLOMBIA a
             WHERE /* trunc(a.nv_regdate) between trunc(sysdate, 'month') and trunc(last_day(sysdate))*/
             trunc(a.nv_regdate) between trunc(sysdate, 'month') and
             last_day(sysdate)
         AND a.nv_prcdate = a.nv_ackdate HAVING COUNT(*) > 1
             GROUP BY trunc(a.nv_regdate), a.file_origen
             ORDER BY 3;


UPDATE CPT_ANALISIS.TBL_NOVEDADES_BANCOLOMBIA a
   SET a.nv_regdate = to_date('06-12-2023 ' ||
                              to_char(a.nv_regdate, 'hh24:mi:ss'),
                              'dd-mm-yyyy hh24:mi:ss')
 WHERE TRUNC(a.nv_regdate) = to_date('19-12-2023', 'dd-mm-yyyy')
   AND a.file_origen = 'NVC1520231206151028.txt'
   AND a.nv_prcdate = a.nv_ackdate;
