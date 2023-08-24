select * from cpt_analisis.tbl_nv_BANBOGOTA;
/
select * from CPT_ANALISIS.TBL_NOVEDADES_BANBOGOTA
where 1               =1
and TRUNC(NV_PRCDATE) = TRUNC(sysdate)
and file_origen is null;
/
select * from CPT_ANALISIS.TBL_NOVEDADES_BANBOGOTA
--update CPT_ANALISIS.TBL_NOVEDADES_BANBOGOTA SET FILE_ORIGEN = 'NVT0220221126040026.txt' -- colocar DIARIAMENTE el nombre del .txt procesado
where 1               =1
and TRUNC(NV_PRCDATE) = TRUNC(sysdate)
and file_origen is null;

commit;
/
select ROWID, A.* from CPT_ANALISIS.TBL_NOVEDADES_BANBOGOTA A
where 1=1
and NV_REGDATE >= to_date ('29-04-2022 00:00','dd-mm-yyyy hh24:mi')
and NV_REGDATE <= to_date ('29-04-2022 23:59','dd-mm-yyyy hh24:mi')
--and file_origen = 'NVT0220210126040014.txt'
and CRD_INTSNR = '002975447423'
order by NV_REGDATE desc
;
/
--Bancolombia
select 
/*trunc (nv_regdate) as fecha,
count(*) as cantidad*/*
--delete
from cpt_analisis.Tbl_novedades_bancolombia a
where a.nv_regdate >= TO_DATE('27-04-2022 00:01', 'dd-mm-yyyy hh24:mi')
  AND a.nv_regdate <= TO_DATE('27-04-2022 23:59', 'dd-mm-yyyy hh24:mi')
--group by trunc(nv_regdate)
--order by 1 asc  
;
/
-------MODIFICACION DE FECHA DE LAS NOVEDADES BANCOLOMBIA-----
select * from cpt_analisis.tbl_novedades_bancolombia
--UPDATE cpt_analisis.tbl_novedades_bancolombia set NV_REGDATE = sysdate -2, NV_PRCDATE = SYSDATE -2, NV_ACKDATE = SYSDATE -2
where 1               =1
and TRUNC(NV_PRCDATE) = TRUNC(sysdate)
and  file_origen = 'NVC1520221122214315';

--------NOVEDADES BANCOLOMBIA--------
/
select * from cpt_analisis.tbl_nv_BANCOLOMBIA;
/
select * from CPT_ANALISIS.TBL_NOVEDADES_BANCOLOMBIA
--update CPT_ANALISIS.TBL_NOVEDADES_BANCOLOMBIA SET FILE_ORIGEN = 'NVC1520220223151025.txt' -- colocar DIARIAMENTE el nombre del .txt procesado
where 1               =1
and TRUNC(NV_PRCDATE) = to_date ('21/07/2022','dd/mm/yyyy') --TRUNC(sysdate)
--and file_origen is null
;


SELECT Lpad(Usrdoc_Number,16,'0') AS A1,
    Lpad(Crd_Intsnr,12,'0')          AS A2,
    Lpad(REPLACE(Usr_Name,',',' '),30,' ')       AS A3,
    Lpad(replace(Usr_Lastname_1,',',' '),20,' ')      AS A4,
    Lpad(REPLACE(Usr_Lastname_2,',',' '),20,' ') AS A5,
    Lpad(replace(Usradd_Address,',',' '),40,' ')      AS A6,
    Lpad(Nv_Statusret,2,' ')         AS A7
  From Cpt_Analisis.Tbl_Novedades_Banbogota
-- Where Trunc( Nv_Prcdate) = To_Date('28/03/2014','dd/mm/yyyy')
 WHERE Nv_Prcdate >= to_date ('29/04/2022','dd/mm/yyyy')
  AND Nv_Prcdate    < to_date ('29/04/2022','dd/mm/yyyy') + 1
  
  
select count (*) from cpt_analisis.tbl_novedades_banbogota
where trunc (nv_regdate) = trunc (sysdate -1) 

select * from cpt_analisis.tbl_novedades_bancolombia
where trunc (nv_regdate) = trunc (sysdate -1) 
