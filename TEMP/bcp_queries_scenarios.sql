-------SCENARIO SECTION ----------  
--zapytanie pokazujace wszystkie Economic Scenarios  
--2ECOSC
use DB_NAME; \
select INTERNAL_NAME from ZOBJECTS \
 where OBJC_CLASS = 'ALMEcoScenario' \
   and INTERNAL_NAME like '%AAAA_PAR%' \
and (SITUATION_DATE =  (select max(SITUATION_DATE) from BSDATE) \
   or SITUATION_DATE = '00000000') \
 order by INTERNAL_NAME;


--zapytanie pokazujace wszystkie Super Scenarios 
--2SUPERSC
use DB_NAME; 
select INTERNAL_NAME from ZOBJECTS  \
 where OBJC_CLASS = 'ALMScenario' \
and (SITUATION_DATE =  (select max(SITUATION_DATE) from BSDATE) \
   or SITUATION_DATE = '00000000') \
and INTERNAL_NAME LIKE '%AAAA_PAR%' \
 order by INTERNAL_NAME;

--bps scenariusze
--2BPSC
use DB_NAME; \
select INTERNAL_NAME from ZOBJECTS \
where OBJC_CLASS='ALMBPSNewProductionScenario' \
and (SITUATION_DATE =  (select max(SITUATION_DATE) from BSDATE) \
   or SITUATION_DATE = '00000000') \
and INTERNAL_NAME LIKE '%AAAA_PAR%' \
 order by INTERNAL_NAME;

--behavioral scneariousz
--2BEHSC
use DB_NAME; \
select INTERNAL_NAME from ZOBJECTS \
where OBJC_CLASS='ALMBehavioralScenario' \
and (SITUATION_DATE =  (select max(SITUATION_DATE) from BSDATE) \
   or SITUATION_DATE = '00000000') \
and INTERNAL_NAME LIKE '%AAAA_PAR%' \
 order by INTERNAL_NAME;


