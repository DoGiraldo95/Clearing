-----------------------------------------------------------------
----------**********CONFIGURACION DE LA FECHA***********---------
-----------------------------------------------------------------
SELECT
  A.*,
  ROWID
FROM
  TBL_CALENDARIO_PROCESO A
WHERE
  A.FECHA_LIQ BETWEEN TO_DATE('15-07-2023', 'DD-MM-YYYY') AND TO_DATE('30-08-2023', 'DD-MM-YYYY')
ORDER BY
  2 ASC;

/

----------------------------------------------------------------------------
----------**********EJECUCION DEL PAQUETE DE VALOR A CONSIGNAR*******-------
----------------------------------------------------------------------------
BEGIN
  MERCURY.RT_PRC_VALOR_CONSIGNAR(TO_DATE('25-08-2023', 'DD-MM-YYYY')); --RECIBE COMO PARAMETRO LA FECHA DE LIQUIDACION(FECHA_LIQ)
END;
/

-------------------------------------------------------------
----------**********GENERACION DEL REPORTE*******------------
-------------------------------------------------------------
--CONSULTA EL VALOR A CONSIGNAR PARA ESTACIONES
SELECT --a.fecha_liq,
  A.FECHA_TRX,
  SUM(A.MONTO) VALOR
FROM
  MERCURY.TBL_VALOR_CONSIGNAR_MRC A
WHERE
  A.FECHA_LIQ >= TO_DATE('&Fecha_1', 'DD-MM-YYYY')
  AND A.FECHA_LIQ <= TO_DATE('&Fecha_2', 'DD-MM-YYYY') -- RECIBE COMO PARAMETRO LA FECHA DE PROCESO(FECHA_LIQ)
  AND A.TP_ID IN (16, 44)
GROUP BY --a.fecha_liq
  A.FECHA_TRX
ORDER BY
  1 ASC;

/

-------------------------------------------------------------
-----------*********REPARTICION POR CONCEPTO POR MESES **********------------
-------------------------------------------------------------

SELECT
  P.FECHA_LIQ,
  '$'
  || TO_CHAR(P.MONTO_ESTACION, '999999999999')           MONTO_ESTACION,
  '$'
  || TO_CHAR(P.MONTO_MIO_CABLE, '999999999999')          MONTO_MIO_CABLE,
  '$'
  || TO_CHAR(P.TOTAL, '999999999999')                    TOTAL,
  '$'
  || TO_CHAR(P.TOTAL - P.MONTO_ESTACION, '999999999999') DIFERENCIA
FROM
  (
    SELECT
      *
    FROM
      (
        SELECT
          A.FECHA_LIQ,
          SUM(A.MONTO)                MONTO_ESTACION,
          'ESTACION'                  AS TIPO
        FROM
          MERCURY.TBL_VALOR_CONSIGNAR_MRC A
        WHERE
          A.TP_ID = 16
          AND A.FECHA_LIQ >= TO_DATE('&Fecha_Inicial', 'DD-MM-YYYY')
          AND A.FECHA_LIQ <= TO_DATE('&Fecha_Final', 'DD-MM-YYYY')
        GROUP BY
          A.FECHA_LIQ UNION
          SELECT
            A.FECHA_LIQ,
            SUM(A.MONTO)                MONTO_MIO_CABLE,
            'MIO CABLE'                 AS TIPO
          FROM
            MERCURY.TBL_VALOR_CONSIGNAR_MRC A
          WHERE
            A.TP_ID = 44
            AND A.FECHA_LIQ >= TO_DATE('&Fecha_Inicial', 'DD-MM-YYYY')
            AND A.FECHA_LIQ <= TO_DATE('&Fecha_Final', 'DD-MM-YYYY')
          GROUP BY
            A.FECHA_LIQ UNION
            SELECT
              A.FECHA_LIQ,
              SUM(A.MONTO)                MONTO_MIO_CABLE,
              'TOTAL MIOCABLE + ESTACION' AS TIPO
            FROM
              MERCURY.TBL_VALOR_CONSIGNAR_MRC A
            WHERE
              A.TP_ID IN (44, 16)
              AND A.FECHA_LIQ >= TO_DATE('&Fecha_Inicial', 'DD-MM-YYYY')
              AND A.FECHA_LIQ <= TO_DATE('&Fecha_Final', 'DD-MM-YYYY')
            GROUP BY
              A.FECHA_LIQ
      )                               T PIVOT(SUM(MONTO_ESTACION) FOR TIPO IN('ESTACION' MONTO_ESTACION,
      'MIO CABLE' MONTO_MIO_CABLE,
      'TOTAL MIOCABLE + ESTACION' TOTAL))
  )                               P
ORDER BY
  1;

/

-------------------------------------------------------------
-----------*********REPARTICION POR CONCEPTO POR DIA **********------------
-------------------------------------------------------------

SELECT
  D.FECHA_LIQUIDACION,
  '$'
  || TO_CHAR(D.MONTO_ESTACION, '999999999999') MONTO_ESTACION,
  '$'
  || TO_CHAR(D.MONTO_MIO_CABLE, '999999999999') MONTO_MIO_CABLE,
  '$'
  || TO_CHAR(D.TOTAL, '999999999999')           TOTAL_ESTACION_MIOCABLE
FROM
  (
    SELECT
      C.FECHA_LIQ FECHA_LIQUIDACION,
      (
        SELECT
          SUM(A.MONTO)
        FROM
          MERCURY.TBL_VALOR_CONSIGNAR_MRC A
        WHERE
          A.TP_ID = 16
          AND A.FECHA_LIQ >= TO_DATE('&Fecha_Inicial', 'DD-MM-YYYY')
          AND A.FECHA_LIQ <= TO_DATE('&Fecha_Final', 'DD-MM-YYYY')
      ) AS MONTO_ESTACION,
      (
        SELECT
          SUM(B.MONTO)
        FROM
          MERCURY.TBL_VALOR_CONSIGNAR_MRC B
        WHERE
          B.TP_ID = 44
          AND B.FECHA_LIQ >= TO_DATE('&Fecha_Inicial', 'DD-MM-YYYY')
          AND B.FECHA_LIQ <= TO_DATE('&Fecha_Final', 'DD-MM-YYYY')
      ) AS MONTO_MIO_CABLE,
      (
        SELECT
          SUM(C.MONTO)
        FROM
          MERCURY.TBL_VALOR_CONSIGNAR_MRC C
        WHERE
          C.TP_ID IN (16, 44)
          AND C.FECHA_LIQ >= TO_DATE('&Fecha_Inicial', 'DD-MM-YYYY')
          AND C.FECHA_LIQ <= TO_DATE('&Fecha_Final', 'DD-MM-YYYY')
      ) AS TOTAL
    FROM
      MERCURY.TBL_VALOR_CONSIGNAR_MRC C
    WHERE
      C.FECHA_LIQ >= TO_DATE('&Fecha_Inicial', 'DD-MM-YYYY')
      AND C.FECHA_LIQ <= TO_DATE('&Fecha_Final', 'DD-MM-YYYY')
    GROUP BY
      C.FECHA_LIQ
  ) D
GROUP BY
  D.MONTO_ESTACION,
  D.MONTO_MIO_CABLE,
  D.TOTAL,
  D.FECHA_LIQUIDACION;

/

-------------------------------------------------------------
-----------*********CONSULTA DE CONTROL**********------------
-------------------------------------------------------------
SELECT
  A.TP_ID                                                TP_ID,
  TRUNC(B.PTD_REGDATE)                                   FECHA,
  COUNT(TO_CHAR(B.PTD_REGDATE, 'DD/MM/YYYY HH24:MI:SS')) CANT, -- FECHA,
  SUM(B.PTD_AMOUNT*1000)                                 MONTO
FROM
  MERCURY.POS_TRANMT          A,
  MERCURY.POS_TRANDT          B,
  MERCURY.POS_DEVICE          C,
  MERCURY.POS_PRODUCTS        D
WHERE
  A.PTM_TRANNBR = B.PTM_TRANNBR
  AND A.PD_CODE = B.PD_CODE
  AND B.PTD_STATUS = 'A'
  AND B.PTD_REGDATE >= TO_DATE('&Fecha_Inicial 00:01', 'DD-MM-YYYY HH24:MI') -- TRX - liquidacion
  AND B.PTD_REGDATE <= TO_DATE('&Fecha_Final 23:59', 'DD-MM-YYYY HH24:MI') --TRX- liquidacion
  AND B.PD_CODE = C.PD_CODE
  AND B.PP_CODE = D.PP_CODE
  AND (B.PP_CODE IN (24, 29, 30, 22, 34, 37)
  OR B.PTD_CONF_DATE IS NOT NULL) --*** CON Venta de Tarjetas
 --and (b.pp_code in (22) or  b.ptd_conf_date is not null) --*** Solamente Recargas
  AND B.PTM_TRANNBR = A.PTM_TRANNBR
  AND B.PD_CODE = A.PD_CODE
  AND A.PTM_STATUS = 'Z'
  AND A.TP_ID IN (16, 44)
GROUP BY
  A.TP_ID, TRUNC(B.PTD_REGDATE) UNION
  SELECT
    A.PRV_MASTER_ID                                        AS TP_ID,
    TRUNC(A.TR_TRANDATE)                                   FECHA,
    COUNT(TO_CHAR(A.TR_TRANDATE, 'DD/MM/YYYY HH24:MI:SS')) CANT,
    SUM(A.TR_AMOUNT)                                       MONTO
  FROM
    MERCURY.TBL_VENTAS_NETSALES A
  WHERE
    A.TR_TRANDATE >= TO_DATE('&Fecha_Inicial 00:01', 'DD-MM-YYYY HH24:MI') --*********  FECHA
    AND A.TR_TRANDATE <= TO_DATE('&Fecha_Final 23:59', 'DD-MM-YYYY HH24:MI') -- liquidacion
    AND A.PRV_MASTER_ID = 745 --Puntos Externos
  GROUP BY
    TRUNC(A.TR_TRANDATE), A.PRV_MASTER_ID
  ORDER BY
    1 ASC;

-------
SELECT
  ROWID,
  A.*
FROM
  MERCURY.TBL_VALOR_CONSIGNAR_MRC A
WHERE
  A.TP_ID = 44
 --and fecha_liq < to_date ('01/01/2023','dd/mm/yyyy')
 --and a.comentarios is null
ORDER BY
  A.REGDATE;

/

SELECT --a.fecha_liq,
  A.FECHA_TRX,
  SUM(A.MONTO) VALOR
FROM
  MERCURY.TBL_VALOR_CONSIGNAR_MRC A
WHERE
  A.FECHA_LIQ >= TO_DATE('10-12-2022', 'DD-MM-YYYY') -- RECIBE COMO PARAMETRO LA FECHA DE LIQUIDACION
  AND A.FECHA_LIQ <= TO_DATE('14-12-2022', 'DD-MM-YYYY')
  AND A.TP_ID IN (44)
GROUP BY --a.fecha_liq
  A.FECHA_TRX
ORDER BY
  1 ASC