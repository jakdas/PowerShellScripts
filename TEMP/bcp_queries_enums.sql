-------ENUMERATIONS ------------
--ENUM_VALUES_FROM_PLIST
--2ENPL
use DB_NAME; \
select INTERNAL_NAME, \
substring(substring(PLIST_STRING,charindex('Members=(',PLIST_STRING)+9, \
charindex(')',substring(PLIST_STRING,charindex('Members=(',PLIST_STRING)+9,len(PLIST_STRING)))-1),1,100) ENUM_VALUES \
from ZOBJECTS Z  \
where OBJC_CLASS = 'ALMEnumeration' \
and PLIST_STRING IS NOT NULL  \
and SITUATION_DATE = (select MAX(SITUATION_DATE) FROM ZOBJECTS Z1 \
                     WHERE Z1.OID=Z.OID) \
and PLIST_STRING not like '%Members=()%' \
and PLIST_STRING not like '%TableName=%' \
and INTERNAL_NAME like '%AAAA_PAR%' \
order by INTERNAL_NAME;

--ENUMS_FROM_DB_LIST
--2ENDB
use DB_NAME; \
select INTERNAL_NAME, \
substring(PLIST_STRING,charindex('TableName=',PLIST_STRING)+10, \
charindex(';',substring(PLIST_STRING,charindex('TableName=',PLIST_STRING)+10,len(PLIST_STRING)))-1) TABLE_NAME \
from ZOBJECTS Z  \
where OBJC_CLASS = 'ALMEnumeration' \
and PLIST_STRING IS NOT NULL  \
and SITUATION_DATE = (select MAX(SITUATION_DATE) FROM ZOBJECTS Z1  \
                     WHERE Z1.OID=Z.OID)  \
and PLIST_STRING like '%TableName=%' \
and INTERNAL_NAME like '%AAAA_PAR%' \
order by INTERNAL_NAME;


