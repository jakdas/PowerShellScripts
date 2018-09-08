. C:\Users\IEUser\getParameter_mac.ps1
. C:\Users\IEUser\sql_functions.ps1
. C:\Users\IEUser\oids.ps1
. C:\Users\IEUser\IFRS9.ps1
. C:\Users\IEUser\SConscript.ps1
. C:\Users\IEUser\browseJsons.ps1
. C:\Users\IEUser\getSDjsons.ps1
. C:\Users\IEUser\getARCfiles.ps1
. C:\Users\IEUser\analyzeLogs.ps1
. C:\Users\IEUser\preIFRS9.ps1
. C:\Users\IEUser\ND.ps1
. C:\Users\IEUser\variousQueries.ps1

function get-ARCoptions () {
  
  $options = @("Set DB connection",
           "Show DB connection",
           "Display Process Definition",
           "Run your own queries",
           "AssistantInProcesses",
           "ZOBJECTS...",
           "National Discretion...",
           "IFRS9 Rename Folders",
           "IFRS9 Summary",
           "List Facilities",
           "Show SQL Queries",
           "Show SQL Queries WITHOUT ZOBJECTS",
           "Browse almGenericFiles",
           "Others...",
           "Technical...")

$ndOptions = @("National Discretion Attributes",
               "National Discretion Parameters")

$zobjectsOPTIONS = @("ZOBJECTS",
                     "ZOBJECTS with names",
                     "Browse by OBJC_CLASS",
                     "Dependencies",
                     "WHERE INTERNAL_NAME LIKE %",
                     "WHERE OBJC_CLASS LIKE %",
                     "Attributes",
                     "Attributes by type",
                     "ZOBJECTS changes")
      
 $otherOptions = @("EconomicScenarios",
           "SuperScenarios",          
           "BusinessPlanningScenarios", 
           "BehavioralScenarios",   
           "Processes",             
           "TasksInProcess", 
           "Browse json files (SDK limits)",
           "Browse FFC static data")    
    
$technicalOptions = @("Sconscripts",
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
   
   if ($selected -Eq "Others...") {
     $selected = $otherOptions | ogv -PassThru -title $title
   }

   if ($selected -Eq "Technical...") {
     $selected = $technicalOptions | ogv -PassThru -title $title
   }

   if ($selected -Eq "ZOBJECTS...") {
     $selected = $zobjectsOPTIONS | ogv -PassThru -title $title
   }
   if ($selected -Eq "National Discretion...") {
     $selected = $ndOPTIONS | ogv -PassThru -title $title
   }

   #$selected
   $dbname = get-databasename
   $_Name = ""

   if ($selected -eq $null) {
     $again = 0
   }
   else {

        if ($selected -notin ("Show DB Connection","Set DB Connection", "Sconscripts", "Browse json files","Browse FFC static data","Browse almGenericFiles",
                              "Show SQL Queries WITHOUT ZOBJECTS","Show SQL Queries","IFRS9 Rename Folders", "Browse by OBJC_CLASS", "Dependencies",
                              "WHERE INTERNAL_NAME LIKE %","WHERE OBJC_CLASS LIKE %","Attributes by type", "National Discretion Attributes", "National Discretion Parameters",
                              "ZOBJECTS changes","Run your own queries")) {
           $_Name = get-Parameter "like Name"
        }
        if ($selected -in ("Show SQL Queries WITHOUT ZOBJECTS","Show SQL Queries")) {
           $_Name = get-Parameter "min time"
        }
        if ($selected -in ("IFRS9 Rename Folders")) {
           $_Name = get-Parameter "start date"
        }
        if ($selected -in ("Dependencies")) {
           $_Name = get-Parameter "OID"
        }
        if ($selected -in ("WHERE INTERNAL_NAME LIKE %")) {
           $_Name = get-Parameter "INTERNAL_NAME"
        }
        if ($selected -in ("WHERE OBJC_CLASS LIKE %")) {
           $_Name = get-Parameter "OBJC_CLASS"
        }

        switch ($selected) {
          "Run your own queries"     { get-definedQueries }
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
          "ZOBJECTS with names"      { get-oidsWithNames $_Name  | ogv }
          "IFRS9 Summary"            { get-ifrs9summaryFinal $_Name }
          "IFRS9 Rename Folders"     { jkd-renameFolders $_Name }
          "List Facilities"          { get-listfacilities $_Name  | ogv -PassThru}
          "Sconscripts"              { get-sconscripts }
          "Browse json files (SDK limits)"        { browse-jsons }
          "Browse FFC static data"   { get-SD-jsons }
          "Browse almGenericFiles"   { get-arc }
          "Show SQL Queries WITHOUT ZOBJECTS" { analyze-logs 0 $_Name | ogv -PassThru}
          "Show SQL Queries"         { analyze-logs 1 $_Name | ogv -PassThru}


          "Browse by OBJC_CLASS"     { get-browseByOBJCCLASS }
          "Dependencies"             { get-dependentOIDS $_Name  }
          "WHERE INTERNAL_NAME LIKE %" { get-oidsLikeInternalName $_Name | ogv -PassThru }
          "WHERE OBJC_CLASS LIKE %"    { get-oidsLikeObjcClass $_Name | ogv -PassThru }
          "Attributes"                 { get-oids4Attributes $_Name | ogv -PassThru }
          "Attributes by type"         { get-oids4AttributesByType | ogv -PassThru }
          "ZOBJECTS changes"           { get-zobjectsChanges | ogv -PassThru }

          "National Discretion Attributes"   { jkd-ND-attributes }
          "National Discretion Parameters"   { jkd-ND-parameters }
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