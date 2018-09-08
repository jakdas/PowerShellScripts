-------- PROCESS CONTRACTS
--zapytanie pokazujace ile kontraktow zostalo zaimportowanych na ostatnia date Situation Date
--2COUNTCONTRACTS
use DB_NAME;  \
select SOURCE_SYSTEM_REF, \
       case STOCK_TYPE_ENUM  \
           WHEN 4 THEN 'Stock' \
           WHEN 5 THEN 'Aggregated' \
           WHEN 6 THEN 'Replicated' \
           WHEN 7 THEN 'NewBusiness' \
           ELSE        'NULL' \
       end as STOCK_TYPE, \
       count(*) as CARDINALITY from CONTRACT \
 WHERE ('AAAA_PAR'='' AND SITUATION_DATE=(select MAX(SITUATION_DATE) from BSDATE) \
      OR SITUATION_DATE = 'AAAA_PAR') \
 GROUP BY SOURCE_SYSTEM_REF, STOCK_TYPE_ENUM \
 ORDER BY SOURCE_SYSTEM_REF,STOCK_TYPE_ENUM ;

--zapytanie pokazujace podstawowe informacje o kontraktach na ostatnia date Situation Date dla danego Source Systemu.
--2CONTRACTS
use DB_NAME; \
select c.SOURCE_CONTRACT_REF AS CONTRACT_REF,c.CONTRACT_ID as ID,ints.INTEREST_STREAM_ID AS STR_ID, \
       at.DESCRIPTION as AMORT,ints.CURRENCY as CCY, c.CONTRACT_STRUCTURE as STRUCTURE, CAST(c.ORIGIN_DATE AS VARCHAR(10)) as ORIGIN,  \
       CAST(c.MATURITY_DATE AS VARCHAR(10)) as MATURITY, cast((ints.PRINCIPAL) as decimal(16,2)) PRINCIPAL,cast((c.BALANCE) as decimal(16,2)) BALANCE,ints.INTEREST_RATE_INDEX_REF as INDEX_, \
       case when CLIENT_RATE_SPREAD is null then 'NULL'  \
                                            else concat(' ',str(ints.CLIENT_RATE_SPREAD*100,4,2),'%')   \
       end as SPREAD, \
       case when FIXED_RATE is null then 'NULL'  \
                                    else concat(' ',str(ints.FIXED_RATE,4,2),'%')  \
       end AS FIX_RATE \
from CONTRACT c, AMORTIZATION_TYPE at, \
CONTRACT_EXT ce LEFT OUTER JOIN INTEREST_STREAM ints ON ce.CONTRACT_ID=ints.CONTRACT_ID \
   and ce.SITUATION_DATE = ints.SITUATION_DATE \
where ('CCCC_PAR' = '' AND c.SITUATION_DATE=(select MAX(SITUATION_DATE) from BSDATE) \
     OR c.SITUATION_DATE = 'CCCC_PAR') \
and at.AMORTIZATION_TYPE_ENUM = ints.AMORTIZATION_TYPE_ENUM \
and c.SITUATION_DATE = ce.SITUATION_DATE \
and c.CONTRACT_ID=ce.CONTRACT_ID \
and c.SOURCE_CONTRACT_REF like '%BBBB_PAR%' \
and c.SOURCE_SYSTEM_REF='AAAA_PAR' \
ORDER BY c.CONTRACT_ID;

--zapytanie pokazujace podstawowe informacje o kontraktach dla danego Replication Segment Name
--2SEGMENTCONTR
use DB_NAME; \
select c.SOURCE_CONTRACT_REF AS CONTRACT_REF,c.CONTRACT_ID,ce.ALM_REPLICATIONSEGMENTNAME as SEG_NAME, \
       c.REPLICATION_PART_NAME as PART_NAME, at.DESCRIPTION as AMORT_TYPE,ints.CURRENCY as CCY, \
       cast(c.ORIGIN_DATE as VARCHAR(10)) as ORIGIN, cast(c.MATURITY_DATE as VARCHAR(10)) as MATURITY, c.BALANCE, c.PRINCIPAL \
from CONTRACT c, AMORTIZATION_TYPE at, \
CONTRACT_EXT ce LEFT OUTER JOIN INTEREST_STREAM ints ON ce.CONTRACT_ID=ints.CONTRACT_ID \
   and ce.SITUATION_DATE = ints.SITUATION_DATE \
where ('BBBB_PAR' = '' AND c.SITUATION_DATE=(select MAX(SITUATION_DATE) from BSDATE) \
      OR c.SITUATION_DATE = 'BBBB_PAR') \
and at.AMORTIZATION_TYPE_ENUM = ints.AMORTIZATION_TYPE_ENUM \
and c.SITUATION_DATE = ce.SITUATION_DATE \
and c.CONTRACT_ID=ce.CONTRACT_ID \
and ce.ALM_REPLICATIONSEGMENTNAME='AAAA_PAR' \
and (c.STOCK_TYPE_ENUM =4 OR c.STOCK_TYPE_ENUM is null) \
order by c.CONTRACT_ID,PART_NAME,ORIGIN, MATURITY;

--zapytanie pokazujace podstawowe informacje o zreplikowanych kontraktach dla danego Replication Segment Name
--2SEGMENTREPLCONTR
use DB_NAME; \
select c.SOURCE_CONTRACT_REF AS CONTRACT_REF,c.CONTRACT_ID,ce.ALM_REPLICATIONSEGMENTNAME as SEG_NAME, \
       c.REPLICATION_PART_NAME as PART_NAME, at.DESCRIPTION as AMORT_TYPE,ints.CURRENCY as CCY, \
       cast(c.ORIGIN_DATE as VARCHAR(10)) as ORIGIN, cast(c.MATURITY_DATE as VARCHAR(10)) as MATURITY, c.BALANCE, c.PRINCIPAL \
from CONTRACT c, AMORTIZATION_TYPE at, \
CONTRACT_EXT ce LEFT OUTER JOIN INTEREST_STREAM ints ON ce.CONTRACT_ID=ints.CONTRACT_ID \
   and ce.SITUATION_DATE = ints.SITUATION_DATE \
where ('BBBB_PAR' = '' AND c.SITUATION_DATE=(select MAX(SITUATION_DATE) from BSDATE) \
      OR c.SITUATION_DATE = 'BBBB_PAR') \
and at.AMORTIZATION_TYPE_ENUM = ints.AMORTIZATION_TYPE_ENUM \
and c.SITUATION_DATE = ce.SITUATION_DATE \
and c.CONTRACT_ID=ce.CONTRACT_ID \
and ce.ALM_REPLICATIONSEGMENTNAME='AAAA_PAR' \
and c.STOCK_TYPE_ENUM =6 \
order by c.CONTRACT_ID,PART_NAME,ORIGIN, MATURITY;


