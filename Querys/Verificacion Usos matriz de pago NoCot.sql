SELECT *
  FROM (SELECT t.fecha_liquidacion, SUM(t.cantidad_trx)
          FROM (SELECT a.clearing_date - 1 AS fecha_liquidacion,
                       trunc(a.cu_datetime) fecha_trx,
                       SUM(a.qpax) cantidad_trx,
                       a.cu_farevalue tarifa
                  FROM mercury.tbl_liquidacionryt_usos a
                 WHERE a.clearing_date BETWEEN
                       TO_DATE('&Fecha_1', 'dd-mm-yyyy') AND
                       TO_DATE('&Fecha_2', 'dd-mm-yyyy')
                   AND a.cu_itg_ctr IS NULL
                   AND (a.tp_id NOT IN (44, 999) OR
                       (a.tp_id = 999 AND a.cu_farevalue > 0)) -- SOLO ESTACIONES
                   AND a.ld_id NOT IN (215)
                   AND to_char(a.clearing_date, 'D') IN (2, 3, 4, 5)
                 GROUP BY a.clearing_date,
                          trunc(a.cu_datetime),
                          a.cu_farevalue) t
         GROUP BY t.fecha_liquidacion
        UNION
        SELECT DISTINCT (b.fecha), SUM(trx)
          FROM (SELECT CASE
                         WHEN to_char(t.fecha_trx, 'D') = 5 AND
                              to_char(t.fecha_liquidacion, 'D') = 1 THEN
                          t.fecha_liquidacion - 3
                         WHEN to_char(t.fecha_trx, 'D') = 6 AND
                              to_char(t.fecha_liquidacion, 'D') = 1 THEN
                          t.fecha_liquidacion - 2
                         WHEN to_char(t.fecha_liquidacion, 'D') = 1 AND
                              TO_NUMBER(trunc(t.puente) - trunc(t.fecha_trx)) > 90 THEN
                          t.fecha_liquidacion - 1
                         ELSE
                          t.fecha_liquidacion - 1
                       END AS fecha,
                       t.cantidad_trx trx
                  FROM (SELECT a.clearing_date AS fecha_liquidacion,
                               trunc(a.cu_datetime) fecha_trx,
                               SUM(a.qpax) cantidad_trx,
                               SUM(a.cu_farevalue) monto_trx,
                               trunc(a.cu_dat_inc_puente) puente
                          FROM mercury.tbl_liquidacionryt_usos a
                         WHERE a.clearing_date BETWEEN
                               TO_DATE('&Fecha_1', 'dd-mm-yyyy') AND
                               TO_DATE('&Fecha_2', 'dd-mm-yyyy')
                           AND a.cu_itg_ctr IS NULL
                           AND (a.tp_id NOT IN (44, 999) OR
                               (a.tp_id = 999 AND a.cu_farevalue > 0)) -- SOLO ESTACIONES
                           AND a.ld_id NOT IN (215)
                         GROUP BY a.clearing_date,
                                  trunc(a.cu_datetime),
                                  trunc(a.cu_dat_inc_puente)) t) b
         GROUP BY b.fecha) consulta
 ORDER BY 1
