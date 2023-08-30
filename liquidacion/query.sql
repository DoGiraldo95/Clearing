select * from mercury.TBL_LOG_UTRYTOPCS
order by 2 ;

SELECT * from mercury.TBL_LOG_UTRYTOPCS_ERRORS;

select 
       a.CU_DATETIME
FROM
mercury.TBL_LIQUIDACIONRYT_USOS a
where 1=1
and a.CU_DATETIME = to_date(sysdate-1,'dd,mm,yyyy');