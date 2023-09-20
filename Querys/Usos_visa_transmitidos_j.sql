----------------------------------------------------
--:::usos visa transmitidos::::
-----------------------------------------------------
select * from Mercury.tbl_trx_utrytopcs
-------------------------------------------------------

SELECT     a.route_id       ,
           a.date_created as fecha_creacion,
           a.device_id    as serial_validador,
           a.entry_date   as fecha_entrada,     
                   
case       a.metrocali
when       '0'
then       'ESTACION'-----bus   
else       a.metrocali
end     as descroip ,
case       a.short_txt
when   'null'
then   'BUS_NO_REGISTRA'
else   a.short_txt
end  as estacion ,
count  (*) as qtrx   
FROM MERCURY.TBL_TRX_UTRYTOPCS a
where 1=1
and  a.date_created >= to_date('20-09-2023 00:01:00','dd-mm-yyyy hh24:mi:ss')
and  a.date_created <= to_date('20-09-2023 13:20:00','dd-mm-yyyy hh24:mi:ss')

group by a.route_id,
             a.short_txt,a.route_id,
             a.date_created,
             a.device_id,
             a.entry_date,
             a.metrocali
order by  a.date_created
;

-------------------------------------------------------------------------------
::::::::::::::::::::::::CONSULTA DE USOS POR VALIDADOR ESTACIONES::::::::::::::::::::::::::

---------------------------------------------------------------------------------

SELECT
  TRUNC(CU.CU_DATETIME)                                                                                                                                                                                                                          AS FECHA_USO,
  LD.LD_DESC                                                                                                                                                                                                                                     AS ESTACION,
  UDF.VEH_ID                                                                                                                                                                                                                                     AS VEH_ID,
  CASE
    WHEN TO_NUMBER(TO_CHAR(CU.CU_DAT_INC_PUENTE, 'hh24')) > 7 THEN
      TRUNC(CU.CU_DAT_INC_PUENTE)
    ELSE
      CASE
        WHEN TRUNC(CU.CU_DAT_INC_PUENTE) = TRUNC(CU.CU_DATETIME) THEN
          TRUNC(CU.CU_DAT_INC_PUENTE)
        ELSE
          TRUNC(CU.CU_DAT_INC_PUENTE)-1
      END
  END AS FECHA_DIALIQ,
  COUNT(1)                                                                                                                                                                                                                                       AS CANTIDAD_USOS
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
 --AND     cu.cu_datetime >= TO_DATE('22-08-2022 00:01', 'dd-mm-yyyy hh24:mi')
 --AND     cu.cu_datetime <= TO_DATE('22-08-2022 23:59', 'dd-mm-yyyy hh24:mi')
  AND CU.CU_DAT_INC_PUENTE >= TO_DATE('18-09-2023 07:59:00', 'dd-mm-yyyy hh24:mi:ss') --Fecha Tabla Puente --6am, 12m, 4pm-- dos dias antes de la fecha de proceso (Actual)
  AND CU.CU_DAT_INC_PUENTE <= TO_DATE('20-09-2023 07:59:00', 'dd-mm-yyyy hh24:mi:ss') --Un dia despues de la fecha consulta de transacciones (Evaluacion de transacciones)
  AND CU.CUT_ID = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale------------------------------
  AND NVL(CU.CU_PARTFARESEQNBR, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
  AND APP.APP_ID = CU.APP_ID
  AND LD.LD_ID = CU.LD_ID
 --  AND     udf.tp_id not in (16)--udf.tp_id not in (25,44) --*** 44- MIO Cable empresa
  AND UDF.VEH_ID IN (1304) ----VALIDADOR
  AND CU.CU_ITG_CTR IS NULL
  AND ((CU.CU_FAREVALUE > 0)
  OR CU.APP_ID IN (920, 902)) -- Solo usos pagos 'BANBOGOTA - BANCOLOMBIA'
 --AND  ((CU.cu_farevalue >= 0 or cu.cu_itg_ctr is not null) or CU.app_id in (920,902) OR app.af_id = 30 )---- Todos los productos
GROUP BY
  LD.LD_DESC, APP.APP_DESCSHORT, CU.CU_ITG_CTR, TRUNC(CU.CU_DATETIME), TRUNC(CU.CU_DAT_INC_PUENTE), APP.APP_DESCSHORT, UDF.VEH_ID, TO_CHAR(CU.CU_DAT_INC_PUENTE, 'hh24'), TRUNC(UDF.UDF_RECEIVEDATE), TO_CHAR(UDF.UDF_RECEIVEDATE, 'hh24'), CU.CU_FAREVALUE;
