SELECT /*ut.route_id*/
 *
  FROM mercury.tbl_trx_utrytopcs ut;
  GROUP BY ut.is_transfer;
 /*WHERE ut.route_id = 'P000'
 ORDER BY ut.fecha_ws desc;*/

/
/*is_transfer --> Transbordos*/

  SELECT car.cut_id, -- Tipo uso 1 := Pasajero
         car.udtm_id,
         car.iss_id,
         car.cd_id,
         car.crd_snr,
         car.app_id,
         car.cu_tsn,
         car.cu_datetime, -- fecha de uso
         car.cu_dat_inc_puente, -- fecha clearing
         car.cu_farevalue,
         car.cu_partfareseqnbr, -- Bolsillos
         car.cu_itg_ctr -- integracion 
    FROM mercury.cardusage car
   WHERE car.app_id IN ('902', '920') -- Usos pagos bancos 902 --> BANCOLOMBIA  - 920 --> BANCO BOGOTA
     AND car.cu_itg_ctr IS NOT NULL
   ORDER BY car.cu_datetime DESC;

---UDTM_ID ?????
/

  SELECT *
    FROM mercury.usagedatatripmt us
   WHERE us.udtm_dtstart_dvs >= (SYSDATE - 1)
     AND us.udtm_dtstart_dvs <= (SYSDATE);
-- ORDER BY us.udtm_dtstart_dvs DESC; -- usos viaje 
---UDS_ID ????

/

  SELECT * FROM mercury.transportproviders tr; /*WHERE tr.tp_id IN  (44, 999)*/; -- punto 
/

  SELECT * FROM mercury.usagedataservice; -- usos services
--- UDF_ID ???
/

  SELECT 
           CASE
                WHEN (app.app_id = 902)THEN 
                'BANCOLOMBIA'
                WHEN  (app.app_id = 920) THEN 
                'BANCO BOGOTA'
                END app_desc, 
                'TARJETA' AS type_product
    FROM mercury.applications app  /*app.app_descshort IN('BANCO BOGOTA',
                             'ESCOLAR',
                             'ESTUDIANTE_SBDO',
                             'COMUN');*/
  WHERE 1 = 1
  AND app_id IN (920, 902) ;

/

  SELECT * FROM mercury.linedetails; --  Linea Estacion 

/

SELECT us.tp_id,
       us.veh_id,
       CASE
         WHEN SUBSTR(us.veh_id, 2, 1) = 2 THEN
          'Padron'
         WHEN SUBSTR(us.veh_id, 2, 1) = 3 THEN
          'Complementario'
         WHEN SUBSTR(us.veh_id, 1, 1) = 5 AND SUBSTR(us.veh_id, 2, 1) = 7 THEN
          'MIO cable' 
         ELSE
          'Otro'
       END veh_type
  FROM mercury.usagedatafile us
  WHERE us.tp_id = 44;
/* GROUP BY us.tp_id, us.veh_id;*/

/
  SELECT *
    FROM mercury.tbl_trx_utrytopcs ut;
         
/
          
 SELECT *
   FROM mercury.tbl_liquidacionryt_date lqd
   ORDER BY lqd.date_liq_max DESC;

/

  SELECT * FROM mercury.tbl_liquidacionryt_rec mlr;
  
/  

SELECT * FROM mercury.Tbl_Liquidacionryt_Usos mlu; --  CURSOR --> C_USOS_PENDIENTES_VISA
--             C_USOS_PENDIENTES                             

/*Fecha Especificada en la ejecucuin del paquete VISA --> CURSOR C_FECHAS_LIQUIDACION(FECHA_LIM IN DATE)*/

/

  SELECT * FROM mercury.pos_trandt ptr
         WHERE ptr.crd_snr = 2759739470 ;
/

  SELECT * FROM mercury.pos_tranmt;    
  
  
/

  SELECT * FROM mercury.applications;

/
--- CONSULTA VALIDADORES
 SELECT *
      FROM (SELECT TRUNC(cu.cu_datetime),
                   cu.cu_tpid TP_ID,
                   ld.ld_id LD_ID,
                   ld.ld_desc LD_DESC,
                   udf.veh_id VEH_ID,
                   ROW_NUMBER() OVER(ORDER BY TRUNC(cu.cu_datetime)) As Row_Num
              FROM mercury.cardusage        cu,
                   mercury.linedetails      ld,
                   mercury.usagedatatripmt  udtm,
                   mercury.usagedataservice uds,
                   mercury.usagedatafile    udf,
                   mercury.applications     app
             WHERE cu.udtm_id = udtm.udtm_id
               AND udtm.uds_id = uds.uds_id
               AND uds.udf_id = udf.udf_id
               AND cu.cu_datetime >= TO_DATE('&DIA', 'DD-MM-YYYY') --TO_DATE('24-08-2022 00:01', 'dd-mm-yyyy hh24:mi')
               AND cu.cu_datetime <= TO_DATE('&DIA2', 'DD-MM-YYYY') --TO_DATE('24-08-2022 23:59', 'dd-mm-yyyy hh24:mi')
               AND cu.cut_id = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
               AND nvl(cu.cu_partfareseqnbr, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
               AND app.app_id = cu.app_id
               AND ld.ld_id = cu.ld_id
               AND ld.ld_desc LIKE ('%TERMINAL PASO DEL COMERCIO%')
               AND udf.veh_id IN (6002, 6003)
               AND ((udf.tp_id <> 67) OR (udf.veh_id <> 9114))
               AND length(udf.veh_id) < 5
             GROUP BY TRUNC(cu.cu_datetime),
                      cu.cu_tpid,
                      ld.ld_id,
                      ld.ld_desc,
                      udf.veh_id) t
     WHERE t.row_num <= 2;
