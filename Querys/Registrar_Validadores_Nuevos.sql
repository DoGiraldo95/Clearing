DECLARE
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
            UDF.TP_ID,
            LD.LD_ID,
            LD.LD_DESC DESCRIPCION,
            CU.CU_TPID
        FROM
            MERCURY.CARDUSAGE CU,
            MERCURY.LINEDETAILS LD,
            MERCURY.USAGEDATATRIPMT UDTM,
            MERCURY.USAGEDATASERVICE UDS,
            MERCURY.USAGEDATAFILE UDF,
            MERCURY.APPLICATIONS APP
        WHERE
            CU.UDTM_ID = UDTM.UDTM_ID
            AND UDTM.UDS_ID = UDS.UDS_ID
            AND UDS.UDF_ID = UDF.UDF_ID
            AND CU.CU_DATETIME >= TRUNC(SYSDATE-1) --TO_DATE('24-08-2022 00:01', 'dd-mm-yyyy hh24:mi')
            AND CU.CU_DATETIME < TRUNC(SYSDATE) --TO_DATE('24-08-2022 23:59', 'dd-mm-yyyy hh24:mi')
            AND CU.CUT_ID = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
            AND NVL(CU.CU_PARTFARESEQNBR, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
            AND APP.APP_ID = CU.APP_ID
            AND LD.LD_ID = CU.LD_ID
            AND ((UDF.TP_ID <> 67)
            OR (UDF.VEH_ID <> 9114))
            AND LENGTH(UDF.VEH_ID) < 5
        GROUP BY
            UDF.TP_ID, LD.LD_ID, UDF.VEH_ID, LD.LD_DESC, CU.CU_TPID, LD.LD_ID;
    ID_VALIDADOR NUMBER;
BEGIN
    FOR I IN C_VALIDADORES_USOS LOOP
        OPEN C_VALIDADORES_MAESTRA(I.VALIDADOR_ESTACION);
        FETCH C_VALIDADORES_MAESTRA INTO ID_VALIDADOR;
        IF C_VALIDADORES_MAESTRA%NOTFOUND THEN
            INSERT INTO TBL_VALIDADORES_MRC (
                TP_ID,
                LD_ID,
                LD_DESC,
                VEH_ID,
                STATUS
            ) VALUES (
                I.TP_ID,
                I.LD_ID,
                I.DESCRIPCION,
                I.VALIDADOR_ESTACION,
                'A'
            );
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('validadores insertados');
        END IF;
        CLOSE C_VALIDADORES_MAESTRA;
    END LOOP;
END;