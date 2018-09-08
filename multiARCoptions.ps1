. C:\Users\IEUser\multiDBs.ps1

function get-multiARCoptions () {
  

  $options = @("Set DB connection",
           "Show DB connection",
           "Compare Attributes",
           "Display differing attributes",
           "Run your own queries",
           "Paste any sql query")
        


   $again = 1 
           
   while ($again -eq 1) {

   $title = "MODE: MULTI"
   $selected = $options | ogv -PassThru -title $title
   


   if ($selected -eq $null) {
     $again = 0
   }
   else {


        switch ($selected) {

          "Compare Attributes"       { test-compareAttributes 1 | ogv -PassThru}
          "Display differing attributes" { test-compareAttributes 0 | ogv -PassThru }
          "Paste any sql query"      { executeAnyQuery | ogv -PassThru
          "Run your own queries"     { get-definedQueries }
        }

    }
   }

}



get-multiARCoptions