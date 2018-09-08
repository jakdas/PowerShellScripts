
function get-SD-jsons () {
$repeat = ""

$folder = Find-Folders
cd $folder
#cd Z:\Downloads\opics_datav1\StaticData
while ($repeat -ne $null) {
dir -Directory | select -property Name |  ogv -PassThru | % {

  "SELECTED: " +$_
  cd $_.Name
  $final = @()
  $files = ls *.json
  foreach ($file in $files) {
       $json = Get-Content -Raw $file.Name | ConvertFrom-Json
       $json | %   {
               $category = $_.staticData | Get-Member -MemberType NoteProperty | % {$_.Name}
               $wynik = $_.staticData.$category 
               #$repeat=$wynik | ogv -PassThru
               $final += $wynik
             }
   }
   $repeat = $final | ogv -PassThru
   cd ..
} 
} 
}

