
function get-sconscripts() {

$plik = Get-Content .\SConscripts4.txt

$rows = @()
$modul = ""

$columns = @(
"MODULE",
"ASCModuleType",
"ASCModuleFrameworksUsed",
"ASCModuleCCFLAGS",
"ASCModuleHeadersPaths",
"ASCModuleLibrariesPaths",
"ASCModuleLibraries",
"ASCModulePrivateHeaders",
"ASCShouldGenerateDefinesHeader",
"ASCShouldGenerateModuleHeader",
"ASCShouldInstallModuleHeader",
"ASCShouldInstallDefinesHeader",
"ASCModuleJavaVersion",
"ASCModuleJavacFlags",
"ASCModuleOutputJarDir")


$row = New-Object -typename psobject 
$columns | % { $row | Add-Member -MemberType NoteProperty -name $_ -value ""}

$rows +=$row

$plik | % {
  $tab = $_ -split "="
  if ($tab[0] -ne $modul) {
   if ($modul -ne "") {
      $rows += $row
   }
   $modul = $tab[0]
   $row = New-Object -typename psobject 
   $row | Add-Member -MemberType NoteProperty -name "MODULE" -value $tab[0]
   $tab[0]
  }
  #$tab[1] + "---> " + $tab[2]
  $row | Add-Member -MemberType NoteProperty -name $tab[1] -value $tab[2] -force
}
$rows |  ogv -PassThru

}

