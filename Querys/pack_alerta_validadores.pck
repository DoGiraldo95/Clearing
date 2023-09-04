CREATE OR REPLACE PACKAGE pack_alerta_validadores AS
    PROCEDURE rt_prc_alerta_validadores;

    PROCEDURE rt_prc_alerta_validadores(date_use DATE);
  
    PROCEDURE rt_prc_alerta_validadores(periodo NUMBER); 

END pack_alerta_validadores;
/
CREATE OR REPLACE PACKAGE BODY PACK_ALERTA_VALIDADORES AS
 /*
  Autor: Diego Giraldo
  Version: 1.1
  Fecha: 31-05-2023
  Descripcion: Package que contiene las alertas :
               * Procedimiento que chequea los validadores que no han comunicado y envia correo de alerta.
               * Procedimiento que chequea los validadores que no estan registrados en la tabla tbl_validadores_mrc
               * Procedimiento Validadores con fecha de uso incorrecta
  Actualizado Por :  Diego Giraldo 
  Fecha: 07-06-2023           
  */
 ------------------------------------------Procedimiento Validadores sin Comunicar Usos -----------------------------------------
  PROCEDURE RT_PRC_ALERTA_VALIDADORES AS
    USOS_MIOCABLE     NUMBER;
 --Arreglo donde se insetan los validadores que no comunican
    TYPE A_VALIDADORES IS
      TABLE OF VARCHAR(10000) INDEX BY PLS_INTEGER;
    L_VALIDADORES     A_VALIDADORES;
    I                 NUMBER;
 --CURSOR DE VALIDADORES
    CURSOR C_VALIDADORES IS
      SELECT
        VAL.LD_ID,
        VAL.LD_DESC,
        VAL.VEH_ID
      FROM
        MERCURY.TBL_VALIDADORES_MRC VAL
      WHERE
        VAL.STATUS = 'A';
    LISTA_VALIDADORES VARCHAR2(10000);
 --Parametro de correo
    R_REMITE          VARCHAR2(1000) := 'dgiraldo@utryt.com.co';
    R_RECIBE          VARCHAR2(1000) := 'jbarrios@utryt.com.co, ddiez@utryt.com.co, jsanchez@utryt.com.co';
    P_RECIBE_COPIA    VARCHAR2(1000) := '';
    P_ASUNTO          VARCHAR2(1000) := '';
    P_MENSAJE         VARCHAR2(10000) := '';
  BEGIN
    I := 1;
    LISTA_VALIDADORES := ' ';
 --Loop que recorre el cursor de los validadores y verifica cuales tiene usos y han comunicado
    FOR VALIDADOR IN C_VALIDADORES LOOP
      SELECT
        COUNT(*) INTO USOS_MIOCABLE
      FROM
        MERCURY.CARDUSAGE           CU,
        MERCURY.LINEDETAILS         LD,
        MERCURY.USAGEDATATRIPMT     UDTM,
        MERCURY.USAGEDATASERVICE    UDS,
        MERCURY.USAGEDATAFILE       UDF,
        MERCURY.APPLICATIONS        APP,
        MERCURY.TBL_VALIDADORES_MRC VAL
      WHERE
        CU.UDTM_ID = UDTM.UDTM_ID
        AND UDTM.UDS_ID = UDS.UDS_ID
        AND UDS.UDF_ID = UDF.UDF_ID
        AND CU.CU_DATETIME >= TRUNC(SYSDATE - 1) --TO_DATE('24-08-2022 00:01', 'dd-mm-yyyy hh24:mi')
        AND CU.CU_DATETIME < TRUNC(SYSDATE) --TO_DATE('24-08-2022 23:59', 'dd-mm-yyyy hh24:mi')
        AND CU.CUT_ID = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
        AND NVL(CU.CU_PARTFARESEQNBR, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
        AND APP.APP_ID = CU.APP_ID
        AND LD.LD_ID = CU.LD_ID
        AND UDF.VEH_ID = VAL.VEH_ID
        AND ((UDF.TP_ID <> 67)
        OR (VAL.VEH_ID <> 9114))
        AND VAL.VEH_ID = VALIDADOR.VEH_ID;
      IF USOS_MIOCABLE <= 10 THEN
 --Inserta validadores sin usos en arreglo
        L_VALIDADORES(I) := VALIDADOR.LD_DESC
                                                                                 || '-'
                                                                                 || TO_CHAR(VALIDADOR.VEH_ID);
        LISTA_VALIDADORES := LISTA_VALIDADORES
                             || L_VALIDADORES(I)
                             || CHR(10)
                             || ' ';
        I := I + 1;
        P_RECIBE_COPIA := 'dgiraldo@utryt.com.co, gvelasquez@utryt.com.co, fholguin@utryt.com.co, jgiron@utryt.com.co, jbarrios@utryt.com.co, ccsiur@utryt.com.co';
        P_ASUNTO := 'VALIDADORES PENDIENTES POR COMUNICAR - CALI';
        P_MENSAJE := 'A continuacion se presenta una lista de validadores sin comunicar:'
                     || CHR(10)
                     || CHR(10)
                     || LISTA_VALIDADORES
                     || CHR(10)
                     || CHR(10)
                     || '--------------------------------------------'
                     || 'POR FAVOR REVISAR Y TENER EN CUENTA PARA LA LIQUIDACIÓN DIARIA'
                     || CHR(10)
                     || CHR(10)
                     || '**********************NO RESPONDER - Mensaje Generado Automaticamente**********************';
      END IF;
    END LOOP;
 --Envia mensaje de alerta
    IF LISTA_VALIDADORES != ' ' THEN
      SP_ENVIA_CORREO(R_REMITE, R_RECIBE, P_RECIBE_COPIA, P_ASUNTO, P_MENSAJE);
      DBMS_OUTPUT.PUT_LINE(P_MENSAJE);
    ELSE
      DBMS_OUTPUT.PUT_LINE('LOS VALIDADORES COMUNICARON');
    END IF;
  END RT_PRC_ALERTA_VALIDADORES;
 ------------------------------------------Procedimiento Validadores Nuevos  -----------------------------------------

 /*PROCEDURE prc_alerta_validadores_nuevos */

  PROCEDURE RT_PRC_ALERTA_VALIDADORES(
    DATE_USE DATE
  ) AS
    CURSOR C_VALIDADORES_MAESTRA(VALIDADOR USAGEDATAFILE.VEH_ID%TYPE) IS
      SELECT
        A.VEH_ID
      FROM
        TBL_VALIDADORES_MRC A
      WHERE
        A.STATUS = 'A'
        AND A.VEH_ID = VALIDADOR;
    CURSOR C_VALIDADORES_USOS IS
      SELECT
        DISTINCT (UDF.VEH_ID) VALIDADOR_ESTACION,
        LD.LD_DESC   DESCRIPCION,
        CU.CU_TPID,
        LD.LD_ID
      FROM
        MERCURY.CARDUSAGE        CU,
        MERCURY.LINEDETAILS      LD,
        MERCURY.USAGEDATATRIPMT  UDTM,
        MERCURY.USAGEDATASERVICE UDS,
        MERCURY.USAGEDATAFILE    UDF,
        MERCURY.APPLICATIONS     APP
      WHERE
        CU.UDTM_ID = UDTM.UDTM_ID
        AND UDTM.UDS_ID = UDS.UDS_ID
        AND UDS.UDF_ID = UDF.UDF_ID
        AND CU.CU_DATETIME >= TRUNC(DATE_USE - 1) --TO_DATE('24-08-2022 00:01', 'dd-mm-yyyy hh24:mi')
        AND CU.CU_DATETIME < TRUNC(DATE_USE) --TO_DATE('24-08-2022 23:59', 'dd-mm-yyyy hh24:mi')
        AND CU.CUT_ID = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
        AND NVL(CU.CU_PARTFARESEQNBR, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
        AND APP.APP_ID = CU.APP_ID
        AND LD.LD_ID = CU.LD_ID
        AND ((UDF.TP_ID <> 67)
        OR (UDF.VEH_ID <> 9114))
        AND LENGTH(UDF.VEH_ID) < 5
      GROUP BY
        UDF.VEH_ID, LD.LD_DESC, CU.CU_TPID, LD.LD_ID;
 --------------------------- VARIABLES -----------------------------------
    R_REMITE       VARCHAR2(1000) := 'dgiraldo@utryt.com.co';
    R_RECIBE       VARCHAR2(1000) := 'ddiez@utryt.com.co, jsanchez@utryt.com.co';
    P_RECIBE_COPIA VARCHAR2(1000) := '';
    P_ASUNTO       VARCHAR2(1000) := '';
    P_MENSAJE      VARCHAR2(10000) := '';
    ID_VALIDADOR   NUMBER;
    NEW_VALIDADOR  VARCHAR2(1000);
  BEGIN
    NEW_VALIDADOR := ' ';
    FOR I IN C_VALIDADORES_USOS LOOP
      OPEN C_VALIDADORES_MAESTRA(I.VALIDADOR_ESTACION);
      FETCH C_VALIDADORES_MAESTRA INTO ID_VALIDADOR;
      IF C_VALIDADORES_MAESTRA%NOTFOUND THEN
        NEW_VALIDADOR := NEW_VALIDADOR
                         || TO_CHAR(I.VALIDADOR_ESTACION)
                         || ' - '
                         || I.DESCRIPCION
                         || CHR(10)
                         || ' ';
        P_RECIBE_COPIA := 'jbarrios@utryt.com.co, dgiraldo@utryt.com.co';
        P_ASUNTO := 'VALIDADORES SIN REGISTRAR - CALI';
        P_MENSAJE := 'A continuacion se presenta una lista de validadores que no encuentran registrados en la tabla tbl_validadores_mrc:'
                     || CHR(10)
                     || CHR(10)
                     || NEW_VALIDADOR
                     || CHR(10)
                     || CHR(10)
                     || '--------------------------------------------'
                     || CHR(10)
                     || CHR(10)
                     || '**********************NO RESPONDER - Mensaje Generado Automaticamente**********************';
      END IF;
      CLOSE C_VALIDADORES_MAESTRA;
    END LOOP;
 --Envia mensaje de alerta
    IF NEW_VALIDADOR != ' ' THEN
      SP_ENVIA_CORREO(R_REMITE, R_RECIBE, P_RECIBE_COPIA, P_ASUNTO, P_MENSAJE);
      DBMS_OUTPUT.PUT_LINE(P_MENSAJE);
    ELSE
      DBMS_OUTPUT.PUT_LINE('LOS VALIDADORES ACTUALIZADOS');
    END IF;
  END RT_PRC_ALERTA_VALIDADORES;
 ------------------------------------------Procedimiento Validadores con fecha uso incorrecta  -----------------------------------------
  PROCEDURE RT_PRC_ALERTA_VALIDADORES(
    PERIODO NUMBER
  ) AS
    CURSOR DT_VALIDADOR IS
      SELECT
        DISTINCT (UDF.VEH_ID)
        || ' - '
        || LD.LD_DESC
        || ' -  SERIE : '
        || SUBSTR(UDF.UDF_FILENAME, 13, 5) AS USO_VALIDADOR
      FROM
        MERCURY.CARDUSAGE        CU,
        MERCURY.LINEDETAILS      LD,
        MERCURY.USAGEDATATRIPMT  UDTM,
        MERCURY.USAGEDATASERVICE UDS,
        MERCURY.USAGEDATAFILE    UDF,
        MERCURY.APPLICATIONS     APP
      WHERE
        CU.UDTM_ID = UDTM.UDTM_ID
        AND UDTM.UDS_ID = UDS.UDS_ID
        AND UDS.UDF_ID = UDF.UDF_ID
        AND TRUNC(CU.CU_DAT_INC_PUENTE) >= TO_DATE(SYSDATE - 1)
        AND TRUNC(CU.CU_DAT_INC_PUENTE) <= TO_DATE(SYSDATE)
        AND CU.CUT_ID = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
        AND NVL(CU.CU_PARTFARESEQNBR, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
        AND APP.APP_ID = CU.APP_ID
        AND LD.LD_ID = CU.LD_ID
        AND UDF.TP_ID <> 25
        AND CU.CU_ITG_CTR IS NULL
        AND ((CU.CU_FAREVALUE > 0)
        OR CU.APP_ID IN (920, 902)) -- Solo usos pagos 'BANBOGOTA - BANCOLOMBIA'
        AND (TO_CHAR(CU.CU_DATETIME, 'yyyy') <> PERIODO
        OR TRUNC(CU.CU_DATETIME) = TO_DATE(SYSDATE - 120)
        OR TRUNC(CU.CU_DATETIME) > TO_DATE(SYSDATE))
      GROUP BY
        LD.LD_DESC, UDF.VEH_ID, UDF.UDF_FILENAME;
 --------------------------- VARIABLES -----------------------------------
    R_REMITE       VARCHAR2(1000) := 'dgiraldo@utryt.com.co';
    R_RECIBE       VARCHAR2(1000) := 'ddiez@utryt.com.co, jdgomez@utryt.com.co, gvelasquez@utryt.com.co, sdiaz@utryt.com.co, jgiron@utryt.com.co, fmatta@utryt.com.co, ccsiur@utryt.com.co';
    P_RECIBE_COPIA VARCHAR2(1000) := '';
    P_ASUNTO       VARCHAR2(1000) := '';
    P_MENSAJE      VARCHAR2(10000) := '';
    LIST_VALIDADOR VARCHAR2(1000);
  BEGIN
    LIST_VALIDADOR := '';
    FOR VALIDADOR IN DT_VALIDADOR LOOP
      IF DT_VALIDADOR%FOUND THEN
        LIST_VALIDADOR := LIST_VALIDADOR
                          || TO_CHAR(VALIDADOR.USO_VALIDADOR)
                          || CHR(10)
                          || '';
        P_RECIBE_COPIA := 'jbarrios@utryt.com.co, dgiraldo@utryt.com.co, jsanchez@utryt.com.co';
        P_ASUNTO := 'VALIDADORES CON FECHA INCORRECTA';
        P_MENSAJE := 'Buen Día, '
                     || CHR(10)
                     || CHR(10)
                     || 'Solicitamos revisión  de los siguientes validadores :'
                     || CHR(10)
                     || CHR(10)
                     || LIST_VALIDADOR
                     || CHR(10)
                     || CHR(10)
                     || 'Los cuales están registrando transacciones con fecha incorrecta, esto puede afectar las integraciones o transbordo de los usuarios.'
                     || CHR(10)
                     || CHR(10)
                     || 'Nota: Por favor generar los casos requeridos con Centro de Control.'
                     || CHR(10)
                     || CHR(10)
                     || 'Quedamos atentos a sus comentarios.'
                     || CHR(10)
                     || CHR(10)
                     || '**********************NO RESPONDER - Mensaje Generado Automaticamente**********************';
      END IF;
    END LOOP;
 --Envia mensaje de alerta
    IF LIST_VALIDADOR != ' ' THEN
      SP_ENVIA_CORREO(R_REMITE, R_RECIBE, P_RECIBE_COPIA, P_ASUNTO, P_MENSAJE);
      DBMS_OUTPUT.PUT_LINE(P_MENSAJE);
    ELSE
      DBMS_OUTPUT.PUT_LINE('LOS VALIDADORES CON FECHA ACTUALIZADA');
    END IF;
  END RT_PRC_ALERTA_VALIDADORES;
END PACK_ALERTA_VALIDADORES;
/
