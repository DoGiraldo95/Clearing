CREATE OR REPLACE PROCEDURE prc_alerta_validadores_nuevos AS

/*
  Autor: Diego Giraldo
  Version: 1.0
  Fecha: 30-05-2023
  Descripcion: Procedimiento que chequea los validadores que no estan registrados en la tabla tbl_validadores_mrc
  */

  --------------------------- CURSORES -----------------------------------

  CURSOR c_validadores_maestra(validador usagedatafile.veh_id%TYPE) IS
    SELECT a.veh_id
      FROM tbl_validadores_mrc a
     WHERE a.status = 'A'
       AND a.veh_id = validador;

  CURSOR c_validadores_usos IS
    SELECT DISTINCT (udf.veh_id) validador_estacion, ld.ld_desc descripcion
      FROM mercury.cardusage        cu,
           mercury.linedetails      ld,
           mercury.usagedatatripmt  udtm,
           mercury.usagedataservice uds,
           mercury.usagedatafile    udf,
           mercury.applications     app
     WHERE cu.udtm_id = udtm.udtm_id
       AND udtm.uds_id = uds.uds_id
       AND uds.udf_id = udf.udf_id
       AND cu.cu_datetime >= trunc(sysdate - 1) --TO_DATE('24-08-2022 00:01', 'dd-mm-yyyy hh24:mi')
       AND cu.cu_datetime < trunc(sysdate) --TO_DATE('24-08-2022 23:59', 'dd-mm-yyyy hh24:mi')
       AND cu.cut_id = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
       AND nvl(cu.cu_partfareseqnbr, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
       AND app.app_id = cu.app_id
       AND ld.ld_id = cu.ld_id
       AND ((udf.tp_id <> 67) OR (udf.veh_id <> 9114))
       AND length(udf.veh_id) < 5
     GROUP BY udf.veh_id, ld.ld_desc;

  --------------------------- VARIABLES -----------------------------------

  r_remite       VARCHAR2(1000) := 'dgiraldo@utryt.com.co';
  r_recibe       VARCHAR2(1000) := 'jbarrios@utryt.com.co';
  p_recibe_copia VARCHAR2(1000) := '';
  p_asunto       VARCHAR2(1000) := '';
  p_mensaje      VARCHAR2(10000) := '';
  id_validador   NUMBER;
  new_validador  VARCHAR2(1000);
BEGIN
  new_validador := ' ';
  FOR i IN c_validadores_usos LOOP
    OPEN c_validadores_maestra(i.validador_estacion);
    FETCH c_validadores_maestra
      INTO id_validador;
    IF c_validadores_maestra%notfound THEN
      new_validador := new_validador || to_char(i.validador_estacion) || ' ' ||
                       i.descripcion || chr(10) || ' ';
    
      p_recibe_copia := 'dgiraldo@utryt.com.co';
      p_asunto       := 'VALIDADORES SIN REGISTRAR - CALI';
      p_mensaje      := 'A continuacion se presenta una lista de validadores que no encuentran registrados en la tabla maestra:' ||
                        chr(10) || chr(10) || new_validador || chr(10) ||
                        chr(10) ||
                        '--------------------------------------------' ||
                        chr(10) || chr(10) ||
                        '**********************NO RESPONDER - Mensaje Generado Automaticamente**********************';
    
    END IF;
  
    CLOSE c_validadores_maestra;
  END LOOP;

  --Envia mensaje de alerta
  IF new_validador != ' ' THEN
    sp_envia_correo(r_remite,
                    r_recibe,
                    p_recibe_copia,
                    p_asunto,
                    p_mensaje);
    dbms_output.put_line(p_mensaje);
  ELSE
    dbms_output.put_line('LOS VALIDADORES ACTUALIZADOS');
  END IF;

END prc_alerta_validadores_nuevos;
