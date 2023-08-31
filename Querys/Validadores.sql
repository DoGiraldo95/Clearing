--------------------------------------------USOS COMUNICADOS-------------------------      
       
 SELECT TO_CHAR(a.cu_datetime, 'yyyy-mm-dd') fecha_uso, COUNT(*) FROM mercury.cardusage a
        WHERE a.cu_tpid IN (66, 67) ---> trasportadora
      --  AND TO_CHAR(a.cu_pbregdate, 'yyyy-mm-dd') >= '2023-05-16' 
        AND TO_CHAR(a.cu_pbregdate, 'yyyy-mm-dd') = '2023-05-17'
        GROUP BY TO_CHAR(a.cu_datetime, 'yyyy-mm-dd')
        ORDER BY 1;
         
--------------------------------------------USOS COMUNICADOS POR VALIDADOR -------------------------  
SELECT TO_CHAR(cu.cu_pbregdate, 'yyyy-mm-dd'), app.app_id, COUNT(*)
             cu.cu_farevalue
              FROM mercury.CARDUSAGE           cu,
                   mercury.linedetails         ld,
                   mercury.USAGEDATATRIPMT     udtm,
                   mercury.USAGEDATASERVICE    uds,
                   mercury.USAGEDATAFILE       udf,
                   mercury.applications        app,
                   mercury.tbl_validadores_mrc val
              WHERE CU.UDTM_ID = UDTM.UDTM_ID
              AND UDTM.UDS_ID = UDS.UDS_ID
              AND UDS.UDF_ID = UDF.UDF_ID
--               AND cu.cu_datetime = TO_DATE('01-04-2023 00:01', 'dd-mm-yyyy hh24:mi')
--               AND cu.cu_datetime = TO_DATE('16-05-2023 23:59', 'dd-mm-yyyy hh24:mi')
              AND TO_CHAR(cu.cu_pbregdate, 'yyyy-mm-dd') >= '2023-05-01' 
              AND TO_CHAR(cu.cu_pbregdate, 'yyyy-mm-dd') <= '2023-05-17' 
--               AND TO_CHAR (cu.cu_datetime, 'YYYY')   = '2023'  
              AND cu.cut_id = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
              AND NVL(cu.cu_partfareseqnbr, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
              AND app.app_id = cu.app_id
              AND ld.ld_id = cu.ld_id
              --AND cu.ld_id = val.ld_id
              AND udf.veh_id = val.veh_id
              AND udf.tp_id in (44, 45, 66, 67)--* 44- MIO Cable
              GROUP BY TO_CHAR(cu.cu_pbregdate, 'yyyy-mm-dd'), app.app_id;
          --    AND cu.app_id in (920, 902);     
/                

--------------------------------- PROCEDIMIENTO EmailVALIDADORES ----------------------
DECLARE
  usos_miocable NUMBER;

  --Arreglo donde se insetan los validadores que no comunican
  TYPE a_validadores IS TABLE OF VARCHAR(10000) INDEX BY PLS_INTEGER;
  l_validadores a_validadores;

  i NUMBER;

  --CURSOR DE VALIDADORES
  CURSOR c_validadores IS
    SELECT val.ld_id, val.ld_desc, val.veh_id
      FROM mercury.tbl_validadores_mrc val;

  lista_validadores VARCHAR2(10000);

  --Parametro de correo
  R_REMITE       VARCHAR2(1000) := 'dgiraldo@utryt.com.co'; --'ssquintero@utryt.com';
  R_RECIBE       VARCHAR2(1000) := 'jbarrios@utryt.com.co'; --'jjaramillo@utryt.com';
  P_RECIBE_COPIA VARCHAR2(1000) := '';
  P_ASUNTO       VARCHAR2(1000) := '';
  P_MENSAJE      VARCHAR2(10000) := '';

BEGIN
  i                 := 1;
  lista_validadores := ' ';
  --Loop que recorre el cursor de los validadores y verifica cuales tiene usos y han comunicado
  FOR validador in c_validadores LOOP
  
    SELECT COUNT(*)
      INTO usos_miocable
      FROM mercury.CARDUSAGE           cu,
           mercury.linedetails         ld,
           mercury.USAGEDATATRIPMT     udtm,
           mercury.USAGEDATASERVICE    uds,
           mercury.USAGEDATAFILE       udf,
           mercury.applications        app,
           mercury.tbl_validadores_mrc val
     WHERE CU.UDTM_ID = UDTM.UDTM_ID
       AND UDTM.UDS_ID = UDS.UDS_ID
       AND UDS.UDF_ID = UDF.UDF_ID
       AND cu.cu_datetime >= TRUNC(SYSDATE - 1) --TO_DATE('24-08-2022 00:01', 'dd-mm-yyyy hh24:mi')
       AND cu.cu_datetime < TRUNC(SYSDATE) --TO_DATE('24-08-2022 23:59', 'dd-mm-yyyy hh24:mi')
       AND cu.cut_id = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
       AND NVL(cu.cu_partfareseqnbr, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
       AND app.app_id = cu.app_id
       AND ld.ld_id = cu.ld_id
          --AND cu.ld_id = val.ld_id
       AND udf.veh_id = val.veh_id
       -- AND udf.tp_id in (44, 45, 66) --* 44- MIO Cable
       -- AND ((CU.cu_farevalue >= 0) or CU.app_id in (920, 902))
       AND ((udf.tp_id <> 67) OR (val.veh_id <> 9114))  
       AND val.veh_id = validador.veh_id;
  
    IF usos_miocable <= 10 THEN
      --Inserta validadores sin usos en arreglo
      l_validadores(i) := validador.ld_desc || '-' ||
                          TO_CHAR(validador.veh_id);
      lista_validadores := lista_validadores || l_validadores(i) || chr(10) || ' ';
      --DBMS_OUTPUT.PUT_LINE ('NO HA COMUNICADO ' || l_validadores(i));
      i := i + 1;
    
      P_RECIBE_COPIA := 'ddiez@utryt.com.co';
      P_Asunto       := 'VALIDADORES PENDIENTES POR COMUNICAR';
    
      P_Mensaje := 'A continuacion se presenta una lista de validadores sin comunicar:' ||
                   chr(10) || chr(10) || lista_validadores || chr(10) ||
                   chr(10) ||
                   '--------------------------------------------' ||
                   'POR FAVOR REVISAR Y TENER EN CUENTA PARA LA LIQUIDACIÓN DIARIA' ||
                   chr(10) || chr(10) ||
                   '**********************NO RESPONDER - Mensaje Generado Automaticamente**********************';
    END IF;
  END LOOP;

  --Envia mensaje de alerta
  IF lista_validadores != ' ' THEN
    Sp_Envia_Correo(R_Remite,
                    R_Recibe,
                    P_Recibe_Copia,
                    P_Asunto,
                    P_Mensaje);
    DBMS_OUTPUT.PUT_LINE(P_mensaje);
  ELSE
    DBMS_OUTPUT.PUT_LINE('LOS VALIDADORES COMUNICARON');
  END IF;
END;
