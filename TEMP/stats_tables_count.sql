SELECT o.NAME,
  i.rowcnt 
FROM sysindexes AS i
  INNER JOIN sysobjects AS o ON i.id = o.id 
WHERE i.indid < 2  AND OBJECTPROPERTY(o.id, 'IsMSShipped') = 0
ORDER BY o.NAME
