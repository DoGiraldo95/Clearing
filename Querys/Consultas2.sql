SELECT ld.ld_descshort AS ESTACION,
       app.app_descshort AS PRODUCTO, --> 900 - 903 - 920 - 500 IS ('BANCO BOGOTA', 'ESCOLAR', 'ESTUDIANTE_SBDO', 'COMUN')
       cu.cu_itg_ctr AS INTEGRACION,
       to_char(cu.cu_datetime, 'DD/MM/YYYY') AS FECHA,
       to_char(cu.cu_datetime, 'DD') AS DIA,
       to_char(cu.cu_datetime, 'MM') AS MES,
       to_char(cu.cu_datetime, 'hh24') AS HORA,
       to_char(cu.cu_datetime, 'hh24:mi:ss') AS HORA_LARGA,
       udf.veh_id as VEH_ID,
       cu.cu_farevalue AS CU_FAREVALUE,
       cu.cu_dat_inc_puente,
       COUNT(1) AS QPAX
  FROM mercury.CARDUSAGE        cu,
       mercury.linedetails      ld,
       mercury.USAGEDATATRIPMT  udtm,
       mercury.USAGEDATASERVICE uds,
       mercury.USAGEDATAFILE    udf,
       mercury.applications     app
 WHERE 1 = 1
   AND CU.UDTM_ID = UDTM.UDTM_ID
   AND UDTM.UDS_ID = UDS.UDS_ID
   AND UDS.UDF_ID = UDF.UDF_ID
   AND cu.cu_datetime >= to_Date('16-11-2020 00:01', 'dd-mm-yyyy hh24:mi') --trunc (sysdate -1)
   AND cu.cu_datetime <= to_Date('30-11-2020 23:59', 'dd-mm-yyyy hh24:mi') --trunc (sysdate)
      
   AND cu.cut_id = 1 -- Tipos de uso -> 1: Passenger use, 5: On-board sale
   AND NVL(cu.cu_partfareseqnbr, 0) <> 2 -- Solo cuenta una vez las transacciones que afectan las dos cuentas de la tarjeta.
   AND app.app_id = cu.app_id
   AND ld.ld_id = cu.ld_id
      --AND     udf.tp_id not in (25,44)
   AND udf.tp_id = 44 --
   AND ((CU.cu_farevalue > 0 or cu.cu_itg_ctr is not null) or
       CU.app_id in (920, 902) OR app.af_id = 30) -- Solo usos pagos y funcionario

 GROUP BY ld.ld_descshort,
          app.app_descshort,
          cu.cu_itg_ctr,
          to_char(cu.cu_datetime, 'DD/MM/YYYY'),
          to_char(cu.cu_datetime, 'DD'),
          to_char(cu.cu_datetime, 'MM'),
          to_char(cu.cu_datetime, 'hh24'),
          to_char(cu.cu_datetime, 'hh24:mi:ss'),
          udf.veh_id,
          cu.cu_farevalue,
          cu.cu_dat_inc_puente;
