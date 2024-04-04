DECLARE

  CURSOR C_USAGEDATAFILES IS
    SELECT CU.PB_ID, CU.DLF_ID, UDF_ID, COUNT(1) TRANSCOUNT
      FROM CARDUSAGE CU
      JOIN DEVICELOGFILES DLF
        ON CU.PB_ID = DLF.PB_ID
       AND CU.DLF_ID = DLF.DLF_ID
      JOIN DEVICELOGMT DMT
        ON DLF.PB_ID = DMT.PB_ID
       AND DLF.DLF_ID = DMT.DLF_ID
      JOIN USAGEDATAFILE UDF
        ON UDF.PB_ID = CU.PB_ID
       AND UDF.DV_ID = DMT.DV_ID
       AND UDF.UDF_FILESEQ = DLF.DLF_FILESEQNBR
       AND UDF.UDF_CONNDATE = DLF.DLF_DTCONN
     WHERE CUT_ID IN (1, 5)
       AND CU_DAT_INC_PUENTE =
           TO_DATE('06/06/6666 00:00:00', 'DD/MM/YYYY HH24:MI:SS')
       AND UDF.UDF_RECEIVEDATE >= TRUNC(SYSDATE - 1) --AGREGADO 26/10/2022 POR CLEARING. SOLUCION A PROBLEMA DE INDICE. TIEMPO DE PROSAMIENTO > 40 MINUTOS
       AND (APP_ID, APP_ISS_ID) IN
           (SELECT APP_ID, ISS_ID
              FROM APPLICATIONS
             WHERE AF_ID IN (27, 28, 30))
       AND CU.APP_ID <> 1023
     GROUP BY CU.PB_ID, CU.DLF_ID, UDF_ID;

  RUSAGEDATAFILE C_USAGEDATAFILES%ROWTYPE;

BEGIN

  BEGIN
    OPEN C_USAGEDATAFILES;
    FETCH C_USAGEDATAFILES
      INTO RUSAGEDATAFILE;
  
    WHILE (C_USAGEDATAFILES%FOUND) LOOP
      BEGIN
        UPDATE CARDUSAGE
           SET CU_DAT_INC_PUENTE = SYSDATE
         WHERE PB_ID = RUSAGEDATAFILE.PB_ID
           AND DLF_ID = RUSAGEDATAFILE.DLF_ID
           AND CUT_ID IN (1, 5)
           AND (APP_ID, APP_ISS_ID) IN
               (SELECT APP_ID, ISS_ID
                  FROM APPLICATIONS
                 WHERE AF_ID IN (27, 28, 30))
           AND APP_ID <> 1023 -- REVISAR
           AND CU_DAT_INC_PUENTE =
               TO_DATE('06-06-6666 00:00:00', 'DD/MM/YYYY HH24:MI:SS');
        --COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          DBMS_OUTPUT.PUT_LINE('ERRO EXPORT USAGE DATAFILE (' || 'UDF_ID' ||
                               RUSAGEDATAFILE.UDF_ID || ') ' || SQLERRM);
      END;
      FETCH C_USAGEDATAFILES
        INTO RUSAGEDATAFILE;
    END LOOP;
       DBMS_OUTPUT.PUT_LINE('# rows updated: ' || SQL%ROWCOUNT);
    CLOSE C_USAGEDATAFILES;
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('ERRO ON EXPORT DATAUSAGES ' || SQLERRM);
  END;
END;
