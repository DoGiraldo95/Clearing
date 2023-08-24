--*******************  Reporte Liquidacion Usos Consolidado*************************************** DIA ACTUAL


SELECT FECHA_TRX,
       SUM(Q_USOS) CANTIDAD_USOS,
       '$'||to_char(SUM(M_USOS),'9999999999')MONTO_USOS,
       SUM(Q_RECARGAS) CANTIDAD_RECARGA,
       '$'||to_char(SUM(M_RECARGAS),'9999999999') MONTO_RECARGAS,
       SUM(Q_MEDIOS_DE_PAGO) CANTIDAD_MEDIOS_DE_PAGO,
       '$'||TO_CHAR(SUM(M_MEDIOS_DE_PAGO),'9999999999') MONTO_MEDIOS_DE_PAGO
  FROM (

        SELECT FECHA_TRX,
                SUM(USOS) Q_USOS,
                SUM(RECARGAS) Q_RECARGAS,
                SUM(MEDIOS_DE_PAGO) Q_MEDIOS_DE_PAGO,
                0 M_USOS,
                0 M_RECARGAS,
                0 M_MEDIOS_DE_PAGO

          FROM (

                 SELECT *
                   FROM (SELECT a.clearing_date AS FECHA_LIQUIDACION,
                                 trunc(a.cu_datetime) FECHA_TRX,
                                 sum(a.qpax) CANTIDAD_TRX,
                                 sum(a.cu_farevalue) MONTO_TRX,
                                 'FONDO GENERAL DE USOS' TIPO
                            FROM MERCURY.TBL_LIQUIDACIONRYT_USOS A
                           WHERE A.CLEARING_DATE =
                                 TO_DATE('04-07-2023', 'DD-MM-YYYY')
                             and a.cu_itg_ctr is null
                             AND (A.TP_ID NOT IN (44,999) or (A.tp_id = 999 and a.cu_farevalue > 0))  -- SOLO ESTACIONES
                             AND a.ld_id NOT IN (215)
                           group by a.clearing_date, trunc(a.cu_datetime)
                          union

                          SELECT a.clearing_date,
                                 trunc(a.ptd_regdate),
                                 sum(a.qtrx),
                                 sum(a.ptd_amount),
                                 'FONDO DE RECARGAS'
                            FROM MERCURY.TBL_LIQUIDACIONRYT_REC A
                           where a.clearing_date =
                                 TO_DATE('04-07-2023', 'DD-MM-YYYY')
                             and a.pp_code not in (24, 29, 30, 34, 37)
                           group by a.clearing_date, trunc(a.ptd_regdate)

                          union

                          SELECT a.clearing_date,
                                 trunc(a.ptd_regdate),
                                 sum(a.qtrx),
                                 sum(a.ptd_amount),
                                 'FONDO SOSTENIMIENTO MEDIO DE PAGOS'
                            FROM MERCURY.TBL_LIQUIDACIONRYT_REC A
                           where a.clearing_date =
                                 TO_DATE('04-07-2023', 'DD-MM-YYYY')
                             and a.pp_code in (24, 29, 30, 34, 37)
                           group by a.clearing_date, trunc(a.ptd_regdate)) T

                         PIVOT(SUM(CANTIDAD_TRX) FOR TIPO IN('FONDO GENERAL DE USOS' AS USOS,
                                                             'FONDO SOSTENIMIENTO MEDIO DE PAGOS' AS
                                                             MEDIOS_DE_PAGO,
                                                             'FONDO DE RECARGAS' AS
                                                             RECARGAS)))
         GROUP BY FECHA_TRX --,USOS,RECARGAS,MEDIOS_DE_PAGO

        UNION

        SELECT FECHA_TRX,
                0,
                0,
                0,
                SUM(USOS) M_USOS,
                SUM(RECARGAS) M_RECARGAS,
                SUM(MEDIOS_DE_PAGO) M_MEDIOS_DE_PAGO

          FROM (

                 SELECT *
                   FROM (SELECT a.clearing_date AS FECHA_LIQUIDACION,
                                 trunc(a.cu_datetime) FECHA_TRX,
                                 sum(a.qpax) CANTIDAD_TRX,
                                 sum(a.cu_farevalue) MONTO_TRX,
                                 'FONDO GENERAL DE USOS' TIPO
                            FROM MERCURY.TBL_LIQUIDACIONRYT_USOS A
                           WHERE A.CLEARING_DATE =
                                 TO_DATE('04-07-2023', 'DD-MM-YYYY')
                             and a.cu_itg_ctr is null
                             AND (A.TP_ID NOT IN (44,999) or (A.tp_id = 999 and a.cu_farevalue > 0)) -- SOLO ESTACIONES
                             AND a.ld_id NOT IN (215)
                            group by a.clearing_date, trunc(a.cu_datetime)
                          UNION

                          SELECT a.clearing_date,
                                 trunc(a.ptd_regdate),
                                 sum(a.qtrx),
                                 sum(a.ptd_amount),
                                 'FONDO DE RECARGAS'
                            FROM MERCURY.TBL_LIQUIDACIONRYT_REC A
                           where a.clearing_date =
                                 TO_DATE('04-07-2023', 'DD-MM-YYYY')
                             and a.pp_code not in (24, 29, 30, 34, 37)
                           group by a.clearing_date, trunc(a.ptd_regdate)

                          UNION

                          SELECT a.clearing_date,
                                 trunc(a.ptd_regdate),
                                 sum(a.qtrx),
                                 sum(a.ptd_amount),
                                 'FONDO SOSTENIMIENTO MEDIO DE PAGOS'
                            FROM MERCURY.TBL_LIQUIDACIONRYT_REC A
                           where a.clearing_date =
                                 TO_DATE('04-07-2023', 'DD-MM-YYYY')
                             and a.pp_code in (24, 29, 30, 34, 37)
                           group by a.clearing_date, trunc(a.ptd_regdate)) T

                         PIVOT(SUM(MONTO_TRX) FOR TIPO IN('FONDO GENERAL DE USOS' AS USOS,
                                                          'FONDO SOSTENIMIENTO MEDIO DE PAGOS' AS
                                                          MEDIOS_DE_PAGO,
                                                          'FONDO DE RECARGAS' AS
                                                          RECARGAS)))
         GROUP BY FECHA_TRX --,USOS,RECARGAS,MEDIOS_DE_PAGO
        )
 GROUP BY FECHA_TRX
 ORDER BY 1 ASC;
