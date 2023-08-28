---------------------------------------------------------------------------------------------------------------------------------------------------------
--...:::::::CONSULTA DE TARJETAS-RECARGAS::::....
----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  T.CRD_SNR          AS TARJETA,
  T.PTD_AMOUNT *1000 AS VALOR_RECARGA,
  T.PTD_SALDO  *1000 AS VALOR_SALDO,
  T.PTD_REGDATE      AS FECHA_RECARGA,
  T.PD_CODE          AS COD_DISPO_RECARGA,
  D.PD_DESC          AS NOMBRE_DISPO_RECARGA,
  P.PP_SHORTDESC     AS PRODUCTO,
  p.PP_STATUS        AS ESTADO_TARJETA
  
FROM
  MERCURY.POS_TRANDT   T
  INNER JOIN MERCURY.POS_DEVICE D
  ON D.PD_CODE=T.PD_CODE
  INNER JOIN MERCURY.POS_PRODUCTS P
  ON T.PP_CODE=P.PP_CODE
 
WHERE
  1=1
  AND T.PTD_REGDATE >= TO_DATE('01-01-2023 00:01', 'dd/mm/yyyy hh24:mi:ss') ---------FECHA_BUSQUEDA(INICIAL)
  AND T.PTD_REGDATE <= TO_DATE('22-08-2023 23:59', 'dd/mm/yyyy hh24:mi:ss') ----------FECHA_BUSQUEDA(FINAL)
  AND T.CRD_SNR=4110637                                                      ----------SERIAL_TARJETA
 --and d.pd_code in (994)                                                    --------DISPO_RECARGA
 order by T.PTD_REGDATE DESC
 ;

-----------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------
 SELECT
  A.CU_DATETIME   AS FECHA_TRX,
  A.CLEARING_DATE AS FECHA_LIQUIDACION,
  A.CU_FAREVALUE  AS MONTO_TRX,
  A.CLEARING_DATE AS DIA_LIQUIDADO,
  A.CU_ITG_CTR    AS INTEGRACION,
  A.QPAX          AS CANTIDAD_USO,
  A.APP_DESCSHORT AS PRODUCTO,
  V.LD_DESC       AS DESCRIPCION,
  V.VEH_ID        AS VALIDADOR
 FROM MERCURY.TBL_LIQUIDACIONRYT_USOS  A
 INNER JOIN MERCURY.TBL_VALIDADORES_MRC V
 ON A.LD_ID=V.LD_ID
 WHERE 1=1 
 AND A.CLEARING_DATE >= TO_DATE('27-08-2023','DD/MM/YYYY HH24:MI:SS')      --FECHA DE LIQUIDACION
 AND A.CLEARING_DATE <= TO_DATE('28-08-2023','DD/MM/YYYY HH24:MI:SS')      --FECHA DELIQUIDACION  
 --AND A.CU_DATETIME = TO_DATE('','DD/MM/YYYY HH24:MI:SS')                 ------FECHA DE USO
 --AND V.VEH_ID = 5103                                                       ------VALIDADOR 
 order by A.CU_DATETIME DESC;
 ---------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------
-------------------------------------------------------
--------------------------------------------------------
--FECHA INCORRECTA--
---------------------------------------------------------
--------------------------------------------------------- 
 SELECT 
        CU.CU_DATETIME       AS FECHA_DE_USO,
        CU.CU_DAT_INC_PUENTE AS FECHA_PUENTE,
        VA.VEH_ID            AS ID_VALIDADOR,
        VA.LD_DESC           AS NOM_VALIDADOR,
        APP.APP_DESCLONG     AS PRODUCTO
 FROM       MERCURY.CARDUSAGE CU
 INNER JOIN MERCURY.TBL_VALIDADORES_MRC VA
 ON         VA.LD_ID=CU.LD_ID
 INNER JOIN MERCURY.APPLICATIONS APP 
 ON         APP.APP_ID=CU.APP_ID
 WHERE 1=1 
 AND CU.CU_DATETIME >= TO_DATE('28-08-2023 00:01','DD/MM/YYYY HH24:MI:SS')     
 AND CU.CU_DATETIME <= TO_DATE('28-08-2023 23:59','DD/MM/YYYY HH24:MI:SS') 
 AND VA.VEH_ID = 5103  
 --AND CU.CU_DAT_INC_PUENTE = TO_DATE('06-06-6666','DD/MM/YYYY')
ORDER BY CU.CU_DATETIME DESC;














 