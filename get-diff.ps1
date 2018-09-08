. C:\Users\IEUser\sql_functions.ps1

function get-listSnapshots() {

   cd C:\TEMP
   $files = dir -file Snapshot-*.txt | Sort-Object -Property LastWriteTime 
   $twoFiles = $files | % {$_.BaseName} | ogv -PassThru

}

function get-diffMostRecent() {

  cd C:\TEMP
  $filenames =  dir -file Snapshot-*.txt | Sort-Object -Property LastWriteTime | select -Last 2
  $filenamesSD =  dir -file SnapshotSD-*.txt | Sort-Object -Property LastWriteTime | select -Last 2

  get-diff $filenames[0].BaseName $filenames[1].BaseName $filenamesSD[0].BaseName $filenamesSD[1].BaseName | ogv -PassThru
}

function get-diffSnapshots() {

   cd C:\TEMP
   $files = dir -file Snapshot-*.txt | Sort-Object -Property LastWriteTime 
   $twoFiles = $files | % {$_.BaseName} | ogv -PassThru

   get-diff $twoFiles[0] $twoFiles[1] $($twoFiles[0] -replace "Snapshot","SnapshotSD") $($twoFiles[1] -replace "Snapshot", "SnapshotSD") | ogv -PassThru

}

function get-diff($filename1, $filename2, $filenameSD1, $filenameSD2) {
  
  cd C:\TEMP
  $tabliceSD1 = @{}
  $file1 = Get-Content $($filename1+".txt")
  $file1 | % {$tab = $_ -split "[ ]+" ; $key=$tab[0];$tabliceSD1[$key]=$tab[1]} 
  #$tablice1

  $tabliceSD2 = [ordered]@{}
  $file2 = Get-Content $($filename2+".txt")
  $file2 |%  {$tab = $_ -split "[ ]+" ; $key=$tab[0];$tabliceSD2[$key]=$tab[1]} 
  #$tablice2

  
  
  $tablice1 = @{}
  $file1 = Get-Content $($filenameSD1+".txt")
  $file1 | % {$tab = $_ -split "[ ]+" ; $key=$tab[0]+"-"+$tab[1];$tablice1[$key]=$tab[2]} 
  #$tablice1

  $tablice2 = [ordered]@{}
  $file2 = Get-Content $($filenameSD2+".txt")
  $file2 |%  {$tab = $_ -split "[ ]+" ; $key=$tab[0]+"-"+$tab[1];$tablice2[$key]=$tab[2]} 
  #$tablice2

  $count=0
  
  foreach ($item in $tabliceSD2.keys) {
     if ($tabliceSD1[$item] -ne $tabliceSD2[$item])  {
         #$item + " DIFF " + $tabliceSD1[$item] + "->" + $tabliceSD2[$item]
          $count+=1
          $row = New-Object -TypeName PSObject
          $row | Add-Member -Name "TABLENAME" -Value $item  -MemberType NoteProperty
          $row | Add-Member -Name "SITUATION DATE" -Value ""  -MemberType NoteProperty
          $row | Add-Member -Name "OLD VALUE" -Value $tabliceSD1[$item]  -MemberType NoteProperty
          $row | Add-Member -Name "NEW VALUE" -Value $tabliceSD2[$item]  -MemberType NoteProperty
          $row | Add-Member -Name "DIFF" -Value $($tabliceSD2[$item] - $tabliceSD1[$item]) -MemberType NoteProperty
          $row
     }
  }


  foreach ($item in $tablice2.keys) {
     if ($tablice1[$item] -ne $tablice2[$item])  {
       #$item + " DIFF " + $tablice1[$item] + "->" + $tablice2[$item]
          $count+=1
          $row = New-Object -TypeName PSObject
          $tab = $item -split "-"
          $row | Add-Member -Name "TABLENAME" -Value $tab[0]  -MemberType NoteProperty
          $row | Add-Member -Name "SITUATION DATE" -Value $tab[1]  -MemberType NoteProperty
          $row | Add-Member -Name "OLD VALUE" -Value $tablice1[$item]  -MemberType NoteProperty
          $row | Add-Member -Name "NEW VALUE" -Value $tablice2[$item]  -MemberType NoteProperty
          $row | Add-Member -Name "DIFF" -Value $($tablice2[$item] - $tablice1[$item]) -MemberType NoteProperty
          $row
     }
  }
  if ($count -eq 0) {
          $row = New-Object -TypeName PSObject
          $row | Add-Member -Name "RESULT" -Value "There are no differences"  -MemberType NoteProperty
          $row
  }
} 

function make-snapshot () {
cd C:\TEMP
$dbname = get-databasename
$dbname
$stats=$(Get-Content ./stats_tables_count.sql) -replace "AAAA",$dbname   
$stats
$timestamp = [DateTime]::Now.ToString("yyyyMMdd-HHmmss")
ExecuteSqlQuery $stats | Out-File -Force $("Snapshot-" + $timestamp + ".txt")
$query=(Get-Content ./stats_tablesSD_count.sql) -replace "AAAA","$dbname"
$unions = ExecuteSqlQuery $query
$properUnions = $unions | % {if ($_.Column1 -like "*ZOBJECTS_HISTO*") {$_.Column1 -replace "UNION ALL",""} else {$_.Column1}}   
$properUnions += "ORDER BY TABNAME, SITUATION_DATE" 
$properUnions = $properUnions -replace "`"","'"
ExecuteSqlQuery $properUnions | Out-File -Force $("SnapshotSD-" + $timestamp + ".txt")

}

function remove-snapshots  () {
   cd C:\TEMP
   $files = dir -file Snapshot-*.txt | Sort-Object -Property LastWriteTime 
   $files2delete = $files | % {$_.BaseName} | ogv -PassThru

   foreach ($file in $files2delete) {
     $filename = $($file+".txt")
     "deleting $filename"
     Remove-Item $filename
     $filename = $($file -replace "Snapshot","SnapshotSD") + ".txt"
     "deleting $filename"
     remove-item $filename
   }
}


function get-snapshotOptions() {

$currentFolder = pwd

$options = @("Set DB connection",
             "Show DB connection",
             "Create a snapshot",#                 = "make-snapshot"
             "List snapshots",   #                 = "get-listSnapshots"
             "Compare two most recent snapshots",# = "get-diffMostRecent"
             "Compare two selected snapshots",#    = "get-diffSnapshots"
             "Delete some snapshots") #             = "remove-snapshots")

$again = 1

while ($again -eq 1) {

   $dbname = get-databasename
   $servername = Get-Servername
   $title = "Server: " + $servername + "  DB: " + $dbname

  $selected = $options | ogv -PassThru -Title $title

  if ($selected -eq $null) {
    $again = 0
  } 
  else {
    switch ($selected) {

      "Set DB connection"        { set-DBconnection }
      "Show DB connection"       { show-DBconnection }
      "Create a snapshot" {
                              make-snapshot 
                          }
      "List snapshots"    {
                              get-listSnapshots
                          }
      "Compare two most recent snapshots"  {
                                              get-diffMostRecent
                                           }
      "Compare two selected snapshots"     {
                                              get-diffSnapshots
                                           }
      "Delete some snapshots"              {
                                              remove-snapshots
                                           }
    }
  }
}
cd $currentFolder
}


get-snapshotOptions