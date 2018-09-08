
function decode-alldbexport() {
$files = dir -Recurse -file -Filter "*.almDBExport" 
$i=1
foreach ($file in $files) {
    decode-dbexportTEST $file.FullName
    $i=$i+1
    if ($i % 100 -eq 0) {$i}
}

}

function decode-dbexport($file) {
$obiekt = New-Object -TypeName PSObject 
$wiersz="";$inside=0;Get-Content  $file |  `
% {if ($_ -notlike "*{*" -and $_ -notmatch "^[ `t]*};$" -and $inside -eq 1) {$_};             #zwykla, pojedyncza linia
if ($_ -notlike "*{*" -and $_ -notmatch "^[ `t]*};" -and $inside -gt 1) {$wiersz=$wiersz+$_}; #linia wewnatrz klamry
if ($_ -match "{$" -and $_ -notmatch "^{$") {$wiersz=$wiersz+$_;$inside=$inside+1};           #linia z klamra {,  nie pierwsza
if ($_ -match "\($" -and $_ -notmatch "^{$") {$wiersz=$wiersz+$_;$inside=$inside+1};           #linia z nawiasem ( 
if ($_ -match "^{$") {$inside=$inside+1}                                                      #linia pierwsza
if ($_ -match "^[ `t]*};$") {$inside=$inside-1};                                              #linia tylko z klamra } i srednikiem ;
if ($_ -match "^[ `t]*\);$") {$inside=$inside-1};                                              #linia tylko z klamra } i srednikiem ;
if ($_ -match "^[ `t]*},$") {$inside=$inside-1};                                              #linia tylko z klamra } i srednikiem ;
if ($_ -match "^[ `t]*};$" -and $inside -eq 1) {$wiersz=$wiersz+$_;$wiersz;$wiersz="";}} | % {$_ -replace "  ","" -replace "`t",""}  | `
 % {$tablica=$_ -split "=";if ($tablica[0] -ne "}") {
   [string]$val=$($tablica[1..20] -join "");$obiekt | add-member -MemberType NoteProperty -name $($tablica[0] -replace " ","") -value $val;} }

$obiekt
 }

 
function decode-dbexportTEST($file) {
$obiekt = New-Object -TypeName PSObject 
$shouldExit=0;
$wiersz="";$inside=0;Get-Content  $file |  `
% { 
if ($_ -like "*ALMClass*" -and $_ -like "*ALMSupervisoryReportTemplate*") {$shouldExit=1;continue}
if ($_ -like "*ALMClass*" -and $_ -like "*ALMConventionRecordActor*" -and $inside -eq 1) {$shouldExit=1;continue}
if ($_ -like "*ALMClass*" -and $_ -like "*ALMCRPEvaluationArea*" -and $inside -eq 1) {$shouldExit=1;continue}

if ($shouldExit -eq 1) {continue}
if ($_ -notlike "*{*" -and $_ -notlike "*(*" -and $_ -notmatch "^[ `t]*};$" -and $inside -eq 1) {$_};             #zwykla, pojedyncza linia
if ($_ -notlike "*{*" -and $_ -notmatch "^[ `t]*};" -and $inside -gt 1) {$wiersz=$wiersz+$_}; #linia wewnatrz klamry
if ($_ -match "{$" -and $_ -notmatch "^{$") {$wiersz=$wiersz+$_;$inside=$inside+1};           #linia z klamra {,  nie pierwsza
if ($_ -match "\($" -and $_ -notmatch "^{$") {$wiersz=$wiersz+$_;$inside=$inside+1};           #linia z nawiasem ( 
if ($_ -match "^{$") {$inside=$inside+1}                                                      #linia pierwsza
if ($_ -match "^[ `t]*};$") {$inside=$inside-1};                                              #linia tylko z klamra } i srednikiem ;
if ($_ -match "^[ `t]*\);$") {$inside=$inside-1};                                              #linia tylko z klamra } i srednikiem ;
if ($_ -match "^[ `t]*},$") {$inside=$inside-1};                                              #linia tylko z klamra } i srednikiem ;
if ($_ -match "^[ `t]*}$") {$inside=$inside-1};                                              #linia tylko z klamra } i srednikiem ;
if ($_ -match "^[ `t]*\);$" -and $inside -eq 1) {$wiersz=$wiersz+$_;$wiersz;$wiersz="";}
if ($_ -match "^[ `t]*};$" -and $inside -eq 1) {$wiersz=$wiersz+$_;$wiersz;$wiersz="";}}  | % {$_ -replace "  ","" -replace "`t",""}  | `
 % {$tablica=$_ -split "=";if ($tablica[0] -ne "}") { 
   if ($tablica[0] -ne $null -and $tablica[0] -ne "" -and $tablica[0] -ne "RowID " -and $tablica[0] -ne "<tdclass ") {
   [string]$val=$($tablica[1..20] -join ""); $obiekt | add-member -MemberType NoteProperty -name $($tablica[0] -replace " ","") -value $val;}} }

$obiekt
 }