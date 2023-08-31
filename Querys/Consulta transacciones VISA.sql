SELECT a.entry_date       AS fecha_uso,
       a.response_date,
       a.att2_dat         AS fecha_recobro,
       a.entry_id         AS id_transaccion,
       a.card_number      AS numero_tarjeta,
       a.device_id        AS id_validador,
       a.terminalid       AS terminaid,
       a.short_txt        AS ruta,
       a.fare_applied,
       a.bin,
       a.last4,
       a.authorization_id,
       a.att4_chr         AS rta_validador,
       a.status,
       a.processed,
       a.descripcion_rta,
       a.tsn_reg,
       a.fecha_ws
FROM mercury.tbl_trx_utrytopcs a
 WHERE 1 = 1
   AND a.bin = 409355
   AND a.last4 = 2733
--AND A.CARD_NUMBER = '62aef571e57b3d36b9d2dd5c83c9f78ae8e002be03801200ed156c1e98fc138f'
--AND A.ACCESS_POINT_ID = 
--and a.entry_date >= to_date ('19/11/2022 00:00','dd/mm/yyyy hh24:mi')
--and a.entry_date < to_date ('17/11/2022 09:30','dd/mm/yyyy hh24:mi')
--and a.response_date >= to_date ('24/10/2022','dd/mm/yyyy')
--and a.response_date <= to_date ('25/10/2022','dd/mm/yyyy')
--and trunc (a.att2_dat) = to_date ('30/09/2022','dd/mm/yyyy') --fecha de recobro
--and a.descripcion_rta like '%NOT SUFFICIENT FUNDS%'
--and a.fecha_ws >= trunc (sysdate -2)
--and a.entry_id = 2209260546536340971
--and a.att2_dat is not null
 ORDER BY 1 ASC;

select *
  from mercury.tbl_trx_utrytopcs a
 where 1 = 1
   and a.bin = 454616
   and a.last4 = 4695
