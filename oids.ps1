. .\sql_functions.ps1

function get-oidsFromDB ($OIDS) {

$query4oids="select OID, case when INTERNAL_NAME is not null then INTERNAL_NAME
else concat('no name (',OBJC_CLASS,')') end INTERNAL_NAME
  from ZOBJECTS 
 where (SITUATION_DATE = (select max(SITUATION_DATE) from BSDATE) 
     or SITUATION_DATE = '00000000')
 ;"

ExecuteSqlQuery $query4oids  | % {$OIDS[$_.OID]=$_.INTERNAL_NAME}  
#  where INTERNAL_NAME -like "*[a-zA-Z0-9]*" | % {$OIDS[$_.OID]=$_.INTERNAL_NAME}  

}

function prepare-OIDS() {
$OIDS=New-Object System.Collections.Hashtable

get-oidsFromDB($OIDS)
$OIDS
}


function get-dependentOIDS($OID) {

$query = "select * from ZOBJECTS 
                                    where PLIST_STRING not like '%DecisionRow%' 
                                      and OBJC_CLASS not in ('ALMConventionRecordActor') 
                                      and OBJC_CLASS not like 'ALMXbrl%' 
                                      and OBJC_CLASS not like '%TaskPrepared%'
                                      and PLIST_STRING like '%$OID%'
                                      and (SITUATION_DATE = (select max(SITUATION_DATE) from BSDATE) 
                                         or SITUATION_DATE = '00000000')"

#$results = ExecuteSqlQuery $query  

get-displayOIDS $query | ogv -PassThru
#$results  | ogv -PassThru

}

function get-browseByOBJCCLASS() {

$query = "select OBJC_CLASS, COUNT(*)  from ZOBJECTS 
                                    where PLIST_STRING not like '%DecisionRow%' 
                                      and OBJC_CLASS not in ('ALMConventionRecordActor') 
                                      and OBJC_CLASS not like 'ALMXbrl%' 
                                      and (SITUATION_DATE = (select max(SITUATION_DATE) from BSDATE) 
                                         or SITUATION_DATE = '00000000')
                                     GROUP BY OBJC_CLASS
                                     ORDER BY OBJC_CLASS"

$selectedType = $results = ExecuteSqlQuery $query  | ogv -PassThru 

if ($selectedType -ne $null) {

    $selectedRow = get-oidsWithNames $selectedType.OBJC_CLASS | ogv -PassThru

    if ($selectedRow -ne $null) {
       get-dependentOIDS $selectedRow.OID 
    }

}


}

function browse-dependingOIDS($OID) {
# petla
# wziac PLIST dla danego OID
# wywolac get-dependingOIDS dla tego PLIST
# wziac OID z wiersza wybranego
$currentOID = $OID
$OIDS = prepare-OIDS
$rootOID = $OID
$shouldExit = 0
$parentOID = ""
$depth=0
$tree=@($OID,"Level2","Level3","Level4","Level5")
while ($shouldExit -eq 0) {
"DEPTH=" + $depth
$query = "select IIF(PLIST_BLOB is null, PLIST_STRING, PLIST_BLOB) PLIST_STRING 
              from ZOBJECTS
             where OID = '$currentOID'"

$result = executesqlquery $query

$recordOID = get-dependingOIDS $result.PLIST_STRING $OIDS | ogv -PassThru -Title $currentOID

if ($recordOID -eq $null) {
  "Cancelling...."
      ""
    "TREE BEFORE"
    $tree
    "------"
  if ($rootOID -eq $currentOID) {
     $shouldExit = 1
     ""
     $OID
     "EXIT!!!!"
  }
    $depth=$depth-1
    $currentOID = $tree[$depth]
    "currentOID = " + $currentOID
    ""
        ""
    "DEPTH=$depth"
    "TREE BEFORE"
    $tree
    "------"
} else {
  if ($recordOID.OID -ne "") {
    ""
    "TREE BEFORE"
    $tree
    "------"
    
    $currentOID = $recordOID.OID
    $depth=$depth+1
    $tree[$depth]=$currentOID
  }
  "currentOID=" + $currentOID  
  ""
  "DEPTH=$depth"
      "TREE AFTER"
    $tree
    "------"


}


}

}



function get-dependingOIDS($PLIST, $OIDS) {

#  1. Wybrac dla danego OID zawartosc PLIST albo PBLOB
#  2. zrobic petle przez przez wszystkie matche


$resultlist = new-object System.Collections.Specialized.StringCollection
#$regex = [regex] '(Device\s#\d(\n.*)*?(?=\n\s*Device\s#|\Z))'
$regex = [regex] '@([0-9A-F]{32})'
$match = $regex.Match($PLIST)
while ($match.Success) {
    $resultlist.Add($match.Value) | out-null
    $match = $match.NextMatch()
} 
$oidsList = ""
$resultList  | % {$oidsList=$oidsList + "'" +  $_.substring(1) + "',"} 
$oidsList = $oidsList -replace ",$",""

if ($oidsList -eq "") {
  $oidsList = "'NO DATA'"
}
$query = "select OID, INTERNAL_NAME, OBJC_CLASS, 
                 IIF(PLIST_BLOB is null, PLIST_STRING, PLIST_BLOB) PLIST_STRING
                                     from ZOBJECTS where OID IN ($oidsList)
                                       and (SITUATION_DATE = (select max(SITUATION_DATE) from BSDATE) 
                                         or SITUATION_DATE = '00000000')"

get-displayOIDS $query $OIDS


}


function get-oids($name) {

$query = "select * from ZOBJECTS 
                                    where PLIST_STRING not like '%DecisionRow%' 
                                      and OBJC_CLASS not in ('ALMConventionRecordActor') 
                                      and OBJC_CLASS not like 'ALMXbrl%' 
                                      and OBJC_CLASS not like '%TaskPrepared%'
                                      and (OBJC_CLASS like '%$name%' OR INTERNAL_NAME like '%$name%')
                                      and (SITUATION_DATE = (select max(SITUATION_DATE) from BSDATE) 
                                         or SITUATION_DATE = '00000000')"

$results = ExecuteSqlQuery $query  | select -first 3000


$row = New-Object -TypeName PSObject
$row | Add-Member -Name "OID" -Value "" -MemberType NoteProperty
$row | Add-Member -Name "INTERNAL_NAME" -Value "" -MemberType NoteProperty
$row | Add-Member -Name "OBJC_CLASS" -Value "" -MemberType NoteProperty
foreach ($item in 4..30) {
  $row | Add-Member -Name $("Column "+$item) -Value ""  -MemberType NoteProperty
}
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
$sep = New-Object -TypeName PSObject
$header = New-Object -TypeName PSObject
$row = New-Object -TypeName PSObject
$sep | Add-Member -Name "OID" -Value $oid -MemberType NoteProperty
$header | Add-Member -Name "OID" -Value $oid -MemberType NoteProperty
$row | Add-Member -Name "OID" -Value $oid -MemberType NoteProperty
$sep | Add-Member -Name "INTERNAL_NAME" -Value $internal_name -MemberType NoteProperty
$header | Add-Member -Name "INTERNAL_NAME" -Value $internal_name -MemberType NoteProperty
$row | Add-Member -Name "INTERNAL_NAME" -Value $internal_name -MemberType NoteProperty
$sep | Add-Member -Name "OBJC_CLASS" -Value $objc_class -MemberType NoteProperty
$header | Add-Member -Name "OBJC_CLASS" -Value $objc_class -MemberType NoteProperty
$row | Add-Member -Name "OBJC_CLASS" -Value $objc_class -MemberType NoteProperty

#$json
$col=4
foreach ($item in $json) {
  $name = $item -replace "=.*",""
  $value = $item -replace "^[^=]+=",""
  #$name + "-----" + $value
  if ($name -ne "") {
    $sep | Add-Member -Name $("Column "+$col) -Value "" -MemberType NoteProperty
    $header | Add-Member -Name $("Column "+$col) -Value $name -MemberType NoteProperty
    $row | Add-Member -Name $("Column "+$col) -Value $value  -MemberType NoteProperty
    $col+=1
  }
}
if ($col -lt 31) {
  $row | Add-Member -Name "Column 30" -Value $rownr  -MemberType NoteProperty
}
$rownr+=1
$sep
$header
$row
}

}

function get-oidsLikeObjcClass($name) {
  
  get-oidsWithNames $name

}


function get-oids4AttributesByType() {

$types = @{"Attributes"="ALMAttribute";
           "Map Attributes"="ALMMapAttribute";
           "Decision Tables"="ALMDecisionTableAttribute";
           "Expression Attributes"="ALMExpressionAttribute";
           "Range Attributes"="ALMRangeAttribute"}


 $selectedType = $types.keys | ogv -PassThru

 $objc_className = $types[$selectedType]

  $query = "select * from ZOBJECTS 
                                    where PLIST_STRING not like '%DecisionRow%' 
                                      and OBJC_CLASS not in ('ALMConventionRecordActor') 
                                      and OBJC_CLASS not like 'ALMXbrl%' 
                                      and OBJC_CLASS = '$objc_className'
                                      and (SITUATION_DATE = (select max(SITUATION_DATE) from BSDATE) 
                                         or SITUATION_DATE = '00000000')"
get-displayOIDS $query  

}

function get-oids4Attributes($name) {

  $query = "select * from ZOBJECTS 
                                    where PLIST_STRING not like '%DecisionRow%' 
                                      and OBJC_CLASS not in ('ALMConventionRecordActor') 
                                      and OBJC_CLASS not like 'ALMXbrl%' 
                                      and INTERNAL_NAME like '%$name%'
                                      and OBJC_CLASS in ('ALMAttribute','ALMMapAttribute','ALMDecisionTableAttribute','ALMExpressionAttribute','ALMRangeAttribute')
                                      and (SITUATION_DATE = (select max(SITUATION_DATE) from BSDATE) 
                                         or SITUATION_DATE = '00000000')"


get-displayOIDS $query  

}

function get-oidsLikeInternalName($name) {
  
  $query = "select * from ZOBJECTS 
                                    where PLIST_STRING not like '%DecisionRow%' 
                                      and OBJC_CLASS not in ('ALMConventionRecordActor') 
                                      and OBJC_CLASS not like 'ALMXbrl%' 
                                      and INTERNAL_NAME like '%$name%'
                                      and (SITUATION_DATE = (select max(SITUATION_DATE) from BSDATE) 
                                         or SITUATION_DATE = '00000000')"


get-displayOIDS $query  

}

function get-oidsWithNames($name) {

$query = "select * from ZOBJECTS 
                                    where PLIST_STRING not like '%DecisionRow%' 
                                      and OBJC_CLASS not in ('ALMConventionRecordActor') 
                                      and OBJC_CLASS not like 'ALMXbrl%' 
                                      and OBJC_CLASS like '%$name%'
                                      and (SITUATION_DATE = (select max(SITUATION_DATE) from BSDATE) 
                                         or SITUATION_DATE = '00000000')"


get-displayOIDS $query

}

function get-displayOIDS($query,$OIDS) {

if ($OIDS -eq $null) {
   $OIDS = prepare-OIDS
}
                                      
$results = ExecuteSqlQuery $query  | select -first 3000


$row = New-Object -TypeName PSObject
$row | Add-Member -Name "OID" -Value "" -MemberType NoteProperty
$row | Add-Member -Name "INTERNAL_NAME" -Value "" -MemberType NoteProperty
$row | Add-Member -Name "OBJC_CLASS" -Value "" -MemberType NoteProperty
foreach ($item in 4..30) {
  $row | Add-Member -Name $("Column "+$item) -Value ""  -MemberType NoteProperty
}
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
$sep = New-Object -TypeName PSObject
$header = New-Object -TypeName PSObject
$row = New-Object -TypeName PSObject
$sep | Add-Member -Name "OID" -Value $oid -MemberType NoteProperty
$header | Add-Member -Name "OID" -Value $oid -MemberType NoteProperty
$row | Add-Member -Name "OID" -Value $oid -MemberType NoteProperty
$sep | Add-Member -Name "INTERNAL_NAME" -Value $internal_name -MemberType NoteProperty
$header | Add-Member -Name "INTERNAL_NAME" -Value $internal_name -MemberType NoteProperty
$row | Add-Member -Name "INTERNAL_NAME" -Value $internal_name -MemberType NoteProperty
$sep | Add-Member -Name "OBJC_CLASS" -Value $objc_class -MemberType NoteProperty
$header | Add-Member -Name "OBJC_CLASS" -Value $objc_class -MemberType NoteProperty
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

  #$name + "-----" + $value
  if ($name -ne "") {
    $sep | Add-Member -Name $("Column "+$col) -Value "" -MemberType NoteProperty
    $header | Add-Member -Name $("Column "+$col) -Value $name -MemberType NoteProperty
    $row | Add-Member -Name $("Column "+$col) -Value $value  -MemberType NoteProperty
    $col+=1
  }
}
if ($col -lt 31) {
  $row | Add-Member -Name "Column 30" -Value $rownr  -MemberType NoteProperty
}
$rownr+=1
$sep
$header
$row
}
$results = $null
}

function get-tasks ($processName) {



$query4tasks = "select  z1.INTERNAL_NAME PROCESS_NAME, z2.INTERNAL_NAME,  
iif(z2.PLIST_BLOB is null,substring(z2.PLIST_STRING,charindex('ContextKeys=',z2.PLIST_STRING)+13, 
          charindex('}',substring(z2.PLIST_STRING,charindex('ContextKeys=',z2.PLIST_STRING)+13,len(z2.PLIST_STRING)))-1),
substring(z2.PLIST_BLOB,charindex('ContextKeys=',z2.PLIST_BLOB)+13, 
          charindex('}',substring(z2.PLIST_BLOB,charindex('ContextKeys=',z2.PLIST_BLOB)+13,len(z2.PLIST_BLOB)))))
  from ZOBJECTS z2, ZOBJECTS z1
 where (z2.SITUATION_DATE = (select max(SITUATION_DATE) from BSDATE)
     or z2.SITUATION_DATE = '00000000')
    and z1.SITUATION_DATE = z2.SITUATION_DATE
    and z1.INTERNAL_NAME like '%"+$processName+"%' 
    and z1.PLIST_STRING like '%Tasks=(%' + z2.OID + '%' 
    and z2.OBJC_CLASS like 'ALMTaskPrepared'
    and charindex('ContextKeys=',z2.PLIST_STRING)>0
 order by PROCESS_NAME,charindex(z2.OID,z1.PLIST_STRING); "

ExecuteSqlQuery $query4tasks 
}



function get-tasksdetails ($processName) {


$OIDS = prepare-OIDS
$finalResults=@()
$firstRow = New-Object PSObject;
    $firstRow | Add-Member -MemberType NoteProperty -Name "Process Name" -Value " "
    $firstRow | Add-Member -MemberType NoteProperty -Name "Task_Name" -Value " "
    1..20 | % {
      $firstRow | Add-Member -MemberType NoteProperty -Name $("Field"+$_.toString("00")) -Value " "
    }
$finalResults += $firstRow
#$finalResults;

$gettasks = get-tasks $processName
$gettasks | convertto-csv | convertfrom-csv | select -first 50 | 
  foreach-object {
     $properties = $_ | get-member -membertype NoteProperty | % {$_.Name} 
     $row=New-Object PSObject;
     $header0=New-Object PSObject;
     $header1=New-Object PSObject;

            $row | Add-Member -MemberType NoteProperty `
                              -Name "Process Name" `
                              -Value $_.PROCESS_NAME
 
            $header0 | Add-Member –MemberType NoteProperty `
                              -Name "Process Name" `
                              -Value $_.PROCESS_NAME

            $header1 | Add-Member –MemberType NoteProperty `
                              -Name "Process Name"`
                              -Value $_.PROCESS_NAME 

            $row | Add-Member -MemberType NoteProperty `
                              -Name "Task_Name" `
                              -Value $_.INTERNAL_NAME
 
            $header0 | Add-Member –MemberType NoteProperty `
                              -Name "Task_Name" `
                              -Value " "

            $header1 | Add-Member –MemberType NoteProperty `
                              -Name "Task_Name"`
                              -Value $_.INTERNAL_NAME 

     $tablica=$_.Column1 -split ";";
     $field=1;
     foreach ($attr in $tablica) {
        if ($attr -like "*[a-zA-Z0-9]*") {
            $tablica2=$attr -split "=";
            if ($tablica2[1].substring(0,2) -eq "[@") {
                              $value = $OIDS[($tablica2[1]).substring(2) -replace "]",""]
            } else {
                $value=""
                #$tablica2[1]
                if ($($tablica2[1]).length -gt 2 -and $tablica2[1].substring(0,3) -eq "([@") {
                             $tablica2[1] | % { $($_ -replace "[()]","") -split "," } `
                              | % {$value = $value + "`n" + $OIDS[($_).substring(2) -replace "]",""]}
                              $value = $value -replace "^`n",""
               } else {
                     $value = $tablica2[1]
                } 
            }
            $row | Add-Member -MemberType NoteProperty `
                              -Name $("Field"+$field.toString("00")) `
                              -Value $value
 
            $header0 | Add-Member –MemberType NoteProperty `
                              -Name $("Field"+$field.toString("00")) `
                              -Value " "

            $header1 | Add-Member –MemberType NoteProperty `
                              -Name $("Field"+$field.toString("00")) `
                              -Value $tablica2[0] 
        }
        $field=$field + 1
    
     };

    
     $finalResults = $finalResults + $header0 + $header1 + $row
  } 
   $output = $finalResults | ogv -PassThru
}

