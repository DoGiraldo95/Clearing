SELECT /*f.usrdoc_number*/
 *
  FROM mercury.tbl_liquidacionryt_usos;


SELECT * FROM mercury.tbl_valor_consignar_mrc;    
                                                                                                                                                                                                                                                                           
SELECT a.nombre, a.identificador FROM (SELECT b.opl_username NOMBRE, b.pos_id IDENTIFICADOR FROM  mercury.tbl_ventas_netsales b
       GROUP BY b.opl_username, b.pos_id) a
             WHERE a.identificador = 742; --> 
SELECT * FROM mercury.linedetails; /*detalle uso estacion*/
SELECT * FROM mercury.userdocuments; /*usuario*/ /*usr_id*/ /*dt_id*/
SELECT * FROM mercury.cardsxusers; /*tarjetaxusuario*/ /*usr_id*/ /*cd_id*/ /*issi_id*/ /*crd_snr*/ --> Tarjetas x usaurio
SELECT * FROM mercury.applications; /*iss_id*/ /*app_id*/ /*sf_id*/ /*ma_id*/
SELECT * FROM mercury.cards; /*iss_id*/ /*cd_id*/ /*cty_id*/ --> Tarjetas
SELECT * FROM mercury.usagedatafile; /*tp_id dv_id*/
SELECT * FROM mercury.cardusage;
SELECT * FROM mercury.tbl_liquidacionryt_usos a;
SELECT * FROM mercury.transportproviders a
       WHERE a.tp_id IN (19,20); /*(16, 44, 34)*/ ; --> proveedores de transporte 
SELECT * FROM mercury.providers; --> proveedores
SELECT * FROM mercury.tbl_tisc_mre a WHERE a.sd_id = 886; -->  MRE CRD_INTSNR
SELECT * FROM mercury.carddesign;
SELECT * FROM mercury.pos_device;
SELECT * FROM mercury.issuers;
SELECT * FROM mercury.pos_tranmt; /* tp_id prs_id*/
SELECT * FROM mercury.personnelxprsfcts; /*prs_id*/
SELECT * FROM mercury.usagedatafile;
SELECT * FROM mercury.tbl_trx_utrytopcs; --> transacciones visa 
SELECT * FROM mercury.pos_products;
SELECT * FROM mercury.usagedataservice;
SELECT * FROM mercury.usagedatatripmt;
SELECT * FROM mercury.usagedatafile; --> udf
SELECT * FROM mercury.POS_DEVICE a; --> puntos recarga pd_code
SELECT * FROM mercury.POS_PRODUCTS PP; --> productos
SELECT *  FROM mercury.pos_trandt a
      WHERE trunc (a.ptd_regdate) = to_date('29-03-2023', 'DD-MM-YYYY') 
      AND a.pp_code IN (23, 25); --> Transanccion pd_id cd_id ld_id pp_code
SELECT * FROM mercury.carddesign;
SELECT * FROM mercury.Tbl_Pos_Locations_Station;
SELECT * FROM mercury.vehiclemanufactortypes a;
       WHERE a.veh_id = 85003;

SELECT trunc(e.ptd_regdate), b.pd_code, b.pl_code, a.pd_desc, d.tp_desc
  FROM mercury.Tbl_Pos_Locations_Station a,
       mercury.pos_device                b,
       mercury.pos_tranmt                c,
       mercury.transportproviders        d,
       mercury.pos_trandt                e
 WHERE 1 = 1
   AND a.pd_code = b.pd_code
   AND b.pd_code = c.pd_code
   AND c.pd_code = e.pd_code
   AND c.tp_id = d.tp_id
      /* AND b.pd_desc LIKE 'MRE%'*/
   AND b.pl_code IN (13, 15)
   AND trunc(e.ptd_regdate) >= to_date('&dia 00:01', 'DD-MM-YYYY HH24:MM')
   AND trunc(e.ptd_regdate) <= to_date('&dia 23:59', 'DD-MM-YYYY HH24:MM')
   AND e.ptd_status = 'A'
 GROUP BY b.pd_code, a.pd_desc, b.pl_code, tp_desc;
