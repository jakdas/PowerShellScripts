. .\sql_functions.ps1
. .\getParameter_mac.ps1
#get-sqlQuery
#clear-nulls1
#get-listfacilities
#get-listfacility
#removeDups
#significantLine
#get-ifrs9summaryFinalWithParam
#get-ifrs9summaryFinal
#get-tablecontents
#clear-nulls-norename
#get-alltablescontents
#get-columns
#clear-nulls-norename


                
function get-sqlQuery ($columns, $name, $numer, $headerPart) {

  $wynik="SELECT '"+$category[$numer-1] +"' category,";
  $header0="";
  $header1="";
  $header2="SELECT '"+$category[$numer-1] +"' category,";
  $kolumna=1;
  $columns |  foreach {
   $wiersz = $_ -replace '^[ ]*(.*)[ ]*$','$1'
   $slowa = $wiersz -split(" ")
   $t=''
   $t=$slowa[0] -replace '(.*)_r[ ]*$','CAST(CAST($1 AS DECIMAL(12,8)) AS VARCHAR(15))';
   $t=$t -replace '(.*)_a[ ]*$','CAST(CAST($1 AS DECIMAL(15,2)) AS VARCHAR(15))';
   $t=$t -replace '(.*)_d[ ]*$','CAST($1 AS VARCHAR(10))';
   $t=$t -replace '(.*)_c[ ]*$','CAST($1 AS VARCHAR(20))';
     if ($t -ne '') {
       if ($header1 -eq '') {
         $header0 += "SELECT '"+$category[$numer-1] +"' category,'  ' kol" + $kolumna.toString("000") + ","
         $header1 += "SELECT '"+$category[$numer-1] +"' category,  '" + ($name -replace '(.*)\..*$','$1') + "...   ' kol" + $kolumna.toString("000") + ","

       } else {
         $header0 += "' ' kol" + $kolumna.toString("000") + ","
         $header1 += "' ' kol" + $kolumna.toString("000") + ","
       }
       if ($slowa.count -gt 1) {
         $header2 += "'" + $slowa[1] + "' kol" + $kolumna.toString("000") + ","
       } else {
         $column = $slowa[0] -replace '(.*)_.$','$1'
         $column = $column -replace '.*\.(.*)$','$1'
         $header2 += "'" + $column + "' kol" + $kolumna.toString("000") + ","
       }
      $wynik += $t + " kol" + $kolumna.toString("000") + ",`n"
     }
     $kolumna=$kolumna+1
   }
   $wynik = $wynik -replace ',$',''
   $header0 = $header0 -replace ',$',''
   $header1 = $header1 -replace ',$',''
   $header2 = $header2 -replace ',$',''
if ($headerPart)  {
   Write-Output $header0
   Write-Output "UNION ALL "
   Write-Output $header1
   Write-Output "UNION ALL "
   Write-Output $header2
} else {
   Write-Output $wynik
}
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
               $newObj | Add-Member -Name $("kol"+$numer.toString("000")) -Value $_.$field -MemberType NoteProperty
               
               $numer=$numer+1 
               }
            }
        }
       $newObj
    }
}





function get-listfacilities  ($name) {
ExecuteSqlQuery "select distinct FACILITY_REF,ORIGIN_DATE,MATURITY_DATE from CONTRACT where FACILITY_REF is not null and FACILITY_REF like `'%$name%`'"
}

function get-listfacility  ($name) {
ExecuteSqlQuery "select distinct SOURCE_CONTRACT_REF from CONTRACT`
 where (SOURCE_CONTRACT_REF = '$name' `
      or FACILITY_REF = '$name');"

}

function removeDups ($data, $keys) {
   $prevRow = @()
   $data | % {
      foreach ($attr in $keys) {
         $_.PSObject.properties.remove($attr)
      }
      $listA = $prevRow | Out-String
      $listB = $_ | Out-String
      if ( $listA -eq $listB ) {}
      else {
        $_
        $prevRow = $_
      }
   }
}

function significantLines ($data, $keys) {
   $prevRow = @()
   $wiersz=0
   $newData = $data | select -property *
   $newData | % {
      foreach ($attr in $keys) {
         $_.PSObject.properties.remove($attr)
      }
      $listA = $prevRow | Out-String
      $listB = $_ | Out-String
      if ( $listA -eq $listB ) {}
      else {
        $wiersz
        #$_
        $prevRow = $_
      }
      $wiersz=$wiersz+1
   }
}


function get-ifrs9summaryFinalWithParam() {

   $param = get-Parameter
   if ($param -ne $null) {
      get-ifrs9summaryFinal $param
   }
}


function get-ifrs9summaryFinal ($name) {
$pliki = "contracts.txt","ap.txt" ,"intereststreams.txt", "cashflows.txt", "iasevents.txt", "iasresults.txt", "iaseventresults.txt", "iasasofresults.txt"
#$pliki = "contracts.txt","ap.txt" ,"intereststreams.txt",  "iasevents.txt", "iasresults.txt", "iaseventresults.txt", "iasasofresults.txt"

#$category = "CONTR", "ADPMT", "INTST", "CASHF", "IASEV", "IASRS", "IASEVR", "IASASR"
$category = "CONTRACTS", "ADDITIONAL PMTS", "INTEREST STREAM","CASHFLOWS", "IAS EVENTS", "IAS RESULTS", "IAS EVENT RES", "IAS AS OF RES"

#$pliki = "iasevents.txt", "contracts.txt"
$queryEnds = @{}

$queryEnds.add("test3_wynik.txt", "  FROM CONTRACT c `
   --LEFT OUTER JOIN FACILITY_TYPE f on c.FACILITY_TYPE = f.FACILITY_TYPE_ENUM `
   --LEFT OUTER JOIN SPECIFIC_PRODUCT sp ON c.SPECIFIC_PRODUCT_ENUM=sp.SPECIFIC_PRODUCT_ENUM `
WHERE  (SOURCE_CONTRACT_REF = '$name' `
      or FACILITY_REF = '$name') ORDER BY SOURCE_CONTRACT_REF,SITUATION_DATE ;")


$queryEnds.add("contracts.txt", "  FROM CONTRACT c `
   LEFT OUTER JOIN FACILITY_TYPE f on c.FACILITY_TYPE = f.FACILITY_TYPE_ENUM `
   LEFT OUTER JOIN SPECIFIC_PRODUCT sp ON c.SPECIFIC_PRODUCT_ENUM=sp.SPECIFIC_PRODUCT_ENUM `
WHERE  (SOURCE_CONTRACT_REF = '$name' `
      or FACILITY_REF = '$name') ORDER BY sp.DESCRIPTION,SOURCE_CONTRACT_REF,SITUATION_DATE ;")
    
$queryEnds.add("ap.txt"," from  CONTRACT c,ADDITIONAL_PAYMENT ap`
  LEFT OUTER JOIN ADDITIONAL_PAYMENT_TYPE apt on ap.AP_TYPE_ENUM = apt.AP_TYPE_ENUM `
  where c.CONTRACT_ID = ap.CONTRACT_ID `
  and c.SITUATION_DATE = ap.SITUATION_DATE and`
--  ap.CONTRACT_ID  IN (`
--  SELECT CONTRACT_ID`
--  FROM CONTRACT c `
--WHERE  `
(SOURCE_CONTRACT_REF = '$name' `
      or FACILITY_REF = '$name') `
 -- ) `
 ORDER BY SOURCE_CONTRACT_REF,ap.ADDITIONAL_PAYMENT_REF,ap.SITUATION_DATE ;")
  
 $queryEnds.add("intereststreams.txt","  FROM CONTRACT c,INTEREST_STREAM intst`
WHERE c.CONTRACT_ID = intst.CONTRACT_ID `
and c.SITUATION_DATE = intst.SITUATION_DATE `
and --intst.CONTRACT_ID  IN (`
  --SELECT CONTRACT_ID`
  --FROM CONTRACT c `
--WHERE  `
 (SOURCE_CONTRACT_REF = '$name' `
      or FACILITY_REF = '$name') `
--  ) `
ORDER BY SOURCE_CONTRACT_REF,INTEREST_STREAM_ID,intst.SITUATION_DATE ;")
  
  $queryEnds.add("cashflows.txt"," FROM CONTRACT c,CASH_FLOW cf`
WHERE  c.CONTRACT_ID = cf.CONTRACT_ID `
and c.SITUATION_DATE = cf.SITUATION_DATE `
--and cf.CONTRACT_ID  IN (`
--  SELECT CONTRACT_ID`
--  FROM CONTRACT c `
--WHERE `
and (SOURCE_CONTRACT_REF = '$name' `
      or FACILITY_REF = '$name') `
--  )`
 ORDER BY cf.CONTRACT_ID,cf.SITUATION_DATE ;")
  
$queryEnds.add("iasevents.txt","from CONTRACT c, IAS_EVENT iasev LEFT OUTER  JOIN EVENT_TYPE ON iasev.EVENT_TYPE_ENUM = EVENT_TYPE.EVENT_TYPE_ENUM `
  where c.CONTRACT_ID = iasev.CONTRACT_ID `
and c.SITUATION_DATE = iasev.SITUATION_DATE and`
--  iasev.CONTRACT_ID  IN ( `
--  SELECT CONTRACT_ID `
--  FROM CONTRACT c `
--WHERE `
(SOURCE_CONTRACT_REF = '$name' `
      or FACILITY_REF = '$name') `
--  ) `
ORDER BY SOURCE_CONTRACT_REF, ADDITIONAL_PAYMENT_REF,iasev.SITUATION_DATE ;")
 
$queryEnds.add("iasresults.txt","from CONTRACT c,IAS_RESULT iasr`
  where c.CONTRACT_ID = iasr.CONTRACT_ID `
and c.SITUATION_DATE = iasr.SITUATION_DATE and`
--  iasr.CONTRACT_ID  IN (`
--  SELECT CONTRACT_ID`
--  FROM CONTRACT c `
--WHERE `
 (SOURCE_CONTRACT_REF = '$name' `
      or FACILITY_REF = '$name') `
--  ) `
ORDER BY SOURCE_CONTRACT_REF, ADDITIONAL_PAYMENT_REF,iasr.SITUATION_DATE ;")
  
 $queryEnds.add("iaseventresults.txt"," FROM CONTRACT c, IAS_EVENT_RESULT iaser`
WHERE c.CONTRACT_ID = iaser.CONTRACT_ID `
and c.SITUATION_DATE = iaser.SITUATION_DATE and`
-- iaser.CONTRACT_ID  IN (`
--  SELECT CONTRACT_ID`
--  FROM CONTRACT c `
--WHERE `
 (SOURCE_CONTRACT_REF = '$name' `
      or FACILITY_REF = '$name') `
--  ) `
ORDER BY SOURCE_CONTRACT_REF,iaser.SITUATION_DATE,EVENT_DATE ;")
  
 $queryEnds.add("iasasofresults.txt","  FROM CONTRACT c, IAS_AS_OF_RESULTS iasasr`
WHERE  c.CONTRACT_ID = iasasr.CONTRACT_ID `
and c.SITUATION_DATE = iasasr.SITUATION_DATE and`
--iasasr.CONTRACT_ID  IN (`
--  SELECT CONTRACT_ID`
--  FROM CONTRACT c `
--WHERE  `
 (SOURCE_CONTRACT_REF = '$name' `
      or FACILITY_REF = '$name') `
--  ) `
ORDER BY SOURCE_CONTRACT_REF, iasasr.ADDITIONAL_PAYMENT_REF, iasasr.SITUATION_DATE,iasasr.BALANCE_SHEET_DATE ;")
  $finalOutput = @()
  $finalOutputReduced = @()

  
  
  
$firstQuery = "SELECT ' ' CATEGORY,' ' kol001,' ' kol002,' ' kol003,' ' kol004,' ' kol005,' ' kol006,' ' kol007,' ' kol008,' ' kol009,
' ' kol010,' ' kol011,' ' kol012,' ' kol013,' ' kol014,' ' kol015,' ' kol016,' ' kol017,' ' kol018,' ' kol019,
' ' kol020,' ' kol021,' ' kol022,' ' kol023,' ' kol024,' ' kol025,' ' kol026,' ' kol027,' ' kol028,' ' kol029,
' ' kol030,' ' kol031,' ' kol032,' ' kol033,' ' kol034,' ' kol035,' ' kol036,' ' kol037,' ' kol038,' ' kol039,
' ' kol040,' ' kol041,' ' kol042,' ' kol043,' ' kol044,' ' kol045,' ' kol046,' ' kol047,' ' kol048,' ' kol049,
' ' kol050,' ' kol051 "
$firstQueryOutput = ExecuteSqlQuery $firstQuery | ConvertTo-Csv | ConvertFrom-Csv
$finalOutput += clear-nulls1 $firstQueryOutput $firstQueryOutput
$finalOutputReduced += clear-nulls1 $firstQueryOutput $firstQueryOutput


$nbOfFiles = $pliki.count
foreach ($numer in 1..$nbOfFiles) {
    $plik=$pliki[$numer-1]
    $data = Get-Content $plik
    $data = $data -split (' , ')
    $headerSql = get-sqlQuery $data $plik $numer $true
    $mainSql = get-sqlQuery $data $plik $numer $false
    
    $mainSql = $mainSql + $queryEnds[$plik]
    Write-Output $mainSql
    $queryOutput_header = ExecuteSqlQuery $headerSql | ConvertTo-Csv | ConvertFrom-Csv
    $queryOutput_main   = ExecuteSqlQuery  $mainSql | ConvertTo-Csv | ConvertFrom-Csv
    $queryOutput_main | Measure-Object
  
     
    $queryOutput_header1 = clear-nulls1 $queryOutput_main $queryOutput_header
    $queryOutput_main1   = clear-nulls1 $queryOutput_main $queryOutput_main
    
    $keys="SITUATION_DATE","SD", "ADDITIONAL_PAYMENT_ID", "UNAMORTIZED_AP"
 
 
 
 $locations = $queryOutput_header1[2] | % {foreach ($attr in $_.PSObject.properties) {
    if ($keys -contains $attr.Value) { $attr.Name }
  }}
 $locations
 
 $lines=significantLines $queryoutput_main1 $locations 
 $queryoutput_main1Reduced = $queryoutput_main1 | select -Index $lines
 $finalOutput += $queryoutput_header1 + $queryoutput_main1 
 $finalOutputReduced += $queryoutput_header1 + $queryoutput_main1Reduced 
 }
 $finalOutput | Format-Table -Property * -AutoSize | Out-String -Width 4096 | Out-File "EEE_wynik.txt"

 #$finalOutput | Out-GridView -Title $name
 $finalOutputReduced | Out-GridView -Title $name 
 
 }

function get-tablecontents () {

   $tableName = @("ZOBJECTS","CONTRACT","BSDATE","ACCOUNT_CATEGORY","CONTRACT_PLEDGEDASSET", "LOG_MESSAGE") | ogv -PassThru

   get-columns $tableName
}






function get-MDjsons () {

ls *.json | select -property Name, Length | ogv -PassThru `
 | % {Get-Content -Raw $_.Name | ConvertFrom-Json `
 | %   {$dane=$_.marketData.fxPriceTimeSeries.data;
        $def =$_.marketData.fxPriceTimeSeries.definition; 
        if ($dane -eq $null) {
          $dane=$_.marketData.assetPriceTimeSeries.data;
          $def =$_.marketData.assetPriceTimeSeries.definition;
        }
        $properties=$dane |  get-member -membertype noteproperty
        $properties_def = $def  |  get-member -membertype noteproperty
        
        $dane | % {
          $wiersz=New-Object -typename PSObject
            foreach ($elem in $properties) {
              $wiersz | Add-Member -MemberType NoteProperty -Name $elem.Name -Value $_.$($elem.Name)
            }
            foreach ($elem in $properties_def) {
              $wiersz | Add-Member -MemberType NoteProperty -Name $elem.Name -Value $def.$($elem.Name)
            }
          $wiersz
        }
       }
     } 
}



function get-alltablescontents () {


$query = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME"


$tableName  = ExecuteSqlQuery $query | ogv -PassThru | % {$_.TABLE_NAME}


get-columns $tableName

}



function get-columns ($tableName) {

    $query = "SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = N'___TABLENAME___'" -replace "___TABLENAME___","$tableName"

$nbOfColumns=0
$columns = ExecuteSqlQuery $query | ogv -PassThru | % {$_.COLUMN_NAME;$nbOfColumns=$nbOfColumns+1}
$nbOfColumns

if ($nbOfColumns -ne 0) {
$listOfColumns = ""
$columns | % { $listOfColumns = $listOfColumns + $_ + " , " }
$listOfColumns = $listOfColumns -replace ', $',''

$query = "Select $listOfColumns , count(*) _COUNT_ from $tableName group by $listOfColumns order by $listOfColumns"
$query

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
    $query
    $queryOutput   = ExecuteSqlQuery  $query | ConvertTo-Csv | ConvertFrom-Csv
     
    $queryOutput1 = clear-nulls-norename $queryOutput $queryOutput
    $queryOutput1 | ogv

}

Function clear-nulls-norenameOLD ($data, $data2) {
    
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



