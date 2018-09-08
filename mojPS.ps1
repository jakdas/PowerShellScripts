function ExecuteSqlQueryFromFile  ($con, $SQLQuery) {
                    $Datatable = New-Object System.Data.DataTable
               
                    $Connection = New-Object System.Data.SQLClient.SQLConnection
                    $connection.ConnectionString = $con

#$Connection.ConnectionString = "Server = 10.22.64.197,1401; Database = alm_jakub_171M; Integrated Security = false; User ID = alm_jakub_171M; Password = alm_jakub_171M;”

                    $Connection.Open()
                    $Command = New-Object System.Data.SQLClient.SQLCommand
                    $Command.Connection = $Connection
                    $Command.CommandText = $SQLQuery
                    $Reader = $Command.ExecuteReader()
                    $Datatable.Load($Reader)
                    $Connection.Close()
               
                    return $Datatable
 
                }

function executesqlquery ($query) {
    
    $con = get-DBConnection
    ExecuteSqlQueryFromFile $con $query
}


function get-DBconnection () {

 $data = get-content ".\connection.properties" -Raw | ConvertFrom-Json
 #$data.Connection.Server
 #$data.Connection.Database
 #$data.Connection."User ID"
 #$data.Connection.Password
 #Write-Output '"Server = 10.22.64.197,1433; Database = alm_jakub_171M; Integrated Security = false; User ID = alm_jakub_171M; Password = alm_jakub_171M;”'
 $connectionString = 'Server = ' + $data.Connection.Server + '; Database = ' + $data.Connection.Database + '; Integrated Security = false; User ID = ' + $data.Connection."User ID" `
                               + '; Password = ' + $data.Connection.Password + ';'
 $connectionString 

}


function show-DBconnection () {

 $data = get-content ".\connection.properties" -Raw | ConvertFrom-Json
 $connectionString = 'Server = ' + $data.Connection.Server + '; Database = ' + $data.Connection.Database + '; Integrated Security = false; User ID = ' + $data.Connection."User ID" `
                               + '; Password = ' + $data.Connection.Password + ';'
 $connectionString 

 read-host -prompt 'Press Enter'

}

function set-DBconnection () {

 $server = Read-Host -Prompt 'Input server name'
 $database = Read-Host -Prompt 'Input database name'
 $user = Read-Host -Prompt 'Input user name' 
 $password = Read-Host -Prompt 'Input password' 

 $data = @{
    Connection = @{
    Server    = $server 
    Database  = $database
    "User ID" = $user
    Password  = $password
    }
 }
 
 $data | ConvertTo-Json | Set-Content -path ".\connection.properties"


}


function get-alltablescontents () {


$query = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME"


$repeat = ""
while ($repeat -ne $null) {

$tableName  = ExecuteSqlQuery $query | ogv -PassThru | % {$_.TABLE_NAME}


$repeat = get-columns $tableName

}
}

function get-columns ($tableName) {

    $query = "SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = N'___TABLENAME___'" -replace "___TABLENAME___","$tableName"

$nbOfColumns=0
$columns = ExecuteSqlQuery $query | ogv -PassThru | % {$_.COLUMN_NAME;$nbOfColumns=$nbOfColumns+1}

if ($nbOfColumns -ne 0) {
$listOfColumns = ""
$columns | % { $listOfColumns = $listOfColumns + $_ + " , " }
$listOfColumns = $listOfColumns -replace ', $',''

$query = "Select $listOfColumns , count(*) _COUNT_ from $tableName group by $listOfColumns order by $listOfColumns"

$results = executesqlquery $query | ogv -PassThru | % {$_}
$properties = $results | Get-Member -membertype property | where Name -ne "_COUNT_" | % {$_.Name}
$conditions = $results | % {foreach ($property in $properties) {
      
      if ([String]::IsNullOrEmpty($_.$Property.ToString())) {
         $Property + " is null "
      } else {
         $Property + "='" +$_.$Property + "'"
      }
      }}
$listOfConditions = ""
$conditions | % { $listOfConditions = $listOfConditions + $_ + " AND " }
$listOfConditions = $listOfConditions -replace 'AND $',''

$query = "Select * from $tableName where $listOfConditions order by $listOfColumns"

} else {
$query = "Select * from $tableName"
}
    
    $queryOutput   = ExecuteSqlQuery  $query | ConvertTo-Csv | ConvertFrom-Csv
     
    $queryOutput1 = clear-nulls-norename $queryOutput $queryOutput
    $repeat = $queryOutput1 | ogv -PassThru
    $repeat

}


Function clear-nulls-norename ($data, $data2) {
    
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
    #$cStore = $cStore | sort

    $data2 |   foreach {
        [int]$numer=1
        $newObj = New-Object -TypeName PSObject
        foreach ($field in $properties)
        {
            if ($cStore -contains $field) {
               $newObj | Add-Member -Name $field -Value $_.$field -MemberType NoteProperty
            }
        }
       $newObj
    }
}


#Write-Output  $MyInvocation.MyCommand.Definition
#Read-Host -Prompt 'press Enter'
get-alltablescontents


#set-DBconnection
