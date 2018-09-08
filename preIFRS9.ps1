. C:\Users\IEUser\selectFile.ps1

function jkd-renameFolders($startDate) {

$folder = Find-Folders
cd $folder

$isOK = jkd-renameFoldersDryRun $startDate | ogv -PassThru

if ($isOK -ne $null) {

$today=[Datetime]$startDate
$pliki = dir -Directory *day* | sort 
foreach ($i in $pliki) { 
   if ($today.dayofweek -eq 'Sunday' -or $today.dayofweek -eq 'Saturday') {$today=$today.AddDays(1);}  
   if ($today.dayofweek -eq 'Sunday' -or $today.dayofweek -eq 'Saturday') {$today=$today.AddDays(1);} 
   $newDirName='{0:yyyyMMdd}' -f $today
   Rename-Item -path $i -NewName $newDirName
   $today=$today.AddDays(1)
}
} else {
 "Nothing has been renamed..."
}
}


function jkd-renameFoldersDryRun($startDate) {


$today=[Datetime]$startDate
$pliki = dir -Directory *day* | sort 
foreach ($i in $pliki) { 
   if ($today.dayofweek -eq 'Sunday' -or $today.dayofweek -eq 'Saturday') {$today=$today.AddDays(1);}  
   if ($today.dayofweek -eq 'Sunday' -or $today.dayofweek -eq 'Saturday') {$today=$today.AddDays(1);} 
   $newDirName='{0:yyyyMMdd}' -f $today
   $i.Name + " -> " +  $newDirName
   $today=$today.AddDays(1)
}
}


function jkd-selectFacility() {

$selected = dir -Recurse | where name -eq "Contracts.almGenericFile"  | `
 % {$_.FullName} | % {Import-Csv -delimiter `t $_ | select FacilityReference}   | `
 where FacilityReference -ne $null | where FacilityReference -ne "" | Sort-Object -property FacilityReference -Unique  | ogv -PassThru

 ,$selected.FacilityReference
}

function jkd-reduceData() {

$fileNames = @("AdditionalPayments.almGenericFile",
"Cashflows.almGenericFile",
"Contracts.almGenericFile",
"Events.almGenericFile",
"FacilityLimits.almGenericFile")

$fileNames
$selectedFacility = jkd-selectFacility
"SELECTED FACILITY"
$selectedFacility
$selectedFacility.count

$contracts=@()
#$contracts = $contracts + $selectedFacility.FacilityReference

$selectedFacility | % {$contracts=$contracts + $_}


if ($selectedFacility.Count -gt 0) {

$filesToBeProcessed = dir -Recurse | where {$_.Name -eq "Contracts.almGenericFile"} 
foreach ($file in $filesToBeProcessed) 
{
  
  Import-Csv -delimiter `t -path $file.FullName | where { $_.FacilityReference -in $selectedFacility} | `
     select -property ContractReference | % {if ($_.ContractReference -notin $contracts) {$contracts = $contracts + $_.ContractReference}}

}
"KONTRAKTY...."
$contracts
"_______"
""


$filesToBeProcessed = dir -Recurse | where {$_.Name -in $fileNames}

foreach ($file in $filesToBeProcessed) 
{
$FILE.FullName
$data1=$null
$nazwa=$file.FullName

Copy-Item -Path $nazwa -Destination $($nazwa+"_ORG")
$data1=Import-Csv -delimiter `t -path $nazwa  | where {( $_.ContractReference -in $contracts) -or ( $_.FacilityReference -in $contracts)} 
#$data1
if ($true) { #($data1 -ne $null) {
  "Files being changed..."
  $data1 | Export-Csv  -NoTypeInformation -Delimiter `t -Path $($nazwa+"_")
  Get-Content -Path $($nazwa+"_")  | % {$_ -replace  "`"",""} | Out-File -Encoding ascii -FilePath $nazwa
} else {
   "No changes..."
}

}
}
}


function jkd-runSeveralProcesses() {

 $folders = dir -Directory 

 foreach ($SD in $folders) {
   "Situation Date: " + $SD.BaseName

   Copy-Item -Path $SD/


 }

}

