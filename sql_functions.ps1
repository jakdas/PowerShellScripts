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

function executesqlquery ($query) {
    
    $con = get-DBConnection
    ExecuteSqlQueryFromFile $con $query
    
}

function get-databasename () {
  $dbname = get-content "C:\Users\IEUser\connection.properties" -Raw | ConvertFrom-Json | % {$_.Connection.Database}
  $dbname
}

function get-servername () {
  $dbname = get-content "C:\Users\IEUser\connection.properties" -Raw | ConvertFrom-Json | % {$_.Connection.Server}
  $dbname
}

function get-DBconnection () {

 $data = get-content "C:\Users\IEUser\connection.properties" -Raw | ConvertFrom-Json
 $connectionString = 'Server = ' + $data.Connection.Server + '; Database = ' + $data.Connection.Database + '; Integrated Security = false; User ID = ' + $data.Connection."User ID" `
                               + '; Password = ' + $data.Connection.Password + ';'
 $connectionString 

}


function show-DBconnection () {

 $data = get-content "C:\Users\IEUser\connection.properties" -Raw | ConvertFrom-Json
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
 
 $data | ConvertTo-Json | Set-Content -path "C:\Users\IEUser\connection.properties"


}