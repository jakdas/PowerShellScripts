. .\sql_functions.ps1



function jkd-ND-attributes() {


$query =  "select INTERNAL_NAME from ZOBJECTS where OBJC_CLASS = 'ALMCRPEvaluationArea'
              and BITS = 'PMSCA'
              order by INTERNAL_NAME"

$results = ExecuteSqlQuery $query  


$selectedRow = $results  | ogv -PassThru

$ndCategory = $selectedRow.INTERNAL_NAME

$query = "select z2.OID,z2.INTERNAL_NAME,z2.OBJC_CLASS, z2.PLIST_STRING
 from ZOBJECTS as z2, ZOBJECTS as z1 
  where z1.INTERNAL_NAME = '" + $ndCategory + "'
    and z1.OBJC_CLASS = 'ALMCRPEvaluationArea' 
    and z1.PLIST_BLOB like '%AttributesDefinitions=(%' + z2.OID + '%;Methods%' 
    and z1.SITUATION_DATE = '00000000'
    and z2.OBJC_CLASS = 'ALMCRPAttributeDefinition'
    and z1.SITUATION_DATE = z2.SITUATION_DATE  
  order by z1.INTERNAL_NAME"

jkd-decodeOIDS $query   | ogv -PassThru

#$results = ExecuteSqlQuery $query

#$results | ogv -PassThru



}

function jkd-ND-parameters() {


$query =  "select INTERNAL_NAME from ZOBJECTS where OBJC_CLASS = 'ALMCRPEvaluationArea'
              and BITS = 'PMSCA'
              order by INTERNAL_NAME"

$results = ExecuteSqlQuery $query  


$selectedRow = $results  | ogv -PassThru

$ndCategory = $selectedRow.INTERNAL_NAME

$query = "select z2.OID,z2.INTERNAL_NAME,z2.OBJC_CLASS, z2.PLIST_STRING , z3.PLIST_STRING PLIST_STRING2
 from ZOBJECTS as z2, ZOBJECTS as z1 , ZOBJECTS as z3
  where z1.INTERNAL_NAME = '" + $ndCategory + "'
    and z1.OBJC_CLASS = 'ALMCRPEvaluationArea' 
    and z1.PLIST_BLOB like '%MethodsArray=(%' + z2.OID + '%' 
    and z1.SITUATION_DATE = '00000000'
    and z2.OBJC_CLASS = 'ALMCRPEvaluationMethod'
    and z1.SITUATION_DATE = z2.SITUATION_DATE  
    --and z2.PLIST_STRING like '%63E7FCBAC4EB4A3CB619705D64395450%'
    and z3.SITUATION_DATE = z2.SITUATION_DATE
    and z2.PLIST_STRING like '%Parameter=%' + z3.OID + '%' 
    and z3.OBJC_CLASS = 'ALMCreditRiskParameter'
  order by z1.INTERNAL_NAME"




jkd-decodeOIDS $query | select -property OID, CreditApproach, ParameterType, Internal_Name, Parameter, DecisionTable, Rule, Number_ | ogv -PassThru



#$results = ExecuteSqlQuery $query

#$results | ogv -PassThru



}



function jkd-decodeOIDS($query) {

$OIDS = prepare-OIDS
                                      
$results = ExecuteSqlQuery $query  | select -first 3000


$row
$rownr = 1
$results | % {
$json = $_.PLIST_STRING -replace "^{",""
$internal_name = $_.INTERNAL_NAME
$objc_class = $_.OBJC_CLASS
$oid = $_.OID
$json = $json -replace "}$",""
$json = $json -replace "Description=`"[^`"]+`"",""
$json = $json -split "[`t;](?=(?:[^`{`}]|[`{`}][^`{`}]*[`{`}])*$)"
$row = New-Object -TypeName PSObject
$row | Add-Member -Name "OID" -Value $oid -MemberType NoteProperty
$row | Add-Member -Name "INTERNAL_NAME" -Value $internal_name -MemberType NoteProperty
$row | Add-Member -Name "OBJC_CLASS" -Value $objc_class -MemberType NoteProperty

#$json
$col=4
foreach ($item in $json) {
  $name = $item -replace "=.*",""
  $valueORG = $item -replace "^[^=]+=",""
  $value = ""
  if ($valueORG -ne "") {
  #-----OIDS renaming

            if ($valueORG.substring(0,2) -eq "[@") {
              #$valueORG.substring(2) -replace "]",""
                              $value = $OIDS[$valueORG.substring(2) -replace "]",""]
            } else {
                $value=""
                #$tablica2[1]
                if ($($valueORG).length -gt 2 -and $valueORG.substring(0,3) -eq "([@") {
                             $valueORG | % { $($_ -replace "[()]","") -split "," } `
                              | % {$value = $value + "`n" + $OIDS[($_).substring(2) -replace "]",""]}
                              $value = $value -replace "^`n",""
               } else {
                     $value = $valueORG
                } 
            }

  #-----OIDS renaming

  }

  if ($name -ne "") {
    $row | Add-Member -Name $name -Value $value  -MemberType NoteProperty
    $col+=1
  }
}

$json = $_.PLIST_STRING2 -replace "^{",""
$json = $json -replace "}$",""
$json = $json -split "[`t;](?=(?:[^`{`}]|[`{`}][^`{`}]*[`{`}])*$)"
foreach ($item in $json) {
  $name = $item -replace "=.*",""
  $valueORG = $item -replace "^[^=]+=",""

  if ($valueORG -ne "") {
     if ($name -in ("ParameterType","CreditApproach")) {
        $valueORG = $valueORG -replace "`"",""
        $row | Add-Member -Name $name -Value $valueORG  -MemberType NoteProperty
     }
  }
}
$row.PsObject.Members.Remove('Description')
$row | Add-Member -Name "Number_" -Value $rownr  -MemberType NoteProperty
$rownr+=1
$row
}
$results = $null
}


