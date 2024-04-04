PROCEDURE LIQUIDACIONRYT_USOS_SW_MIFARE(FECHA_LIQ DATE) IS

  CURSOR C_FECHAS_LIQUIDACION(FECHA_LIM IN DATE) IS
    SELECT A.DATE_LIQ_MIN, A.DATE_LIQ_MAX
      FROM MERCURY.TBL_LIQUIDACIONRYT_DATE A
     WHERE A.DATE_LIQ = FECHA_LIM
       AND A.USOS IS NULL;

  CURSOR C_REGISTROS(FECHA_MIN IN DATE, FECHA_MAX IN DATE) IS
    SELECT *
      FROM (WITH
           -- Consulta a tarjetas 
           TARJETA AS (SELECT c.ISS_ID, c.CD_ID, c.CRD_SNR, c.CRD_INTSNR
                         FROM MERCURY.CARDS c),
           -- Consulta a aplicaciones
           APLICACIONES AS (SELECT a.APP_ID, a.APP_DESCSHORT
                              FROM MERCURY.APPLICATIONS a),
           -- Consulta a sw_mifare_trx condicionado, se  agrega campos tp_id = 16 y convirtiendo valor real a pesos
           SW_MIFARE AS (SELECT sw.*, 16 AS TP_ID, (sw.FEE * 10) AS FAREVALUE
                           FROM MERCURY.sw_mifare_trx sw
                          WHERE TRUNC(SW.CU_DAT_INC_PUENTE) =
                                TO_DATE('06/06/6666', 'dd-mm-yyyy')
                            AND sw.CREATED >= FECHA_MIN
                            AND sw.CREATED <= FECHA_MAX
                            AND sw.BUS_ID NOT IN
                                (85001, 85002, 85003, 85004, 85005)
                            AND SW.TERMINAL_ID <> 1500030409
                            AND (sw.USE_TYPE = 0 OR sw.FEE > 0))
             SELECT sw.LINE_ID,
                    a.APP_DESCSHORT,
                    t.ISS_ID,
                    t.CD_ID,
                    t.CRD_SNR,
                    sw.APP_ID,
                    sw.TSN,
                    sw.USE_TYPE,
                    -- control de integracion 0 -> 'uso pago' 1 -> integracion
                    sw.TRX_DATE,
                    sw.CREATED,
                    sw.BUS_ID,
                    sw.TP_ID,
                    sw.FAREVALUE,
                    COUNT(1) AS QPAX
               FROM SW_MIFARE sw
               JOIN TARJETA t
                 ON (sw.UUID = t.CRD_INTSNR)
               JOIN APLICACIONES a
                 ON (sw.APP_ID = a.APP_ID)
              WHERE 1 = 1
              GROUP BY sw.LINE_ID,
                       a.APP_DESCSHORT,
                       t.ISS_ID,
                       t.CD_ID,
                       t.CRD_SNR,
                       sw.APP_ID,
                       sw.TSN,
                       sw.USE_TYPE,
                       sw.TRX_DATE,
                       sw.CREATED,
                       sw.BUS_ID,
                       sw.TP_ID,
                       sw.FAREVALUE;


  -- BUSCA USOS QUE NO TIENEN FECHA DE LIQUIDACION, ESTO SE DEBE AL MOMENTO DE TRANSMISION TENIAN LA MISMA FECHA, QUEDAN PENDIENTES PARA EL
  -- SIGUIENTE CICLO DE CONCILIACION

  CURSOR C_USOS_PENDIENTES IS
    SELECT *
      FROM MERCURY.TBL_LIQUIDACIONRYT_USOS A
     WHERE A.CLEARING_DATE IS NULL
       AND A.TP_ID NOT IN (999);

  R_USOSLIQUIDADOS MERCURY.TBL_LIQUIDACIONRYT_USOS%ROWTYPE;

  EXISTE_TRX_TSN NUMBER(1) := 3;

BEGIN
  FOR RCDATE IN C_FECHAS_LIQUIDACION(FECHA_LIM) LOOP
    --Abre y recorre CURSOR fechas de liquidacion 
    FOR RCLIQUIDACION IN C_REGISTROS(RCDATE.DATE_LIQ_MIN, RCDATE.DATE_LIQ_MAX) LOOP
    
      R_USOSLIQUIDADOS.LD_ID := RCLIQUIDACION.LD_ID;
    
      R_USOSLIQUIDADOS.APP_DESCSHORT := RCLIQUIDACION.APP_DESCSHORT;
    
      R_USOSLIQUIDADOS.ISS_ID := RCLIQUIDACION.ISS_ID;
    
      R_USOSLIQUIDADOS.CD_ID := RCLIQUIDACION.CD_ID;
    
      R_USOSLIQUIDADOS.CRD_SNR := RCLIQUIDACION.CRD_SNR;
    
      R_USOSLIQUIDADOS.APP_ID := RCLIQUIDACION.APP_ID;
    
      R_USOSLIQUIDADOS.CU_TSN := RCLIQUIDACION.TSN;
    
      R_USOSLIQUIDADOS.CU_ITG_CTR := RCLIQUIDACION.USE_TYPE;
    
      R_USOSLIQUIDADOS.CU_DATETIME := RCLIQUIDACION.TRX_DATE;
    
      R_USOSLIQUIDADOS.CU_DAT_INC_PUENTE := RCLIQUIDACION.CREATED;
    
      R_USOSLIQUIDADOS.VEH_ID := RCLIQUIDACION.BUS_ID;
    
      R_USOSLIQUIDADOS.CU_FAREVALUE := RCLIQUIDACION.FAREVALUE;
    
      R_USOSLIQUIDADOS.QPAX := RCLIQUIDACION.QPAX;
    
      R_USOSLIQUIDADOS.CLEARING_DATE := FECHA_LIM; -- fecha que se ejecuta el procedure
      R_USOSLIQUIDADOS.TP_ID         := RCLIQUIDACION.TP_ID;
    
      R_USOSLIQUIDADOS.CLEARING_REG := SYSDATE;
    
      /*****Control de duplicidad de ISS_ID, CD_ID, CRD_SNR, APP_ID y CU_TSN en la tabla TBL_LIQUIDACIONRYT_USOS*****/
      SELECT COUNT(1)
        INTO EXISTE_TRX_TSN
        FROM DUAL
       WHERE EXISTS (SELECT 1
                FROM MERCURY.TBL_LIQUIDACIONRYT_USOS A
               WHERE A.ISS_ID = RCLIQUIDACION.ISS_ID
                 AND A.CD_ID = RCLIQUIDACION.CD_ID
                 AND A.CRD_SNR = RCLIQUIDACION.CRD_SNR
                 AND A.APP_ID = RCLIQUIDACION.APP_ID
                 AND A.CU_TSN = RCLIQUIDACION.CU_TSN);
    
      IF EXISTE_TRX_TSN = 0 THEN
        INSERT INTO MERCURY.TBL_LIQUIDACIONRYT_USOS
        VALUES R_USOSLIQUIDADOS;
      
        COMMIT;
      END IF;
    END LOOP;
    UPDATE Mercury.sw_mifare_trx sw
       SET sw.cu_dat_inc_puente = SYSDATE
     WHERE sw.use_type = 0
       AND TRUNC(sw.cu_dat_inc_puente) = TO_DATE('06/06/66', 'dd-mm-yyyy')
       AND TRUNC(sw.created) >= TRUNC(RCDATE.DATE_LIQ_MIN) -- AND a.fecha_ws < TRUNC(SYSDATE)
       AND TRUNC(sw.trx_id) <> SYSDATE
    
     COMMIT;
  END LOOP;
  --- BUSCA TRANSACCIONES QUE NO TIENEN FECHA DE LIQUIDACION Y LAS ACTUALIZA CON EL CICLO ACTUAL

  FOR RPENDIENTE IN C_USOS_PENDIENTES LOOP
  
    IF RPENDIENTE.CU_DATETIME < FECHA_LIM THEN
    
      UPDATE MERCURY.TBL_LIQUIDACIONRYT_USOS A
         SET A.CLEARING_DATE = FECHA_LIM
       WHERE RPENDIENTE.ISS_ID = A.ISS_ID
         AND RPENDIENTE.CD_ID = A.CD_ID
         AND RPENDIENTE.CRD_SNR = A.CRD_SNR
         AND RPENDIENTE.APP_ID = A.APP_ID
         AND RPENDIENTE.CU_TSN = A.CU_TSN
         AND RPENDIENTE.CU_DATETIME = A.CU_DATETIME;
    
      COMMIT;
    END IF;
  END LOOP;
  --- ACTUALIZA FECHA DE LIQUIDACION, USOS QUE CORESPONDEN AL MISMO DIA CONCILIADO
  UPDATE MERCURY.TBL_LIQUIDACIONRYT_USOS A
     SET A.CLEARING_DATE = NULL
   WHERE TRUNC(A.CU_DATETIME) = A.CLEARING_DATE
     AND A.TP_ID NOT IN (999);

  COMMIT;
END LIQUIDACIONRYT_USOS_SW_MIFARE;
