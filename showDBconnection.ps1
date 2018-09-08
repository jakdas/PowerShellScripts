
function show-DBconnection () {

 $data = get-content ".\connection.properties" -Raw | ConvertFrom-Json
 $connectionString = 'Server = ' + $data.Connection.Server + '; Database = ' + $data.Connection.Database + '; Integrated Security = false; User ID = ' + $data.Connection."User ID" `
                               + '; Password = ' + $data.Connection.Password + ';'
 $connectionString 

 read-host -prompt 'Press Enter'

}

show-DBconnection