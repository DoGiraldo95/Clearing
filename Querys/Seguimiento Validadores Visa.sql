SELECT
  *
FROM
  (
    SELECT
      TRUNC(TU.DATE_CREATED) FECHA,
      COUNT(*)               USOS,
      'ESTACIONES'           TIPO
    FROM
      MERCURY.TBL_TRX_UTRYTOPCS TU
    WHERE
      TO_DATE(TU.FECHA_WS, 'dd-mm-yyyy') >= (
        SELECT
          TO_DATE(TRUNC(SYSDATE, 'month'), 'dd-mm-yyyy')
        FROM
          DUAL
      )
      AND TU.METROCALI = '0'
    GROUP BY
      TRUNC(TU.DATE_CREATED) UNION
      SELECT
        TRUNC(TU.DATE_CREATED),
        COUNT(*),
        'BUSES'
      FROM
        MERCURY.TBL_TRX_UTRYTOPCS TU
      WHERE
        TO_DATE(TU.FECHA_WS, 'dd-mm-yyyy') >= (
          SELECT
            TO_DATE(TRUNC(SYSDATE, 'month'), 'dd-mm-yyyy')
          FROM
            DUAL
        )
        AND TU.METROCALI <> '0'
      GROUP BY
        TRUNC(TU.DATE_CREATED)
  )                         V PIVOT(SUM(V.USOS) FOR TIPO IN('ESTACIONES' TRX_ESTACIONES,
  'BUSES' TRX_BUSES))
ORDER BY
  1;