-------- PROCESS SECTION
--zapytanie pokazujace wszystkie procesy, uporzadkowane wg RANK
--2PROCESSES
use DB_NAME; \
select DISTINCT RANK,INTERNAL_NAME from ZOBJECTS \
 where OBJC_CLASS = 'ALMTaskPreparedGroup' \
and (SITUATION_DATE = (select max(SITUATION_DATE) from BSDATE) \
    or SITUATION_DATE = '00000000') \
and INTERNAL_NAME like '%AAAA_PAR%' \
order by RANK,INTERNAL_NAME;


--Wyciaganie taskow dla danego procesu
--2TASKSINPROCESS
use DB_NAME; \
select z1.RANK,z2.INTERNAL_NAME AS TASK_NAME, \
substring(z2.PLIST_STRING,charindex('OriginalAssistantName',z2.PLIST_STRING)+22,len(z2.PLIST_STRING) \
                        -charindex('OriginalAssistantName',z2.PLIST_STRING)-23) as ASSISTANT_NAME \
 from ZOBJECTS as z2, ZOBJECTS as z1 \
  where z1.INTERNAL_NAME = 'AAAA_PAR' \
    and z1.PLIST_STRING like '%Tasks=(%' + z2.OID + '%' \
    and z1.SITUATION_DATE =  (select max(SITUATION_DATE) from BSDATE) \
    and z1.SITUATION_DATE = z2.SITUATION_DATE \
  order by charindex(z2.OID,z1.PLIST_STRING);

--Wyswietla liste procesow uzywajacych danego asystenta
--2ASSISTANT
use DB_NAME; \
select distinct
substring(z2.PLIST_STRING,charindex('OriginalAssistantName',z2.PLIST_STRING)+22,len(z2.PLIST_STRING) \
 -charindex('OriginalAssistantName',z2.PLIST_STRING)-23) as ASSISTANT_NAME, \
z2.INTERNAL_NAME AS TASK_NAME,process.INTERNAL_NAME PROCESS_NAME,process.RANK \
from ZOBJECTS as z2, ZOBJECTS as process \
 where z2.OBJC_CLASS = 'ALMTaskPrepared' \
 and process.OBJC_CLASS = 'ALMTaskPreparedGroup' \
 and process.PLIST_STRING like '%Tasks=(%' + z2.OID + '%' \
 and process.SITUATION_DATE=(select max(SITUATION_DATE) from BSDATE) \
 and z2.SITUATION_DATE=(select max(SITUATION_DATE) from BSDATE) \
and substring(z2.PLIST_STRING,charindex('OriginalAssistantName',z2.PLIST_STRING)+22,len(z2.PLIST_STRING) \
-charindex('OriginalAssistantName',z2.PLIST_STRING)-23) like '%AAAA_PAR%' \
order by ASSISTANT_NAME,TASK_NAME;
