#show-allDBconnections
#get-selectedDBconnection $connectionID
#set-nextDBconnection

function ExecuteSqlQueryFromFile  ($con, $SQLQuery) {
                    $Datatable = New-Object System.Data.DataTable
               
                    $Connection = New-Object System.Data.SQLClient.SQLConnection
                    $connection.ConnectionString = $con

                    $Connection.Open()
                    $Command = New-Object System.Data.SQLClient.SQLCommand
                    $Command.Connection = $Connection
                    $Command.CommandText = $SQLQuery
                    $Reader = $Command.ExecuteReader()
                    $Datatable.Load($Reader)
                    $Connection.Close()
               
                    return $Datatable
 
                }

function show-allDBconnections() {

$selectedConnections = @()
$allConnections = get-content "C:\Users\IEUser\multiconnection.properties" -Raw | ConvertFrom-Json 
$allConnections | % { 
   
   $_.PSObject.properties | % { 
       $connection = New-Object -TypeName PSObject
       $connection | Add-Member -Name "Connection" -Value $_.Name -MemberType NoteProperty
       $connection | Add-Member -Name "Name" -Value $_.Value.Name -MemberType NoteProperty
       $connection | Add-Member -Name "Description" -Value $_.Value  -MemberType NoteProperty

       $connection
   }
   
}  | select -Property Name,Description, Connection |  ogv -PassThru | % { $selectedConnections = $selectedConnections +  $_.Connection }


,$selectedConnections
}




function get-selectedDBconnection($connectionId) {

 $allConnections = get-content "C:\Users\IEUser\multiconnection.properties" -Raw | ConvertFrom-Json
 $data = $allConnections.$connectionId
 $data
 $connectionString = 'Server = ' + $data.Server + '; Database = ' + $data.Database + '; Integrated Security = false; User ID = ' + $data."User ID" `
                               + '; Password = ' + $data.Password + ';'
 $connectionString 

}


Function clear-nulls1 ($data, $data2) {
    
    $properties=$data | Get-Member -membertype noteproperty  | % {$_.Name}
    $cStore = @()     # array to store used column numbers
    $data |   foreach {
            foreach ($field in $properties)
            {
                if ($_.($field) -ne '')
                {
                    if ($cStore -notcontains $field) {$cStore += $field                                                  }
                }
            }
    }
    $cStore = $cStore | sort

    $data2 |   foreach {
        [int]$numer=1
        $newObj = New-Object -TypeName PSObject
        foreach ($field in $properties)
        {
            if ($cStore -contains $field) {
              if ($field -eq "CATEGORY") {
               $newObj | Add-Member -Name "CATEGORY" -Value $_.$field -MemberType NoteProperty
              } else {
               $newObj | Add-Member -Name $field -Value $_.$field -MemberType NoteProperty
               
               $numer=$numer+1 
               }
            }
        }
       $newObj
    }
}


function get-definedQueries4MultiDB() {

 $queries = @{}

 $queries.add("CAT1__BSDATE Table", "
 SELECT * 
   FROM BSDATE")
 $queries.add("CAT2__Number of contracts per SD", "
 SELECT SITUATION_DATE,COUNT(*) COUNT
   FROM CONTRACT 
  GROUP BY SITUATION_DATE")
 $queries.add("CAT2__Query4", "
 SELECT * 
   FROM BSDATE 
  WHERE SITUATION_DATE ='___SD__Enter Situation Date___'")
 $queries.add("CAT3__ZOBJECTS objects for OBJC_CLASS", "
 SELECT OBJC_CLASS,COUNT(*) COUNT
   FROM ZOBJECTS
  WHERE OBJC_CLASS like '%___OBJC_CLASS__Enter part of the OBJC_CLASS name___%'
 GROUP BY OBJC_CLASS")

 $processedQueries = foreach ($query in $queries.keys) {
   $fields = $query -split "__"
   $row = New-Object -TypeName PSObject
   $row | Add-Member -MemberType NoteProperty -Name "Category" -Value $fields[0]
   $row | Add-Member -MemberType NoteProperty -Name "Name" -Value $fields[1]
   $row | Add-Member -MemberType NoteProperty -Name "Query" -Value $queries[$query]
   $row
 } 
 
 $selectedQuery = $processedQueries | Sort-Object -Property Category,Name  | ogv -PassThru


 $selectedQuery.Query
 $sqlQuery = build-query $selectedQuery.Query
 $sqlQuery
 executemultisqlquery $sqlQuery | ogv -PassThru

}

function jkd-compareSchemas($withPosition) {

if ($withPosition -eq 1) {
$sql = "SELECT  t.table_name ,concat(c.ordinal_position,':',c.column_name,': (',c.IS_NULLABLE,') ',c.DATA_TYPE,' ', c.CHARACTER_MAXIMUM_LENGTH,' ', c.NUMERIC_PRECISION) VALUE
FROM INFORMATION_SCHEMA.TABLES t,INFORMATION_SCHEMA.COLUMNS c
WHERE t.TABLE_TYPE = 'BASE TABLE' 
and t.TABLE_NAME=c.TABLE_NAME
and t.TABLE_CATALOG=c.TABLE_CATALOG
and (t.TABLE_NAME not like '%_SS1[0-9]%' and t.TABLE_NAME not like '%_SS2[0-9]%' and t.TABLE_NAME not like '%_SS[0-9]' or t.TABLE_NAME like '%_SS1' )
order by t.TABLE_NAME"
}
else {
$sql = "SELECT  t.table_name ,concat(c.column_name,': (',c.IS_NULLABLE,') ',c.DATA_TYPE,' ', c.CHARACTER_MAXIMUM_LENGTH,' ', c.NUMERIC_PRECISION) VALUE
FROM INFORMATION_SCHEMA.TABLES t,INFORMATION_SCHEMA.COLUMNS c
WHERE t.TABLE_TYPE = 'BASE TABLE' 
and t.TABLE_NAME=c.TABLE_NAME
--and t.TABLE_NAME like '[A-X]%'
and t.TABLE_CATALOG=c.TABLE_CATALOG
and (t.TABLE_NAME not like '%_SS1[0-9]%' and t.TABLE_NAME not like '%_SS2[0-9]%' and t.TABLE_NAME not like '%_SS[0-9]' or t.TABLE_NAME like '%_SS1' )
order by t.TABLE_NAME"
}


$allData = executemultisqlquery $sql 
$connections = @()
$processedData = $allData | % {
   if ($_.Database -notin $connections) {
      $connections=$connections + $_.Database
   }
   $row = New-Object -TypeName psobject 
   $row | Add-Member -MemberType NoteProperty -Name "INTERNAL_NAME" -Value $_.TABLE_NAME 
   $row | Add-Member -MemberType NoteProperty -Name "VALUE" -Value $_.VALUE
   $row | Add-Member -MemberType NoteProperty -Name "Database" -Value $_.Database
   $row
} 

jkd-displayExistSummary $processedData 0 $connections

}

function jkd-displayExistSummary($allData,$displayAll,$connections) {



 $headerRow = New-Object -TypeName psobject
 $headerRow | Add-Member -MemberType NoteProperty -Name "VALUE" -Value ""
 $headerRow | Add-Member -MemberType NoteProperty -Name "COUNT" -Value ""

 foreach ($name in $connections) {
    $headerRow | Add-Member -MemberType NoteProperty -Name $name -Value ""
 }
 
 $wynik=$allData  | Group-Object -Property INTERNAL_NAME,VALUE 
 $output = $wynik | % {
    $obj=new-object -TypeName PSObject; 
    $obj | Add-member -name "VALUE" -value $($_.Name -replace ",",":") -MemberType NoteProperty; 
    $count = 0
    foreach ($item in $_.Group)  {
        $obj | Add-Member -Force -name $item.Database -value  "EXISTS" -MemberType NoteProperty
        $count = $count+1
    }
    $obj | Add-Member -Name "COUNT" -Value $count -MemberType NoteProperty 
    $obj}

 $finalOutput = $output | Sort-Object -Property VALUE
 $headerRow 
 if ($displayAll -eq 0) {
   $finalOutput | Where-Object COUNT -ne $connections.Count
 } else {
   $finalOutput
 }
 


}




function test-compareAttributes($displayAll) {


$sql = "
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
and INTERNAL_NAME like '%'
--and INTERNAL_NAME like '%arc_jakub%' 
order by INTERNAL_NAME"

$output= executemultisqlquery $sql
$connections = @()

$allPLISTRows = $output | % {
  $name = $_.INTERNAL_NAME
  $db = $_.Database
  if ($db -notin $connections) {$connections=$connections + $db}
  $enumValues = $_.ENUM_VALUES -split ","
  foreach ($enum in $enumValues) {
     $row = New-Object -TypeName psobject
     $row | Add-Member -MemberType NoteProperty -Name "INTERNAL_NAME" -Value $name
     $row | Add-Member -MemberType NoteProperty -Name "VALUE" -Value $enum 
     $row | Add-Member -MemberType NoteProperty -Name "Database" -Value $db
     $row
  }
}

 $allDBRows = get-attributesFromDB
 


 $headerRow = New-Object -TypeName psobject
 $headerRow | Add-Member -MemberType NoteProperty -Name "VALUE" -Value ""
 $headerRow | Add-Member -MemberType NoteProperty -Name "COUNT" -Value ""

 foreach ($name in $connections) {
    $headerRow | Add-Member -MemberType NoteProperty -Name $name -Value ""
 }
 
 $wynik=$allPLISTRows + $allDBRows  | Group-Object -CaseSensitive -Property INTERNAL_NAME,VALUE 
 $output = $wynik | % {
    $obj=new-object -TypeName PSObject; 
    $obj | Add-member -name "VALUE" -value $($_.Name -replace ",",":") -MemberType NoteProperty; 
    $count = 0
    foreach ($item in $_.Group)  {
        $obj | Add-Member -Force -name $item.Database -value  "EXISTS" -MemberType NoteProperty
        $count = $count+1
    }
    $obj | Add-Member -Name "COUNT" -Value $count -MemberType NoteProperty 
    $obj}

 $finalOutput = $output | Sort-Object -Property VALUE
 $headerRow 
 if ($displayAll -eq 0) {
   $finalOutput | Where-Object COUNT -ne $connections.Count
 } else {
   $finalOutput
 }


}


function get-attributesFromDB() {

$sql = "select CONCAT('SELECT `"',t.TABLE_NAME,'`" CATEGORY, str(',c.COLUMN_NAME,'), DESCRIPTION FROM ',t.TABLE_NAME,'  UNION ALL')
--CONCAT('SELECT `"',t.TABLE_NAME,'`" CATEGORY,',c.COLUMN_NAME,', DESCRIPTION FROM ',t.TABLE_NAME,'  UNION ALL')
FROM INFORMATION_SCHEMA.TABLES t,INFORMATION_SCHEMA.COLUMNS c
where  t.TABLE_TYPE = 'BASE TABLE'
and t.TABLE_NAME=c.TABLE_NAME
and t.TABLE_CATALOG=c.TABLE_CATALOG
  AND t.TABLE_NAME IN (
SELECT t1.table_name 
FROM INFORMATION_SCHEMA.TABLES t1,INFORMATION_SCHEMA.COLUMNS c1
WHERE t1.TABLE_TYPE = 'BASE TABLE'
and t1.TABLE_NAME=c1.TABLE_NAME
and t1.TABLE_CATALOG=c1.TABLE_CATALOG
group by t1.table_name
having count(*) =2)
and t.TABLE_NAME not in ('VERSIONS','TABLE_TO_ANONYMISE','COUNTRY_RATING_TMP','CONTRACT_MITIGANT_GROUP','CONTRACT_PLEDGEDASSET_GROUP','BIS_CREDIT_APPROACH')
and c.COLUMN_NAME != 'DESCRIPTION'   --BIS_CREDIT_APPROACH   BIS_CREDIT_APPROACH_REF
order by t.TABLE_NAME"

$unions = ExecuteSqlQuery $sql "arcjakub"
$properUnions = $unions | % {if ($_.Column1 -like "*VALUATION_METHOD_ENUM*") {$_.Column1 -replace "UNION ALL",""} else {$_.Column1}}   

$properUnions = $properUnions -replace "`"","'"
$output = ExecutemultiSqlQuery $properUnions 

$output | % {
   $row = New-Object -TypeName psobject 
   $row | Add-Member -MemberType NoteProperty -Name "INTERNAL_NAME" -Value $($_.CATEGORY + " (DB)") 
   $row | Add-Member -MemberType NoteProperty -Name "VALUE" -Value $($_.DESCRIPTION + " (" + $($_.Column1 -replace " ","") + ")") 
   $row | Add-Member -MemberType NoteProperty -Name "Database" -Value $_.Database
   $row
}


}


function test-multicount() {

 #$test1=@{"aaa"=7;"bbb"=8;"ccc"=9}
 #$test1 | % {
 #  foreach ($item in $_.keys) {
 #     $obj=New-Object -typename PSObject;
 #     $obj | Add-Member -name "Name" -value "AA" -MemberType NoteProperty; 
 #     $obj | Add-Member -name "Value" -Value $_[$item] -MemberType NoteProperty;$obj
 #  }} | Group-Object -Property Name | % {$_.Group.Value} | Sort-Object -Unique | Measure-Object | %{ $_.Count}

 
 $sql="select INTERNAL_NAME, 
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
#$sql = "select * from BSDATE"
 #$sql = "select SITUATION_DATE, BUCKET_NAME, BUCKET_INDEX from BUCKET where SITUATION_DATE = '20041231'"
 $output= executemultisqlquery $sql | Sort-Object -Property SITUATION_DATE
 $wynik=$output | Group-Object -Property SITUATION_DATE #, BUCKET_NAME, BUCKET_INDEX
 $wynik | % {
    $obj=new-object -TypeName PSObject; 
    $obj | Add-member -name "VALUE" -value $_.Name -MemberType NoteProperty; 
    foreach ($item in $_.Group)  {
        $obj | Add-Member -name $item.Database -value  "EXISTS" -MemberType NoteProperty
    }; 
    $obj}


}


function set-nextDBconnection () {

 $allConnections = get-content "C:\Users\IEUser\multiconnection.properties" -Raw | ConvertFrom-Json 
 $nextConnectionName = $allConnections | % { $_.PSObject.properties | % { $_.name -replace "Connection",""} | select -last 1 | % {"Connection" + $([int]$_ + 1)}} 

 $name = Read-Host -Prompt 'Input connection name'
 $server = Read-Host -Prompt 'Input server name'
 $database = Read-Host -Prompt 'Input database name'
 $user = Read-Host -Prompt 'Input user name' 
 $password = Read-Host -Prompt 'Input password' 

 $data = @"
 {
    "Name" : "$name", 
    "Server"    : "$server", 
    "Database"  : "$database",
    "User ID" : "$user",
    "Password"  : "$password"
}
"@
 
 $data

 $allConnections  | add-member -Name $nextConnectionName -value (convertfrom-json $data) -MemberType NoteProperty 

 #$allConnections |  ogv
 $allConnections | ConvertTo-Json | Set-Content -path "C:\Users\IEUser\multiconnection.properties"
 

}

function get-selectedDBconnection ($connectionName) {

 $data = get-content "C:\Users\IEUser\multiconnection.properties" -Raw | ConvertFrom-Json
 $connectionString = 'Server = ' + $data.$connectionName.Server + '; Database = ' + $data.$connectionName.Database + '; Integrated Security = false; User ID = ' + $data.$connectionName."User ID" `
                               + '; Password = ' + $data.$connectionName.Password + ';'
 $connectionString 

}


function executemultisqlquery ($query) {
   $connections = show-allDBconnections
   $connections | % {
     
      $result = executesqlquery  $query $_
      $result | Add-Member -Name Database -Value $_ -MemberType NoteProperty
      $output = $result  | ConvertTo-Csv | ConvertFrom-Csv
      $result = clear-nulls1 $output $output
      $result
   } 
   
}


function runmultisqlquery () {

 $queries = @{}

 $queries.add("Query1", "select * from BSDATE")
 $queries.add("Query2", "select SITUATION_DATE,COUNT(*) from CONTRACT GROUP BY SITUATION_DATE")
 $queries.add("Query3", "select SITUATION_DATE,COUNT(*) from ZOBJECTS group by SITUATION_DATE")
 $queries.add("Query4", "SELECT o.NAME,
  i.rowcnt ru
FROM sysindexes AS i
  INNER JOIN sysobjects AS o ON i.id = o.id 
WHERE i.indid < 2  AND OBJECTPROPERTY(o.id, 'IsMSShipped') = 0
ORDER BY o.NAME")

 $queries.add("Query5","select INTERNAL_NAME, 
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
order by INTERNAL_NAME")




 $selectedQuery = $queries | ogv -PassThru


 $output= executemultisqlquery $selectedQuery.Value | Sort-Object -Property SITUATION_DATE
 $wynik=$output | Group-Object -Property SITUATION_DATE #, BUCKET_NAME, BUCKET_INDEX
 $wynik | % {
    $obj=new-object -TypeName PSObject; 
    $obj | Add-member -name "VALUE" -value $_.Name -MemberType NoteProperty; 
    foreach ($item in $_.Group)  {
        $obj | Add-Member -name $item.Database -value  "EXISTS" -MemberType NoteProperty
    }; 
    $obj}

#
#  executemultisqlquery $selectedQuery.Value | Group-Object -Property NAME | Where-Object Count -eq 2  | `
#      % {#

         
#         if ($_.Group[0].ru -ne $_.Group[1].ru) {

#            $newObj = New-Object -TypeName PSObject
#            $newObj | Add-Member -Name "Table" -Value $_.Group[0].Name -MemberType NoteProperty
#            $newObj | Add-Member -Name $_.Group[0].Database -Value $_.Group[0].ru -MemberType NoteProperty
#            $newObj | Add-Member -Name $_.Group[1].Database -Value $_.Group[1].ru -MemberType NoteProperty
#            $newObj
#         }
#        }
}


function executesqlquery ($query,$connectionName) {
     
    $con = get-selectedDBConnection $connectionName
    #"connecting to... $con ... $query"
    #$con 
    #$query
    ExecuteSqlQueryFromFile $con $query
}


