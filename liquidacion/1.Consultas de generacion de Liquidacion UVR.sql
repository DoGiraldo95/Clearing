-- QUERY 1, ASIGNAR FECHA AL CALENDARIO DE LIQUIDACION
SELECT
    ROWID,
    A.*
FROM
    MERCURY.TBL_LIQUIDACIONRYT_DATE A
WHERE
    A.DATE_LIQ BETWEEN TRUNC(SYSDATE, 'MONTH') AND LAST_DAY(SYSDATE)
ORDER BY
    2 DESC;

/

--- QUERY 2, EJECUTAR PAQUETE DE LIQUIDACION USOS
BEGIN
    MERCURY.LIQUIDACIONRT_PKG.LIQUIDACIONRYT_USOS(TO_DATE('05-04-2024', 'DD-MM-YYYY')); --DIA ACTUAL
END;
/

--- QUERY 2.1, EJECUTAR PAQUETE DE LIQUIDACION USOS VISA
BEGIN
    MERCURY.LIQUIDACIONRT_PKG.LIQUIDACIONRYT_USOS_VISA(TO_DATE('05-04-2024', 'DD-MM-YYYY')); --DIA ACTUAL
END;
/
--- QUERY 2.2, EJECUTAR PAQUETE DE LIQUIDACION USOS MIFARE
BEGIN 
     MERCURY.LIQUIDACIONRT_PKG.LIQUIDACIONRYT_USOS_SW_MIFARE(TO_DATE('05-04-2024', 'DD-MM-YYYY')); --DIA ACTUAL
END;
/
-- QUERY 3, EJECUTAR PAQUETE DE LIQUIDACION RECARGAS Y VENTAS
BEGIN
    MERCURY.LIQUIDACIONRT_PKG.LIQUIDACION_REC(TO_DATE('05-04-2024', 'DD-MM-YYYY')); --DIA ACTUAL
END;

/


--*************************************************************************************
--*****************  REPORTE LIQUIDACION USOS POR TARIFA 2024******************************* DIA ACTUAL

SELECT
    FECHA_TRX,
    SUM(Q_USOS_2200)                                CANTIDAD_USOS_2200,
    '$'
    || TO_CHAR(SUM(M_USOS_2200), '9999999999')      MONTO_USOS_2200,
    SUM(Q_USOS_2400)                                CANTIDAD_USOS_2400,
    '$'
    || TO_CHAR(SUM(M_USOS_2400), '9999999999')      MONTO_USOS_2400,
    SUM(Q_USOS_2700)                                CANTIDAD_USOS_2700,
    '$'
    || TO_CHAR(SUM(M_USOS_2700), '9999999999')      MONTO_USOS_2700,
    SUM(Q_USOS_2900)                                CANTIDAD_USOS_2900,
    '$'
    || TO_CHAR(SUM(M_USOS_2900), '9999999999')      MONTO_USOS_2900,
    SUM(Q_RECARGAS)                                 CANTIDAD_RECARGA,
    '$'
    || TO_CHAR(SUM(M_RECARGAS), '9999999999')       MONTO_RECARGAS,
    SUM(Q_MEDIOS_DE_PAGO)                           CANTIDAD_MEDIOS_DE_PAGO,
    '$'
    || TO_CHAR(SUM(M_MEDIOS_DE_PAGO), '9999999999') MONTO_MEDIOS_DE_PAGO
FROM
    (
        SELECT
            FECHA_TRX,
            SUM(USOS_2200)      Q_USOS_2200,
            SUM(USOS_2400)      Q_USOS_2400,
            SUM(USOS_2700)      Q_USOS_2700,
            SUM(USOS_2900)      Q_USOS_2900,
            SUM(RECARGAS)       Q_RECARGAS,
            SUM(MEDIOS_DE_PAGO) Q_MEDIOS_DE_PAGO,
            0 M_USOS_2200,
            0 M_USOS_2400,
            0 M_USOS_2700,
            0 M_USOS_2900,
            0 M_RECARGAS,
            0 M_MEDIOS_DE_PAGO
        FROM
            (
 --USOS 2200
                SELECT
                    *
                FROM
                    (
                        SELECT
                            A.CLEARING_DATE              AS FECHA_LIQUIDACION,
                            TRUNC(A.CU_DATETIME)         FECHA_TRX,
                            SUM(A.QPAX)                  CANTIDAD_TRX,
                            SUM(A.CU_FAREVALUE)          MONTO_TRX,
                            'FONDO GENERAL DE USOS 2200' TIPO
                        FROM
                            MERCURY.TBL_LIQUIDACIONRYT_USOS A
                        WHERE
                            A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                            AND (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                            AND (A.TP_ID NOT IN (44, 999)
                            OR (A.TP_ID = 999
                            AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                            AND A.CU_FAREVALUE = 2200
                        GROUP BY
                            A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
 --USOS 2400
                            SELECT
                                *
                            FROM
                                (
                                    SELECT
                                        A.CLEARING_DATE              AS FECHA_LIQUIDACION,
                                        TRUNC(A.CU_DATETIME)         FECHA_TRX,
                                        SUM(A.QPAX)                  CANTIDAD_TRX,
                                        SUM(A.CU_FAREVALUE)          MONTO_TRX,
                                        'FONDO GENERAL DE USOS 2400' TIPO
                                    FROM
                                        MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                    WHERE
                                        A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                        AND  (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                                        AND (A.TP_ID NOT IN (44, 999)
                                        OR (A.TP_ID = 999
                                        AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                        AND A.CU_FAREVALUE = 2400
                                    GROUP BY
                                        A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
  --USOS 2700                                   
                                     SELECT
                                            *
                                        FROM
                                            (
                                                SELECT
                                                    A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                                    TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                                    SUM(A.QPAX)                          CANTIDAD_TRX,
                                                    SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                                    'FONDO GENERAL DE USOS 2700'         TIPO
                                                FROM
                                                    MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                                WHERE
                                                    A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                                    AND  (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                                                    AND (A.TP_ID NOT IN (44, 999)
                                                    OR (A.TP_ID = 999
                                                    AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                                    AND A.CU_FAREVALUE = 2700
                                                GROUP BY
                                                    A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
 --USOS 2900
                                        SELECT
                                            *
                                        FROM
                                            (
                                                SELECT
                                                    A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                                    TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                                    SUM(A.QPAX)                          CANTIDAD_TRX,
                                                    SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                                    'FONDO GENERAL DE USOS 2900'         TIPO
                                                FROM
                                                    MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                                WHERE
                                                    A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                                    AND  (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                                                    AND (A.TP_ID NOT IN (44, 999)
                                                    OR (A.TP_ID = 999
                                                    AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                                    AND A.CU_FAREVALUE = 2900
                                                GROUP BY
                                                    A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                                    SELECT
                                                        A.CLEARING_DATE,
                                                        TRUNC(A.PTD_REGDATE),
                                                        SUM(A.QTRX),
                                                        SUM(A.PTD_AMOUNT),
                                                        'FONDO DE RECARGAS'
                                                    FROM
                                                        MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                                    WHERE
                                                        A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                                        AND A.PP_CODE NOT IN (24, 29, 30, 34, 37)
                                                    GROUP BY
                                                        A.CLEARING_DATE, TRUNC(A.PTD_REGDATE) UNION
                                                        SELECT
                                                            A.CLEARING_DATE,
                                                            TRUNC(A.PTD_REGDATE),
                                                            SUM(A.QTRX),
                                                            SUM(A.PTD_AMOUNT),
                                                            'FONDO SOSTENIMIENTO MEDIO DE PAGOS'
                                                        FROM
                                                            MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                                        WHERE
                                                            A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                                            AND A.PP_CODE IN (24, 29, 30, 34, 37)
                                                        GROUP BY
                                                            A.CLEARING_DATE, TRUNC(A.PTD_REGDATE)
                                                            )
                                            )                               
                                )                               
                    )                               T PIVOT(SUM(CANTIDAD_TRX) FOR TIPO IN('FONDO GENERAL DE USOS 2200' AS USOS_2200,
                    'FONDO GENERAL DE USOS 2400' AS USOS_2400,
                    'FONDO GENERAL DE USOS 2700' AS USOS_2700,
                    'FONDO GENERAL DE USOS 2900' AS USOS_2900,
                    'FONDO SOSTENIMIENTO MEDIO DE PAGOS' AS MEDIOS_DE_PAGO,
                    'FONDO DE RECARGAS' AS RECARGAS))
            )                               
        GROUP BY
            FECHA_TRX --,USOS,RECARGAS,MEDIOS_DE_PAGO
            UNION
            SELECT
                FECHA_TRX,
                0,
                0,
                0,
                0,
                0,
                0,
                SUM(USOS_2200)      M_USOS_2200,
                SUM(USOS_2400)      M_USOS_2400,
                SUM(USOS_2700)      M_USOS_2700,
                SUM(USOS_2900)      M_USOS_2900,
                SUM(RECARGAS)       M_RECARGAS,
                SUM(MEDIOS_DE_PAGO) M_MEDIOS_DE_PAGO
            FROM
                (
                    SELECT
                        *
                    FROM
                        (
                            SELECT
                                A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                SUM(A.QPAX)                          CANTIDAD_TRX,
                                SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                'FONDO GENERAL DE USOS 2200'         TIPO
                            FROM
                                MERCURY.TBL_LIQUIDACIONRYT_USOS A
                            WHERE
                                A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                AND  (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                                AND (A.TP_ID NOT IN (44, 999)
                                OR (A.TP_ID = 999
                                AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                AND A.CU_FAREVALUE = 2200
                            GROUP BY
                                A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                SELECT
                                    A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                    TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                    SUM(A.QPAX)                          CANTIDAD_TRX,
                                    SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                    'FONDO GENERAL DE USOS 2400'         TIPO
                                FROM
                                    MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                WHERE
                                    A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                    AND  (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                                    AND (A.TP_ID NOT IN (44, 999)
                                    OR (A.TP_ID = 999
                                    AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                    AND A.CU_FAREVALUE = 2400
                                GROUP BY
                                    A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                    SELECT
                                        A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                        TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                        SUM(A.QPAX)                          CANTIDAD_TRX,
                                        SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                        'FONDO GENERAL DE USOS 2700'         TIPO
                                    FROM
                                        MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                    WHERE
                                        A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                        AND  (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                                        AND (A.TP_ID NOT IN (44, 999)
                                        OR (A.TP_ID = 999
                                        AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                        AND A.CU_FAREVALUE = 2700
                                    GROUP BY
                                        A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                        SELECT
                                        A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                        TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                        SUM(A.QPAX)                          CANTIDAD_TRX,
                                        SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                        'FONDO GENERAL DE USOS 2900'         TIPO
                                    FROM
                                        MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                    WHERE
                                        A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                        AND  (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                                        AND (A.TP_ID NOT IN (44, 999)
                                        OR (A.TP_ID = 999
                                        AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                        AND A.CU_FAREVALUE = 2900
                                    GROUP BY
                                        A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                        SELECT
                                            A.CLEARING_DATE,
                                            TRUNC(A.PTD_REGDATE),
                                            SUM(A.QTRX),
                                            SUM(A.PTD_AMOUNT),
                                            'FONDO DE RECARGAS'
                                        FROM
                                            MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                        WHERE
                                            A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                            AND A.PP_CODE NOT IN (24, 29, 30, 34, 37)
                                        GROUP BY
                                            A.CLEARING_DATE, TRUNC(A.PTD_REGDATE) UNION
                                            SELECT
                                                A.CLEARING_DATE,
                                                TRUNC(A.PTD_REGDATE),
                                                SUM(A.QTRX),
                                                SUM(A.PTD_AMOUNT),
                                                'FONDO SOSTENIMIENTO MEDIO DE PAGOS'
                                            FROM
                                                MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                            WHERE
                                                A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                                AND A.PP_CODE IN (24, 29, 30, 34, 37)
                                            GROUP BY
                                                A.CLEARING_DATE, TRUNC(A.PTD_REGDATE)
                        )                               T PIVOT(SUM(MONTO_TRX) FOR TIPO IN('FONDO GENERAL DE USOS 2200' AS USOS_2200,
                        'FONDO GENERAL DE USOS 2400' AS USOS_2400,
                        'FONDO GENERAL DE USOS 2700' AS USOS_2700,
                        'FONDO GENERAL DE USOS 2900' AS USOS_2900,
                        'FONDO SOSTENIMIENTO MEDIO DE PAGOS' AS MEDIOS_DE_PAGO,
                        'FONDO DE RECARGAS' AS RECARGAS))
                )                               
            GROUP BY
                FECHA_TRX --,USOS,RECARGAS,MEDIOS_DE_PAGO
    )                               
GROUP BY
    FECHA_TRX
ORDER BY
    1 ASC;

/

--*************************************************************************************
--*******************  REPORTE LIQUIDACION USOS CONSOLIDADO*************************************** DIA ACTUAL


SELECT
    FECHA_TRX,
    SUM(Q_USOS)                                    CANTIDAD_USOS,
    '$'
    ||TO_CHAR(SUM(M_USOS), '9999999999')MONTO_USOS           ,
    SUM(Q_RECARGAS)                                CANTIDAD_RECARGA,
    '$'
    ||TO_CHAR(SUM(M_RECARGAS), '9999999999')       MONTO_RECARGAS,
    SUM(Q_MEDIOS_DE_PAGO)                          CANTIDAD_MEDIOS_DE_PAGO,
    '$'
    ||TO_CHAR(SUM(M_MEDIOS_DE_PAGO), '9999999999') MONTO_MEDIOS_DE_PAGO
FROM
    (
        SELECT
            FECHA_TRX,
            SUM(USOS)           Q_USOS,
            SUM(RECARGAS)       Q_RECARGAS,
            SUM(MEDIOS_DE_PAGO) Q_MEDIOS_DE_PAGO,
            0 M_USOS,
            0 M_RECARGAS,
            0 M_MEDIOS_DE_PAGO
        FROM
            (
                SELECT
                    *
                FROM
                    (
                        SELECT
                            A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                            TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                            SUM(A.QPAX)                          CANTIDAD_TRX,
                            SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                            'FONDO GENERAL DE USOS'              TIPO
                        FROM
                            MERCURY.TBL_LIQUIDACIONRYT_USOS A
                        WHERE
                            A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                          AND (A.CU_ITG_CTR IS NULL OR A.Cu_Itg_Ctr =0)
                            AND (A.TP_ID NOT IN (44, 999)
                            OR (A.TP_ID = 999
                            AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                        GROUP BY
                            A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                            SELECT
                                A.CLEARING_DATE,
                                TRUNC(A.PTD_REGDATE),
                                SUM(A.QTRX),
                                SUM(A.PTD_AMOUNT),
                                'FONDO DE RECARGAS'
                            FROM
                                MERCURY.TBL_LIQUIDACIONRYT_REC  A
                            WHERE
                                A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                AND A.PP_CODE NOT IN (24, 29, 30, 34, 37)
                            GROUP BY
                                A.CLEARING_DATE, TRUNC(A.PTD_REGDATE) UNION
                                SELECT
                                    A.CLEARING_DATE,
                                    TRUNC(A.PTD_REGDATE),
                                    SUM(A.QTRX),
                                    SUM(A.PTD_AMOUNT),
                                    'FONDO SOSTENIMIENTO MEDIO DE PAGOS'
                                FROM
                                    MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                WHERE
                                    A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                    AND A.PP_CODE IN (24, 29, 30, 34, 37)
                                GROUP BY
                                    A.CLEARING_DATE, TRUNC(A.PTD_REGDATE)
                    )                               T PIVOT(SUM(CANTIDAD_TRX) FOR TIPO IN('FONDO GENERAL DE USOS' AS USOS,
                    'FONDO SOSTENIMIENTO MEDIO DE PAGOS' AS MEDIOS_DE_PAGO,
                    'FONDO DE RECARGAS' AS RECARGAS))
            )                               
        GROUP BY
            FECHA_TRX --,USOS,RECARGAS,MEDIOS_DE_PAGO
            UNION
            SELECT
                FECHA_TRX,
                0,
                0,
                0,
                SUM(USOS)           M_USOS,
                SUM(RECARGAS)       M_RECARGAS,
                SUM(MEDIOS_DE_PAGO) M_MEDIOS_DE_PAGO
            FROM
                (
                    SELECT
                        *
                    FROM
                        (
                            SELECT
                                A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                SUM(A.QPAX)                          CANTIDAD_TRX,
                                SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                'FONDO GENERAL DE USOS'              TIPO
                            FROM
                                MERCURY.TBL_LIQUIDACIONRYT_USOS A
                            WHERE
                                A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                AND (A.CU_ITG_CTR IS NULL OR A.Cu_Itg_Ctr =0)
                                AND (A.TP_ID NOT IN (44, 999)
                                OR (A.TP_ID = 999
                                AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                            GROUP BY
                                A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                SELECT
                                    A.CLEARING_DATE,
                                    TRUNC(A.PTD_REGDATE),
                                    SUM(A.QTRX),
                                    SUM(A.PTD_AMOUNT),
                                    'FONDO DE RECARGAS'
                                FROM
                                    MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                WHERE
                                    A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                    AND A.PP_CODE NOT IN (24, 29, 30, 34, 37)
                                GROUP BY
                                    A.CLEARING_DATE, TRUNC(A.PTD_REGDATE) UNION
                                    SELECT
                                        A.CLEARING_DATE,
                                        TRUNC(A.PTD_REGDATE),
                                        SUM(A.QTRX),
                                        SUM(A.PTD_AMOUNT),
                                        'FONDO SOSTENIMIENTO MEDIO DE PAGOS'
                                    FROM
                                        MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                    WHERE
                                        A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                        AND A.PP_CODE IN (24, 29, 30, 34, 37)
                                    GROUP BY
                                        A.CLEARING_DATE, TRUNC(A.PTD_REGDATE)
                        )                               T PIVOT(SUM(MONTO_TRX) FOR TIPO IN('FONDO GENERAL DE USOS' AS USOS,
                        'FONDO SOSTENIMIENTO MEDIO DE PAGOS' AS MEDIOS_DE_PAGO,
                        'FONDO DE RECARGAS' AS RECARGAS))
                )                               
            GROUP BY
                FECHA_TRX --,USOS,RECARGAS,MEDIOS_DE_PAGO
    )
GROUP BY
    FECHA_TRX
ORDER BY
    1 ASC;

/

--*************************************************************************************
--*******************  REPORTE LIQUIDACION USOS VISA*********************************** DIA ACTUAL

SELECT
    TRUNC(A.CU_DATETIME)    FECHA_TRX,
    SUM(A.QPAX)             CANTIDAD_TRX,
    SUM(A.CU_FAREVALUE)     MONTO_TRX,
    A.CU_FAREVALUE          TARIFA,
    A.CLEARING_DATE         AS FECHA_LIQUIDACION,
    'FONDO GENERAL DE VISA' TIPO
FROM
    MERCURY.TBL_LIQUIDACIONRYT_USOS A
WHERE
    A.CLEARING_DATE >= TO_DATE('&DIA', 'DD-MM-YYYY')
    AND A.CU_ITG_CTR IS NULL
    AND A.TP_ID IN (999) -- SOLO VISA
    AND A.LD_ID NOT IN (215) -- NO INCLUYE INTEGRACIONES MIO CABLE CA�AVERALEJO
    AND A.CU_FAREVALUE > 0
GROUP BY
    A.CLEARING_DATE, TRUNC(A.CU_DATETIME), A.CU_FAREVALUE
ORDER BY
    1 ASC;

/

--*************************************************************************************
--*****************  REPORTE LIQUIDACION USOS POR TARIFA 2022******************************* DIA ACTUAL
SELECT
    FECHA_TRX,
    SUM(Q_USOS_2200)                                CANTIDAD_USOS_2200,
    TO_CHAR(SUM(M_USOS_2200), 'FML9999999999')      MONTO_USOS_2200,
    SUM(Q_USOS_2400)                                CANTIDAD_USOS_2400,
    TO_CHAR(SUM(M_USOS_2400), 'FML9999999999')      MONTO_USOS_2400,
    SUM(Q_RECARGAS)                                 CANTIDAD_RECARGA,
    TO_CHAR(SUM(M_RECARGAS), 'FML9999999999')       MONTO_RECARGAS,
    SUM(Q_MEDIOS_DE_PAGO)                           CANTIDAD_MEDIOS_DE_PAGO,
    TO_CHAR(SUM(M_MEDIOS_DE_PAGO), 'FML9999999999') MONTO_MEDIOS_DE_PAGO
FROM
    (
        SELECT
            FECHA_TRX,
            SUM(USOS_2200)      Q_USOS_2200,
            SUM(USOS_2400)      Q_USOS_2400,
            SUM(RECARGAS)       Q_RECARGAS,
            SUM(MEDIOS_DE_PAGO) Q_MEDIOS_DE_PAGO,
            0 M_USOS_2200,
            0 M_USOS_2400,
            0 M_RECARGAS,
            0 M_MEDIOS_DE_PAGO
        FROM
            (
                SELECT
                    *
                FROM
                    (
                        SELECT
                            A.CLEARING_DATE              AS FECHA_LIQUIDACION,
                            TRUNC(A.CU_DATETIME)         FECHA_TRX,
                            SUM(A.QPAX)                  CANTIDAD_TRX,
                            SUM(A.CU_FAREVALUE)          MONTO_TRX,
                            'FONDO GENERAL DE USOS 2200' TIPO
                        FROM
                            MERCURY.TBL_LIQUIDACIONRYT_USOS A
                        WHERE
                            A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                            AND A.CU_ITG_CTR IS NULL
                            AND (A.TP_ID NOT IN (44, 999)
                            OR (A.TP_ID = 999
                            AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                            AND A.CU_FAREVALUE = 2200
                            AND A.LD_ID NOT IN (215)
                        GROUP BY
                            A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                            SELECT
                                *
                            FROM
                                (
                                    SELECT
                                        A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                        TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                        SUM(A.QPAX)                          CANTIDAD_TRX,
                                        SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                        'FONDO GENERAL DE USOS 2400'         TIPO
                                    FROM
                                        MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                    WHERE
                                        A.CLEARING_DATE >= TO_DATE('&DIA', 'DD-MM-YYYY')
                                        AND A.CU_ITG_CTR IS NULL
                                        AND (A.TP_ID NOT IN (44, 999)
                                        OR (A.TP_ID = 999
                                        AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                        AND A.CU_FAREVALUE = 2400
                                        AND A.LD_ID NOT IN (215)
                                    GROUP BY
                                        A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                        SELECT
                                            A.CLEARING_DATE,
                                            TRUNC(A.PTD_REGDATE),
                                            SUM(A.QTRX),
                                            SUM(A.PTD_AMOUNT),
                                            'FONDO DE RECARGAS'
                                        FROM
                                            MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                        WHERE
                                            A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                            AND A.PP_CODE NOT IN (24, 29, 30, 34, 37)
                                        GROUP BY
                                            A.CLEARING_DATE, TRUNC(A.PTD_REGDATE) UNION
                                            SELECT
                                                A.CLEARING_DATE,
                                                TRUNC(A.PTD_REGDATE),
                                                SUM(A.QTRX),
                                                SUM(A.PTD_AMOUNT),
                                                'FONDO SOSTENIMIENTO MEDIO DE PAGOS'
                                            FROM
                                                MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                            WHERE
                                                A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                                AND A.PP_CODE IN (24, 29, 30, 34, 37)
                                            GROUP BY
                                                A.CLEARING_DATE, TRUNC(A.PTD_REGDATE)
                                )                               
                    )                               T PIVOT(SUM(CANTIDAD_TRX) FOR TIPO IN('FONDO GENERAL DE USOS 2200' AS USOS_2200,
                    'FONDO GENERAL DE USOS 2400' AS USOS_2400,
                    'FONDO SOSTENIMIENTO MEDIO DE PAGOS' AS MEDIOS_DE_PAGO,
                    'FONDO DE RECARGAS' AS RECARGAS))
            )                               
        GROUP BY
            FECHA_TRX --,USOS,RECARGAS,MEDIOS_DE_PAGO
            UNION
            SELECT
                FECHA_TRX,
                0,
                0,
                0,
                0,
                SUM(USOS_2200)      M_USOS_2200,
                SUM(USOS_2400)      M_USOS_2400,
                SUM(RECARGAS)       M_RECARGAS,
                SUM(MEDIOS_DE_PAGO) M_MEDIOS_DE_PAGO
            FROM
                (
                    SELECT
                        *
                    FROM
                        (
                            SELECT
                                A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                SUM(A.QPAX)                          CANTIDAD_TRX,
                                SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                'FONDO GENERAL DE USOS 2200'         TIPO
                            FROM
                                MERCURY.TBL_LIQUIDACIONRYT_USOS A
                            WHERE
                                A.CLEARING_DATE >= TO_DATE('&DIA', 'DD-MM-YYYY')
                                AND A.CU_ITG_CTR IS NULL
                                AND (A.TP_ID NOT IN (44, 999)
                                OR (A.TP_ID = 999
                                AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                AND A.CU_FAREVALUE = 2200
                                AND A.LD_ID NOT IN (215)
                            GROUP BY
                                A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                SELECT
                                    A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                    TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                    SUM(A.QPAX)                          CANTIDAD_TRX,
                                    SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                    'FONDO GENERAL DE USOS 2400'         TIPO
                                FROM
                                    MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                WHERE
                                    A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                    AND A.CU_ITG_CTR IS NULL
                                    AND (A.TP_ID NOT IN (44, 999)
                                    OR (A.TP_ID = 999
                                    AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                    AND A.CU_FAREVALUE = 2400
                                    AND A.LD_ID NOT IN (215)
                                GROUP BY
                                    A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                    SELECT
                                        A.CLEARING_DATE,
                                        TRUNC(A.PTD_REGDATE),
                                        SUM(A.QTRX),
                                        SUM(A.PTD_AMOUNT),
                                        'FONDO DE RECARGAS'
                                    FROM
                                        MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                    WHERE
                                        A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                        AND A.PP_CODE NOT IN (24, 29, 30, 34, 37)
                                    GROUP BY
                                        A.CLEARING_DATE, TRUNC(A.PTD_REGDATE) UNION
                                        SELECT
                                            A.CLEARING_DATE,
                                            TRUNC(A.PTD_REGDATE),
                                            SUM(A.QTRX),
                                            SUM(A.PTD_AMOUNT),
                                            'FONDO SOSTENIMIENTO MEDIO DE PAGOS'
                                        FROM
                                            MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                        WHERE
                                            A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                            AND A.PP_CODE IN (24, 29, 30, 34, 37)
                                        GROUP BY
                                            A.CLEARING_DATE, TRUNC(A.PTD_REGDATE)
                        )                               T PIVOT(SUM(MONTO_TRX) FOR TIPO IN('FONDO GENERAL DE USOS 2200' AS USOS_2200,
                        'FONDO GENERAL DE USOS 2400' AS USOS_2400,
                        'FONDO SOSTENIMIENTO MEDIO DE PAGOS' AS MEDIOS_DE_PAGO,
                        'FONDO DE RECARGAS' AS RECARGAS))
                )                               
            GROUP BY
                FECHA_TRX --,USOS,RECARGAS,MEDIOS_DE_PAGO
    )                               
GROUP BY
    FECHA_TRX
ORDER BY
    1 ASC;

/
-- QUERY 1, ASIGNAR FECHA AL CALENDARIO DE LIQUIDACION
SELECT
    ROWID,
    A.*
FROM
    MERCURY.TBL_LIQUIDACIONRYT_DATE A
WHERE
    A.DATE_LIQ BETWEEN TRUNC(SYSDATE, 'MONTH') AND LAST_DAY(SYSDATE)
ORDER BY
    2 DESC;

/

--- QUERY 2, EJECUTAR PAQUETE DE LIQUIDACION USOS
BEGIN
    MERCURY.LIQUIDACIONRT_PKG.LIQUIDACIONRYT_USOS(TO_DATE('05-04-2024', 'DD-MM-YYYY')); --DIA ACTUAL
END;
/

--- QUERY 2.1, EJECUTAR PAQUETE DE LIQUIDACION USOS VISA
BEGIN
    MERCURY.LIQUIDACIONRT_PKG.LIQUIDACIONRYT_USOS_VISA(TO_DATE('05-04-2024', 'DD-MM-YYYY')); --DIA ACTUAL
END;
/
--- QUERY 2.2, EJECUTAR PAQUETE DE LIQUIDACION USOS MIFARE
BEGIN 
     MERCURY.LIQUIDACIONRT_PKG.LIQUIDACIONRYT_USOS_SW_MIFARE(TO_DATE('05-04-2024', 'DD-MM-YYYY')); --DIA ACTUAL
END;
/
-- QUERY 3, EJECUTAR PAQUETE DE LIQUIDACION RECARGAS Y VENTAS
BEGIN
    MERCURY.LIQUIDACIONRT_PKG.LIQUIDACION_REC(TO_DATE('05-04-2024', 'DD-MM-YYYY')); --DIA ACTUAL
END;

/


--*************************************************************************************
--*****************  REPORTE LIQUIDACION USOS POR TARIFA 2024******************************* DIA ACTUAL

SELECT
    FECHA_TRX,
    SUM(Q_USOS_2200)                                CANTIDAD_USOS_2200,
    '$'
    || TO_CHAR(SUM(M_USOS_2200), '9999999999')      MONTO_USOS_2200,
    SUM(Q_USOS_2400)                                CANTIDAD_USOS_2400,
    '$'
    || TO_CHAR(SUM(M_USOS_2400), '9999999999')      MONTO_USOS_2400,
    SUM(Q_USOS_2700)                                CANTIDAD_USOS_2700,
    '$'
    || TO_CHAR(SUM(M_USOS_2700), '9999999999')      MONTO_USOS_2700,
    SUM(Q_USOS_2900)                                CANTIDAD_USOS_2900,
    '$'
    || TO_CHAR(SUM(M_USOS_2900), '9999999999')      MONTO_USOS_2900,
    SUM(Q_RECARGAS)                                 CANTIDAD_RECARGA,
    '$'
    || TO_CHAR(SUM(M_RECARGAS), '9999999999')       MONTO_RECARGAS,
    SUM(Q_MEDIOS_DE_PAGO)                           CANTIDAD_MEDIOS_DE_PAGO,
    '$'
    || TO_CHAR(SUM(M_MEDIOS_DE_PAGO), '9999999999') MONTO_MEDIOS_DE_PAGO
FROM
    (
        SELECT
            FECHA_TRX,
            SUM(USOS_2200)      Q_USOS_2200,
            SUM(USOS_2400)      Q_USOS_2400,
            SUM(USOS_2700)      Q_USOS_2700,
            SUM(USOS_2900)      Q_USOS_2900,
            SUM(RECARGAS)       Q_RECARGAS,
            SUM(MEDIOS_DE_PAGO) Q_MEDIOS_DE_PAGO,
            0 M_USOS_2200,
            0 M_USOS_2400,
            0 M_USOS_2700,
            0 M_USOS_2900,
            0 M_RECARGAS,
            0 M_MEDIOS_DE_PAGO
        FROM
            (
 --USOS 2200
                SELECT
                    *
                FROM
                    (
                        SELECT
                            A.CLEARING_DATE              AS FECHA_LIQUIDACION,
                            TRUNC(A.CU_DATETIME)         FECHA_TRX,
                            SUM(A.QPAX)                  CANTIDAD_TRX,
                            SUM(A.CU_FAREVALUE)          MONTO_TRX,
                            'FONDO GENERAL DE USOS 2200' TIPO
                        FROM
                            MERCURY.TBL_LIQUIDACIONRYT_USOS A
                        WHERE
                            A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                            AND (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                            AND (A.TP_ID NOT IN (44, 999)
                            OR (A.TP_ID = 999
                            AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                            AND A.CU_FAREVALUE = 2200
                        GROUP BY
                            A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
 --USOS 2400
                            SELECT
                                *
                            FROM
                                (
                                    SELECT
                                        A.CLEARING_DATE              AS FECHA_LIQUIDACION,
                                        TRUNC(A.CU_DATETIME)         FECHA_TRX,
                                        SUM(A.QPAX)                  CANTIDAD_TRX,
                                        SUM(A.CU_FAREVALUE)          MONTO_TRX,
                                        'FONDO GENERAL DE USOS 2400' TIPO
                                    FROM
                                        MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                    WHERE
                                        A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                        AND  (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                                        AND (A.TP_ID NOT IN (44, 999)
                                        OR (A.TP_ID = 999
                                        AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                        AND A.CU_FAREVALUE = 2400
                                    GROUP BY
                                        A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
  --USOS 2700                                   
                                     SELECT
                                            *
                                        FROM
                                            (
                                                SELECT
                                                    A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                                    TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                                    SUM(A.QPAX)                          CANTIDAD_TRX,
                                                    SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                                    'FONDO GENERAL DE USOS 2700'         TIPO
                                                FROM
                                                    MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                                WHERE
                                                    A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                                    AND  (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                                                    AND (A.TP_ID NOT IN (44, 999)
                                                    OR (A.TP_ID = 999
                                                    AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                                    AND A.CU_FAREVALUE = 2700
                                                GROUP BY
                                                    A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
 --USOS 2900
                                        SELECT
                                            *
                                        FROM
                                            (
                                                SELECT
                                                    A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                                    TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                                    SUM(A.QPAX)                          CANTIDAD_TRX,
                                                    SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                                    'FONDO GENERAL DE USOS 2900'         TIPO
                                                FROM
                                                    MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                                WHERE
                                                    A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                                    AND  (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                                                    AND (A.TP_ID NOT IN (44, 999)
                                                    OR (A.TP_ID = 999
                                                    AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                                    AND A.CU_FAREVALUE = 2900
                                                GROUP BY
                                                    A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                                    SELECT
                                                        A.CLEARING_DATE,
                                                        TRUNC(A.PTD_REGDATE),
                                                        SUM(A.QTRX),
                                                        SUM(A.PTD_AMOUNT),
                                                        'FONDO DE RECARGAS'
                                                    FROM
                                                        MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                                    WHERE
                                                        A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                                        AND A.PP_CODE NOT IN (24, 29, 30, 34, 37)
                                                    GROUP BY
                                                        A.CLEARING_DATE, TRUNC(A.PTD_REGDATE) UNION
                                                        SELECT
                                                            A.CLEARING_DATE,
                                                            TRUNC(A.PTD_REGDATE),
                                                            SUM(A.QTRX),
                                                            SUM(A.PTD_AMOUNT),
                                                            'FONDO SOSTENIMIENTO MEDIO DE PAGOS'
                                                        FROM
                                                            MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                                        WHERE
                                                            A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                                            AND A.PP_CODE IN (24, 29, 30, 34, 37)
                                                        GROUP BY
                                                            A.CLEARING_DATE, TRUNC(A.PTD_REGDATE)
                                                            )
                                            )                               
                                )                               
                    )                               T PIVOT(SUM(CANTIDAD_TRX) FOR TIPO IN('FONDO GENERAL DE USOS 2200' AS USOS_2200,
                    'FONDO GENERAL DE USOS 2400' AS USOS_2400,
                    'FONDO GENERAL DE USOS 2700' AS USOS_2700,
                    'FONDO GENERAL DE USOS 2900' AS USOS_2900,
                    'FONDO SOSTENIMIENTO MEDIO DE PAGOS' AS MEDIOS_DE_PAGO,
                    'FONDO DE RECARGAS' AS RECARGAS))
            )                               
        GROUP BY
            FECHA_TRX --,USOS,RECARGAS,MEDIOS_DE_PAGO
            UNION
            SELECT
                FECHA_TRX,
                0,
                0,
                0,
                0,
                0,
                0,
                SUM(USOS_2200)      M_USOS_2200,
                SUM(USOS_2400)      M_USOS_2400,
                SUM(USOS_2700)      M_USOS_2700,
                SUM(USOS_2900)      M_USOS_2900,
                SUM(RECARGAS)       M_RECARGAS,
                SUM(MEDIOS_DE_PAGO) M_MEDIOS_DE_PAGO
            FROM
                (
                    SELECT
                        *
                    FROM
                        (
                            SELECT
                                A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                SUM(A.QPAX)                          CANTIDAD_TRX,
                                SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                'FONDO GENERAL DE USOS 2200'         TIPO
                            FROM
                                MERCURY.TBL_LIQUIDACIONRYT_USOS A
                            WHERE
                                A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                AND  (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                                AND (A.TP_ID NOT IN (44, 999)
                                OR (A.TP_ID = 999
                                AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                AND A.CU_FAREVALUE = 2200
                            GROUP BY
                                A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                SELECT
                                    A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                    TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                    SUM(A.QPAX)                          CANTIDAD_TRX,
                                    SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                    'FONDO GENERAL DE USOS 2400'         TIPO
                                FROM
                                    MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                WHERE
                                    A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                    AND  (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                                    AND (A.TP_ID NOT IN (44, 999)
                                    OR (A.TP_ID = 999
                                    AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                    AND A.CU_FAREVALUE = 2400
                                GROUP BY
                                    A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                    SELECT
                                        A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                        TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                        SUM(A.QPAX)                          CANTIDAD_TRX,
                                        SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                        'FONDO GENERAL DE USOS 2700'         TIPO
                                    FROM
                                        MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                    WHERE
                                        A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                        AND  (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                                        AND (A.TP_ID NOT IN (44, 999)
                                        OR (A.TP_ID = 999
                                        AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                        AND A.CU_FAREVALUE = 2700
                                    GROUP BY
                                        A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                        SELECT
                                        A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                        TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                        SUM(A.QPAX)                          CANTIDAD_TRX,
                                        SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                        'FONDO GENERAL DE USOS 2900'         TIPO
                                    FROM
                                        MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                    WHERE
                                        A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                        AND  (A.CU_ITG_CTR IS NULL OR A.CU_ITG_CTR = 0)
                                        AND (A.TP_ID NOT IN (44, 999)
                                        OR (A.TP_ID = 999
                                        AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                        AND A.CU_FAREVALUE = 2900
                                    GROUP BY
                                        A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                        SELECT
                                            A.CLEARING_DATE,
                                            TRUNC(A.PTD_REGDATE),
                                            SUM(A.QTRX),
                                            SUM(A.PTD_AMOUNT),
                                            'FONDO DE RECARGAS'
                                        FROM
                                            MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                        WHERE
                                            A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                            AND A.PP_CODE NOT IN (24, 29, 30, 34, 37)
                                        GROUP BY
                                            A.CLEARING_DATE, TRUNC(A.PTD_REGDATE) UNION
                                            SELECT
                                                A.CLEARING_DATE,
                                                TRUNC(A.PTD_REGDATE),
                                                SUM(A.QTRX),
                                                SUM(A.PTD_AMOUNT),
                                                'FONDO SOSTENIMIENTO MEDIO DE PAGOS'
                                            FROM
                                                MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                            WHERE
                                                A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                                AND A.PP_CODE IN (24, 29, 30, 34, 37)
                                            GROUP BY
                                                A.CLEARING_DATE, TRUNC(A.PTD_REGDATE)
                        )                               T PIVOT(SUM(MONTO_TRX) FOR TIPO IN('FONDO GENERAL DE USOS 2200' AS USOS_2200,
                        'FONDO GENERAL DE USOS 2400' AS USOS_2400,
                        'FONDO GENERAL DE USOS 2700' AS USOS_2700,
                        'FONDO GENERAL DE USOS 2900' AS USOS_2900,
                        'FONDO SOSTENIMIENTO MEDIO DE PAGOS' AS MEDIOS_DE_PAGO,
                        'FONDO DE RECARGAS' AS RECARGAS))
                )                               
            GROUP BY
                FECHA_TRX --,USOS,RECARGAS,MEDIOS_DE_PAGO
    )                               
GROUP BY
    FECHA_TRX
ORDER BY
    1 ASC;

/

--*************************************************************************************
--*******************  REPORTE LIQUIDACION USOS CONSOLIDADO*************************************** DIA ACTUAL


SELECT
    FECHA_TRX,
    SUM(Q_USOS)                                    CANTIDAD_USOS,
    '$'
    ||TO_CHAR(SUM(M_USOS), '9999999999')MONTO_USOS           ,
    SUM(Q_RECARGAS)                                CANTIDAD_RECARGA,
    '$'
    ||TO_CHAR(SUM(M_RECARGAS), '9999999999')       MONTO_RECARGAS,
    SUM(Q_MEDIOS_DE_PAGO)                          CANTIDAD_MEDIOS_DE_PAGO,
    '$'
    ||TO_CHAR(SUM(M_MEDIOS_DE_PAGO), '9999999999') MONTO_MEDIOS_DE_PAGO
FROM
    (
        SELECT
            FECHA_TRX,
            SUM(USOS)           Q_USOS,
            SUM(RECARGAS)       Q_RECARGAS,
            SUM(MEDIOS_DE_PAGO) Q_MEDIOS_DE_PAGO,
            0 M_USOS,
            0 M_RECARGAS,
            0 M_MEDIOS_DE_PAGO
        FROM
            (
                SELECT
                    *
                FROM
                    (
                        SELECT
                            A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                            TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                            SUM(A.QPAX)                          CANTIDAD_TRX,
                            SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                            'FONDO GENERAL DE USOS'              TIPO
                        FROM
                            MERCURY.TBL_LIQUIDACIONRYT_USOS A
                        WHERE
                            A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                          AND (A.CU_ITG_CTR IS NULL OR A.Cu_Itg_Ctr =0)
                            AND (A.TP_ID NOT IN (44, 999)
                            OR (A.TP_ID = 999
                            AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                        GROUP BY
                            A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                            SELECT
                                A.CLEARING_DATE,
                                TRUNC(A.PTD_REGDATE),
                                SUM(A.QTRX),
                                SUM(A.PTD_AMOUNT),
                                'FONDO DE RECARGAS'
                            FROM
                                MERCURY.TBL_LIQUIDACIONRYT_REC  A
                            WHERE
                                A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                AND A.PP_CODE NOT IN (24, 29, 30, 34, 37)
                            GROUP BY
                                A.CLEARING_DATE, TRUNC(A.PTD_REGDATE) UNION
                                SELECT
                                    A.CLEARING_DATE,
                                    TRUNC(A.PTD_REGDATE),
                                    SUM(A.QTRX),
                                    SUM(A.PTD_AMOUNT),
                                    'FONDO SOSTENIMIENTO MEDIO DE PAGOS'
                                FROM
                                    MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                WHERE
                                    A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                    AND A.PP_CODE IN (24, 29, 30, 34, 37)
                                GROUP BY
                                    A.CLEARING_DATE, TRUNC(A.PTD_REGDATE)
                    )                               T PIVOT(SUM(CANTIDAD_TRX) FOR TIPO IN('FONDO GENERAL DE USOS' AS USOS,
                    'FONDO SOSTENIMIENTO MEDIO DE PAGOS' AS MEDIOS_DE_PAGO,
                    'FONDO DE RECARGAS' AS RECARGAS))
            )                               
        GROUP BY
            FECHA_TRX --,USOS,RECARGAS,MEDIOS_DE_PAGO
            UNION
            SELECT
                FECHA_TRX,
                0,
                0,
                0,
                SUM(USOS)           M_USOS,
                SUM(RECARGAS)       M_RECARGAS,
                SUM(MEDIOS_DE_PAGO) M_MEDIOS_DE_PAGO
            FROM
                (
                    SELECT
                        *
                    FROM
                        (
                            SELECT
                                A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                SUM(A.QPAX)                          CANTIDAD_TRX,
                                SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                'FONDO GENERAL DE USOS'              TIPO
                            FROM
                                MERCURY.TBL_LIQUIDACIONRYT_USOS A
                            WHERE
                                A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                AND (A.CU_ITG_CTR IS NULL OR A.Cu_Itg_Ctr =0)
                                AND (A.TP_ID NOT IN (44, 999)
                                OR (A.TP_ID = 999
                                AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                            GROUP BY
                                A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                SELECT
                                    A.CLEARING_DATE,
                                    TRUNC(A.PTD_REGDATE),
                                    SUM(A.QTRX),
                                    SUM(A.PTD_AMOUNT),
                                    'FONDO DE RECARGAS'
                                FROM
                                    MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                WHERE
                                    A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                    AND A.PP_CODE NOT IN (24, 29, 30, 34, 37)
                                GROUP BY
                                    A.CLEARING_DATE, TRUNC(A.PTD_REGDATE) UNION
                                    SELECT
                                        A.CLEARING_DATE,
                                        TRUNC(A.PTD_REGDATE),
                                        SUM(A.QTRX),
                                        SUM(A.PTD_AMOUNT),
                                        'FONDO SOSTENIMIENTO MEDIO DE PAGOS'
                                    FROM
                                        MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                    WHERE
                                        A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                        AND A.PP_CODE IN (24, 29, 30, 34, 37)
                                    GROUP BY
                                        A.CLEARING_DATE, TRUNC(A.PTD_REGDATE)
                        )                               T PIVOT(SUM(MONTO_TRX) FOR TIPO IN('FONDO GENERAL DE USOS' AS USOS,
                        'FONDO SOSTENIMIENTO MEDIO DE PAGOS' AS MEDIOS_DE_PAGO,
                        'FONDO DE RECARGAS' AS RECARGAS))
                )                               
            GROUP BY
                FECHA_TRX --,USOS,RECARGAS,MEDIOS_DE_PAGO
    )
GROUP BY
    FECHA_TRX
ORDER BY
    1 ASC;

/

--*************************************************************************************
--*******************  REPORTE LIQUIDACION USOS VISA*********************************** DIA ACTUAL

SELECT
    TRUNC(A.CU_DATETIME)    FECHA_TRX,
    SUM(A.QPAX)             CANTIDAD_TRX,
    SUM(A.CU_FAREVALUE)     MONTO_TRX,
    A.CU_FAREVALUE          TARIFA,
    A.CLEARING_DATE         AS FECHA_LIQUIDACION,
    'FONDO GENERAL DE VISA' TIPO
FROM
    MERCURY.TBL_LIQUIDACIONRYT_USOS A
WHERE
    A.CLEARING_DATE >= TO_DATE('&DIA', 'DD-MM-YYYY')
    AND A.CU_ITG_CTR IS NULL
    AND A.TP_ID IN (999) -- SOLO VISA
    AND A.LD_ID NOT IN (215) -- NO INCLUYE INTEGRACIONES MIO CABLE CA�AVERALEJO
    AND A.CU_FAREVALUE > 0
GROUP BY
    A.CLEARING_DATE, TRUNC(A.CU_DATETIME), A.CU_FAREVALUE
ORDER BY
    1 ASC;

/

--*************************************************************************************
--*****************  REPORTE LIQUIDACION USOS POR TARIFA 2022******************************* DIA ACTUAL
SELECT
    FECHA_TRX,
    SUM(Q_USOS_2200)                                CANTIDAD_USOS_2200,
    TO_CHAR(SUM(M_USOS_2200), 'FML9999999999')      MONTO_USOS_2200,
    SUM(Q_USOS_2400)                                CANTIDAD_USOS_2400,
    TO_CHAR(SUM(M_USOS_2400), 'FML9999999999')      MONTO_USOS_2400,
    SUM(Q_RECARGAS)                                 CANTIDAD_RECARGA,
    TO_CHAR(SUM(M_RECARGAS), 'FML9999999999')       MONTO_RECARGAS,
    SUM(Q_MEDIOS_DE_PAGO)                           CANTIDAD_MEDIOS_DE_PAGO,
    TO_CHAR(SUM(M_MEDIOS_DE_PAGO), 'FML9999999999') MONTO_MEDIOS_DE_PAGO
FROM
    (
        SELECT
            FECHA_TRX,
            SUM(USOS_2200)      Q_USOS_2200,
            SUM(USOS_2400)      Q_USOS_2400,
            SUM(RECARGAS)       Q_RECARGAS,
            SUM(MEDIOS_DE_PAGO) Q_MEDIOS_DE_PAGO,
            0 M_USOS_2200,
            0 M_USOS_2400,
            0 M_RECARGAS,
            0 M_MEDIOS_DE_PAGO
        FROM
            (
                SELECT
                    *
                FROM
                    (
                        SELECT
                            A.CLEARING_DATE              AS FECHA_LIQUIDACION,
                            TRUNC(A.CU_DATETIME)         FECHA_TRX,
                            SUM(A.QPAX)                  CANTIDAD_TRX,
                            SUM(A.CU_FAREVALUE)          MONTO_TRX,
                            'FONDO GENERAL DE USOS 2200' TIPO
                        FROM
                            MERCURY.TBL_LIQUIDACIONRYT_USOS A
                        WHERE
                            A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                            AND A.CU_ITG_CTR IS NULL
                            AND (A.TP_ID NOT IN (44, 999)
                            OR (A.TP_ID = 999
                            AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                            AND A.CU_FAREVALUE = 2200
                            AND A.LD_ID NOT IN (215)
                        GROUP BY
                            A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                            SELECT
                                *
                            FROM
                                (
                                    SELECT
                                        A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                        TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                        SUM(A.QPAX)                          CANTIDAD_TRX,
                                        SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                        'FONDO GENERAL DE USOS 2400'         TIPO
                                    FROM
                                        MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                    WHERE
                                        A.CLEARING_DATE >= TO_DATE('&DIA', 'DD-MM-YYYY')
                                        AND A.CU_ITG_CTR IS NULL
                                        AND (A.TP_ID NOT IN (44, 999)
                                        OR (A.TP_ID = 999
                                        AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                        AND A.CU_FAREVALUE = 2400
                                        AND A.LD_ID NOT IN (215)
                                    GROUP BY
                                        A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                        SELECT
                                            A.CLEARING_DATE,
                                            TRUNC(A.PTD_REGDATE),
                                            SUM(A.QTRX),
                                            SUM(A.PTD_AMOUNT),
                                            'FONDO DE RECARGAS'
                                        FROM
                                            MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                        WHERE
                                            A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                            AND A.PP_CODE NOT IN (24, 29, 30, 34, 37)
                                        GROUP BY
                                            A.CLEARING_DATE, TRUNC(A.PTD_REGDATE) UNION
                                            SELECT
                                                A.CLEARING_DATE,
                                                TRUNC(A.PTD_REGDATE),
                                                SUM(A.QTRX),
                                                SUM(A.PTD_AMOUNT),
                                                'FONDO SOSTENIMIENTO MEDIO DE PAGOS'
                                            FROM
                                                MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                            WHERE
                                                A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                                AND A.PP_CODE IN (24, 29, 30, 34, 37)
                                            GROUP BY
                                                A.CLEARING_DATE, TRUNC(A.PTD_REGDATE)
                                )                               
                    )                               T PIVOT(SUM(CANTIDAD_TRX) FOR TIPO IN('FONDO GENERAL DE USOS 2200' AS USOS_2200,
                    'FONDO GENERAL DE USOS 2400' AS USOS_2400,
                    'FONDO SOSTENIMIENTO MEDIO DE PAGOS' AS MEDIOS_DE_PAGO,
                    'FONDO DE RECARGAS' AS RECARGAS))
            )                               
        GROUP BY
            FECHA_TRX --,USOS,RECARGAS,MEDIOS_DE_PAGO
            UNION
            SELECT
                FECHA_TRX,
                0,
                0,
                0,
                0,
                SUM(USOS_2200)      M_USOS_2200,
                SUM(USOS_2400)      M_USOS_2400,
                SUM(RECARGAS)       M_RECARGAS,
                SUM(MEDIOS_DE_PAGO) M_MEDIOS_DE_PAGO
            FROM
                (
                    SELECT
                        *
                    FROM
                        (
                            SELECT
                                A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                SUM(A.QPAX)                          CANTIDAD_TRX,
                                SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                'FONDO GENERAL DE USOS 2200'         TIPO
                            FROM
                                MERCURY.TBL_LIQUIDACIONRYT_USOS A
                            WHERE
                                A.CLEARING_DATE >= TO_DATE('&DIA', 'DD-MM-YYYY')
                                AND A.CU_ITG_CTR IS NULL
                                AND (A.TP_ID NOT IN (44, 999)
                                OR (A.TP_ID = 999
                                AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                AND A.CU_FAREVALUE = 2200
                                AND A.LD_ID NOT IN (215)
                            GROUP BY
                                A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                SELECT
                                    A.CLEARING_DATE                      AS FECHA_LIQUIDACION,
                                    TRUNC(A.CU_DATETIME)                 FECHA_TRX,
                                    SUM(A.QPAX)                          CANTIDAD_TRX,
                                    SUM(A.CU_FAREVALUE)                  MONTO_TRX,
                                    'FONDO GENERAL DE USOS 2400'         TIPO
                                FROM
                                    MERCURY.TBL_LIQUIDACIONRYT_USOS A
                                WHERE
                                    A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                    AND A.CU_ITG_CTR IS NULL
                                    AND (A.TP_ID NOT IN (44, 999)
                                    OR (A.TP_ID = 999
                                    AND A.CU_FAREVALUE > 0)) -- SOLO ESTACIONES
                                    AND A.CU_FAREVALUE = 2400
                                    AND A.LD_ID NOT IN (215)
                                GROUP BY
                                    A.CLEARING_DATE, TRUNC(A.CU_DATETIME) UNION
                                    SELECT
                                        A.CLEARING_DATE,
                                        TRUNC(A.PTD_REGDATE),
                                        SUM(A.QTRX),
                                        SUM(A.PTD_AMOUNT),
                                        'FONDO DE RECARGAS'
                                    FROM
                                        MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                    WHERE
                                        A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                        AND A.PP_CODE NOT IN (24, 29, 30, 34, 37)
                                    GROUP BY
                                        A.CLEARING_DATE, TRUNC(A.PTD_REGDATE) UNION
                                        SELECT
                                            A.CLEARING_DATE,
                                            TRUNC(A.PTD_REGDATE),
                                            SUM(A.QTRX),
                                            SUM(A.PTD_AMOUNT),
                                            'FONDO SOSTENIMIENTO MEDIO DE PAGOS'
                                        FROM
                                            MERCURY.TBL_LIQUIDACIONRYT_REC  A
                                        WHERE
                                            A.CLEARING_DATE = TO_DATE('&DIA', 'DD-MM-YYYY')
                                            AND A.PP_CODE IN (24, 29, 30, 34, 37)
                                        GROUP BY
                                            A.CLEARING_DATE, TRUNC(A.PTD_REGDATE)
                        )                               T PIVOT(SUM(MONTO_TRX) FOR TIPO IN('FONDO GENERAL DE USOS 2200' AS USOS_2200,
                        'FONDO GENERAL DE USOS 2400' AS USOS_2400,
                        'FONDO SOSTENIMIENTO MEDIO DE PAGOS' AS MEDIOS_DE_PAGO,
                        'FONDO DE RECARGAS' AS RECARGAS))
                )                               
            GROUP BY
                FECHA_TRX --,USOS,RECARGAS,MEDIOS_DE_PAGO
    )                               
GROUP BY
    FECHA_TRX
ORDER BY
    1 ASC;

/
