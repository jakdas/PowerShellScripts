--Wyswietla wielkosc wszytkich tablic, od najwiekszej do najmniejszej
--2SIZE
USE DB_NAME; \
with cte as ( \
SELECT \
t.name as TableName, \
SUM (s.used_page_count) as used_pages_count, \
SUM (CASE WHEN (i.index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count) \
          ELSE lob_used_page_count + row_overflow_used_page_count END) as pages \
FROM sys.dm_db_partition_stats  AS s  \
JOIN sys.tables AS t ON s.object_id = t.object_id \
JOIN sys.indexes AS i ON i.[object_id] = t.[object_id] AND s.index_id = i.index_id \
GROUP BY t.name \
) \
select \
    cte.TableName,  \
    cast((cte.pages * 8.)/1024 as decimal(10,3)) as TableSizeInMB,  \
    cast(((CASE WHEN cte.used_pages_count > cte.pages  \
                THEN cte.used_pages_count - cte.pages \
                ELSE 0 \
          END) * 8./1024) as decimal(10,3)) as IndexSizeInMB \
from cte \
where cast((cte.pages * 8.)/1024 as decimal(10,3)) > 0 \
  and cte.TableName LIKE '%AAAA_PAR%'
order by 2 desc;

--Wyswietla numery partycji z tablicy SOURCE_SYSTEM
--2PARTITIONS
USE DB_NAME; \
select DISPLAY_VALUE, PARTITION_ID \
 from SOURCE_SYSTEM \
 WHERE SITUATION_DATE = (select MAX(SITUATION_DATE) from BSDATE) \
 order by DISPLAY_VALUE;

--Wyswietla wielkosc bazy danych [MB]
--2DBSIZE
use master; \
SELECT SUM(SizeMB) \
FROM ( \
    SELECT DB_NAME(database_id) AS DatabaseName, \
           Name AS Logical_Name, \
           Physical_Name, \
           (size * 8) / 1024 SizeMB \
    FROM sys.master_files \
    WHERE DB_NAME(database_id) = 'DB_NAME' \
) AS TEMP ; 

--Wyswietla liste wszystkich istniejacych Situation Dates
--2SHOWSD
use DB_NAME; \
select SITUATION_DATE, CYCLES \
  from BSDATE \
 order by SITUATION_DATE; 

--Wyswietla N ostatnich wpisow w tablicy LOG_MESSAGE
--2LAST
use DB_NAME; \
select top AAAA_PAR EVENT,PROCESS_NAME,TASK_NAME,DESCRIPTION  from LOG_MESSAGE \
order by TIMESTAMP desc; 

--Wyswietla liste baz danych (schemes)
--2LIST
use master; \
select Name from sysdatabases \
 where Name not in ('master','tempdb','model','msdb')  ; 

--Usuwa baze danych
--2DROP
use master; \
drop database AAAA_PAR;



--Wyswietla jakie kolumny ma dana tablica
--2COLUMNS
use DB_NAME; \
SELECT c.Name from sys.columns c \
join sys.objects o ON o.object_id = c.object_id \
where o.type = 'U' \
  and o.Name ='AAAA_PAR' \
  order by column_id;

 
--Wyswietla jakie tablice sa w systemie
--2TABLES
use DB_NAME; \
select o1.name from sys.tables o1 where \
o1.type = 'U' \
and o1.name like '%AAAA_PAR%' \
order by o1.name; 

--Wyswietla jakie tablice w systemie maja SITUATION_DATE i spelniaja jakis warunek
--2SDTABLES
use DB_NAME; \
select o1.name from sys.tables o1 where \
o1.type = 'U' \
and o1.name like '%AAAA_PAR%' \
and \
    exists ( SELECT   c.Name \
FROM     sys.columns c where \
c.object_id = o1.object_id \
and c.Name = 'SITUATION_DATE');

 
--Wyswietla ile wierszy jest w danej tablicy
--2ROWCOUNT
use DB_NAME; \
select 'AAAA_PAR', COUNT(*) \
  from AAAA_PAR; 



--Wyswietla ile wierszy jest w danej tablicy per SD, na ostatnie x SD
--2ROWSDCOUNT
use DB_NAME; \
select 'AAAA_PAR', SITUATION_DATE, COUNT(*) FROM \
  AAAA_PAR Z \
where Z.SITUATION_DATE >= (select SITUATION_DATE from BSDATE BS \
                            where BBBB_PAR+2 = (select count(*) from BSDATE BS1 \
                                        where BS1.SITUATION_DATE>=BS.SITUATION_DATE)) \
GROUP BY SITUATION_DATE \
ORDER BY SITUATION_DATE;


--Wyswietla jakie sa cashflowy dla jakiegos trade'a na ostatnia SD
--2CASHFLOWS
use DB_NAME; \
select cf.* from CASH_FLOW cf, CONTRACT c \
 where cf.CONTRACT_ID=c.CONTRACT_ID and c.SITUATION_DATE = (select max(SITUATION_DATE) from BSDATE) \
 and cf.SITUATION_DATE = c.SITUATION_DATE \
 and c.SOURCE_CONTRACT_REF = 'AAAA_PAR';


