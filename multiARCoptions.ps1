. C:\Users\IEUser\multiDBs.ps1
. C:\Users\IEUser\buildQuery.ps1
. C:\Users\IEUser\variousQueries.ps1

function get-multiARCoptions () {
  

  $options = @("Define new DB connection",
           "Compare Attributes",
           "Display differing attributes",
           "Run your own predefined queries",
           "Paste any sql query",
           "Compare DB schemas",
           "Compare DB schemas with position")
        


   $again = 1 
           
   while ($again -eq 1) {

   $title = "MODE: MULTI"
   $selected = $options | ogv -PassThru -title $title
   


   if ($selected -eq $null) {
     $again = 0
   }
   else {


        switch ($selected) {
          "Define new DB connection" { set-nextDBconnection }
          "Compare Attributes"       { test-compareAttributes 1 | ogv -PassThru}
          "Display differing attributes" { test-compareAttributes 0 | ogv -PassThru }
          "Paste any sql query"      { executeAnyQuery  }
          "Run your own predefined queries"     { get-definedQueries4MultiDB }
          "Compare DB schemas with position" { jkd-compareSchemas 1 | ogv -PassThru }
          "Compare DB schemas"       { jkd-compareSchemas 0 | ogv -PassThru }
        }

    }
   }

}



get-multiARCoptions