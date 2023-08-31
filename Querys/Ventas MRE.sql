SELECT trunc(PTDT.PTD_REGDATE) FECHA,
       PTDT.CD_ID DISENO_ID,
       CRDDG.CD_DESC DISENO,
       PTMT.TP_ID EMPRESA,
       TP.TP_DESC NOMBRE_RED,
       PD.SD_ID ID_POS,
       PD.PD_DESC NOMBRE_POS,
       sum(PTDT.PTD_TRANPRICE * 1000) AS VALOR,
       --PTDT.PTD_SALDO * 1000 AS SALDO,
       
       count(*) QPAX
  FROM mercury.POS_TRANMT         PTMT,
       mercury.POS_DEVICE         PD,
       mercury.POS_PRODUCTS       PP,
       mercury.POS_TRANDT         PTDT,
       MERCURY.CARDSXUSERS        CRDXUSR,
       MERCURY.USERS              USR,
       MERCURY.CARDDESIGN         CRDDG,
       MERCURY.TRANSPORTPROVIDERS TP,
       -- MERCURY.APPLICATIONS              APP,
       mercury.Tbl_Pos_Locations_Station PLS
 WHERE PD.pd_code = PLS.pd_code
   AND PTDT.PD_CODE = PD.PD_CODE
   AND PP.PP_CODE = PTDT.PP_CODE
   AND PTDT.PTM_TRANNBR = PTMT.PTM_TRANNBR
   AND PTDT.PD_CODE = PTMT.PD_CODE
   
      -- AND ptmt.TP_ID in (16, 44)
      --AND PD.SD_ID IN (739)
   and (PTDT.pp_code in (24) or PTDT.ptd_conf_date is not null)
      --AND PD.PD_DESC like '%EXT%'    
   AND PTDT.ISS_ID = CRDXUSR.ISS_ID
   AND PTDT.CD_ID = CRDXUSR.CD_ID
   AND PTDT.CRD_SNR = CRDXUSR.CRD_SNR
   AND CRDXUSR.USR_ID = USR.USR_ID
   AND CRDDG.CD_ID = PTDT.CD_ID
   AND PTMT.TP_ID = TP.TP_ID
/*   AND pd.sd_id = 751
*/--AND PTDT.PTD_SALDO >= 20.00
--AND PTDT.PTD_APPID = APP.APP_ID
   AND PTDT.PTD_REGDATE >=
       TO_DATE('&fecha_ini 00:01', 'DD-MM-YYYY HH24:MI')
   AND PTDT.PTD_REGDATE <=
       TO_DATE('&fecha_fin 23:59', 'DD-MM-YYYY HH24:MI')
   AND PTDT.PTD_STATUS = 'A'
   AND PD.PL_CODE IN (13, 14, 15)

 GROUP BY PTDT.CD_ID,
          CRDDG.CD_DESC,
          PTMT.TP_ID,
          TP.TP_DESC,
          PD.SD_ID,
          PD.PD_DESC,
          PTDT.PTD_TRANPRICE * 1000,
          --to_char (PTDT.PTD_REGDATE, 'dd/mm/yyyy')
          trunc(PTDT.PTD_REGDATE)

 order by 1 asc;
