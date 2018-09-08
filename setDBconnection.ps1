
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

set-DBconnection