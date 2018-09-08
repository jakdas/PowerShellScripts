. C:\Users\IEUser\getParameter_mac.ps1
. C:\Users\IEUser\sql_functions.ps1
. C:\Users\IEUser\oids.ps1
. C:\Users\IEUser\IFRS9.ps1

function get-ARCoptions () {
  
  $options = @("Set DB connection",
           "Show DB connection",
           "Display Process Definition",
           "AssistantInProcesses",
           "ZOBJECTS",
           "IFRS9 Summary",
           "List Facilities",
           "Others")

      
 $otherOptions = @("EconomicScenarios",
           "SuperScenarios",          
           "BusinessPlanningScenarios", 
           "BehavioralScenarios",   
           "Processes",             
           "TasksInProcess",           
           "EnumerationsInDB",           
           "EnumerationsInPList",
           "TableSize",
           "ListColumns",
           "ListTables",
           "ListSDTables",
           "RowCount",
           "RowSDCount")    
    


    
   $again = 1 
           
   while ($again -eq 1) {

   $dbname = get-databasename
   $servername = Get-Servername
   $title = "Server: " + $servername + "  DB: " + $dbname
   $selected = $options | ogv -PassThru -title $title
   
   if ($selected -Eq "Others") {
     $selected = $otherOptions | ogv -PassThru -title $title
   }

   #$selected
   $dbname = get-databasename
   $_Name = ""

   if ($selected -eq $null) {
     $again = 0
   }
   else {

        if ($selected -notin ("Show DB Connection","Set DB Connection")) {
           $_Name = get-Parameter "like Name"
        }
        switch ($selected) {
          EconomicScenarios          { runQuery "--2ECOSC" $dbname $_Name }
          SuperScenarios             { runQuery "--2SUPERSC" $dbname $_Name }
          BusinessPlanningScenarios  { runQuery "--2BPSC" $dbname $_Name }
          BehavioralScenarios        { runQuery "--2BEHSC" $dbname $_Name }

          Processes                  { runQuery "--2PROCESSES" $dbname $_Name }
          TasksInProcess             { runQuery "--2TASKSINPROCESS" $dbname $_Name }

          EnumerationsInDB           { runQuery "--2ENDB" $dbname $_Name }
          EnumerationsInPList        { runQuery "--2ENPL" $dbname $_Name }

          TableSize                  { runQuery "--2SIZE" $dbname $_Name }
          ListColumns                { runQuery "--2COLUMNS" $dbname $_Name }
          ListTables                 { runQuery "--2TABLES" $dbname  $_Name }
          ListSDTables               { runQuery "--2SDTABLES" $dbname  $_Name }
          RowCount                   { runQuery "--2ROWCOUNT" $dbname  $_Name }
          RowSDCount                 { runQuery "--2ROWSDCOUNT" $dbname  $_Name 10 }
          AssistantInProcesses       { runQuery "--2ASSISTANT" $dbname $_Name }
          "Display Process Definition" {get-tasksdetails $_Name }
          "Set DB connection"        { set-DBconnection }
          "Show DB connection"       { show-DBconnection }
          "ZOBJECTS"                 { get-oids $_Name | ogv}
          "IFRS9 Summary"            { get-ifrs9summaryFinal $_Name }
          "List Facilities"          { get-listfacilities $_Name  | ogv -PassThru}
        }

    }
   }

}

function GetQuery ($SQLFILES, $QUERYNAME) {
get-content $SQLFILES | foreach {switch -wildcard ($_) {                                                                                                        
 $queryname {$flag=1
             $_=""
             continue}   
 "" {$flag=0}}  
 if ($flag -eq 1) { $_ } 
 }  
 write-output ""
}


function getFullQuery ($QUERYNAME,$dbname, $par1, $par2, $par3) {
$modifiedQuery = (GetQuery "C:\TEMP\bcp_quer*.sql" $QUERYNAME) -replace "\\", ""`
   -replace "DB_NAME", $dbname `
   -replace "AAAA_PAR", $par1 `
   -replace "AAAA_PAR", $par1 `
   -replace "BBBB_PAR", $par2 `
   -replace "CCCC_PAR", $par3 `
   -replace "AAAA", $host_name  `
   -replace "BBBB", $user_name  `
   -replace "CCCC", $password 
   Write-Output $modifiedQuery
}

    
function runQuery ($QUERYNAME, $dbname, $par1,$par2,$par3) {
  $query = getFullQuery $QUERYNAME $dbname $par1 $par2 $par3
  $query | select -index (2..100)
  $output = ExecuteSqlQuery ($query | select -index (2..100)) | ogv -PassThru

}    

get-ARCoptions