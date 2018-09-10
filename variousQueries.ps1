. C:\Users\IEUser\buildQuery.ps1
#. C:\Users\IEUser\sql_functions.ps1

function get-definedQueries() {

 $queries = @{}

 $queries.add("CAT1_Query1", "
 SELECT * 
   FROM BSDATE")
 $queries.add("CAT2_Query2", "
 SELECT SITUATION_DATE,COUNT(*) 
   FROM CONTRACT 
  GROUP BY SITUATION_DATE")
 $queries.add("CAT3_Query3", "
 SELECT SITUATION_DATE,COUNT(*) 
   FROM ZOBJECTS 
  GROUP BY SITUATION_DATE")
 $queries.add("CAT2_Query4", "
 SELECT * 
   FROM BSDATE 
  WHERE SITUATION_DATE ='___SD__Enter Situation Date___'")
 $queries.add("CAT3_Query5", "
 SELECT OBJC_CLASS,COUNT(*) 
   FROM ZOBJECTS
  WHERE OBJC_CLASS like '%___OBJC_CLASS__Enter part of the OBJC_CLASS name___%'
 GROUP BY OBJC_CLASS
 --SORT:Column1")

 $processedQueries = foreach ($query in $queries.keys) {
   $fields = $query -split "_"
   $row = New-Object -TypeName PSObject
   $row | Add-Member -MemberType NoteProperty -Name "Category" -Value $fields[0]
   $row | Add-Member -MemberType NoteProperty -Name "Name" -Value $fields[1]
   $row | Add-Member -MemberType NoteProperty -Name "Query" -Value $queries[$query]
   $row
 } 
 
 $selectedQuery = $processedQueries | Sort-Object -Property Category,Name  | ogv -PassThru


 $selectedQuery.Query
 $sortPhrase = $($selectedQuery.Query -replace "`n","")  -replace "^.*--SORT:",""
 $sqlQuery = build-query $selectedQuery.Query
 $sqlQuery
 executesqlquery $sqlQuery | Sort-Object -Property $sortPhrase | ogv -PassThru

}

function executeAnyQuery()  {
  
  $sql = get-Parameter "Paste your SQL query here"
  
  $output = executemultisqlquery $sql 
  $fields = $output  | Get-Member -MemberType NoteProperty | Where-Object PropertyName -ne "Database" | Select -ExpandProperty Name  | ogv -PassThru

  $fields | Get-Member
  $properties = ""
  $fields | % {if ($_ -ne "Database") {$properties=$properties + $_ + ","}}
  $properties = $properties + "Database"
  $properties
  #select * from BSDATE
  $output | Sort-Object -Property $properties | ogv -PassThru

}




function OLDget-allPlistEnumValues() {

$query = "
select INTERNAL_NAME, 
substring(substring(PLIST_STRING,charindex('Members=(',PLIST_STRING)+9, 
charindex(')',substring(PLIST_STRING,charindex('Members=(',PLIST_STRING)+9,len(PLIST_STRING)))-1),1,100) ENUM_VALUES 
from ZOBJECTS Z  
where OBJC_CLASS = 'ALMEnumeration' 
and PLIST_STRING IS NOT NULL  
and SITUATION_DATE = (select MAX(SITUATION_DATE) FROM ZOBJECTS Z1 
                     WHERE Z1.OID=Z.OID) 
and PLIST_STRING not like '%Members=()%' 
and PLIST_STRING not like '%TableName=%' 
--and INTERNAL_NAME like '%arc_jakub%' 
order by INTERNAL_NAME"

$output = executesqlquery $query

$output | % {
  $name = $_.INTERNAL_NAME
  $enumValues = $_.ENUM_VALUES -split ","
  foreach ($enum in $enumValues) {
     $row = New-Object -TypeName psobject
     $row | Add-Member -MemberType NoteProperty -Name "INTERNAL_NAME" -Value $name
     $row | Add-Member -MemberType NoteProperty -Name "VALUE" -Value $enum 
     $row
  }

} 
#RETURN:   INTERNAL_NAME, VALUE
}
