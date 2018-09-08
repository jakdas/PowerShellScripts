
. C:\Users\IEUser\selectFile.ps1

function analyze-logs($includeZOBJECTS,$minTime) {

$file = find-File

$previous_query=""
$hour_s=0
$minute_s=0
$second_s=0
$milisecond_s=0
$timeInMilis_s=0
$taskName = ""

Get-Content $file | % { 
   
   #$_
   if ($_ -notmatch "[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]") {
      $previous_query = $previous_query + $_ -replace "[ \t]+"," "
   } else {
   $hour_e = $_.substring(0,2)/1
   $minute_e = $_.substring(3,2)/1
   $second_e = $_.substring(6,2)/1
   $milisecond_e =$_.substring(9,3)/1
   $timeInMilis_e=$hour_e*60*60*1000+$minute_e*60000+$second_e*1000+$milisecond_e

   if ($_ -match "INSERT INTO LOG_MESSAGE" -and $_ -match "BeginTask") {
     $pos = $_.IndexOf("BeginTask")
     $rightPart = $_.Substring($pos)
     $rightPart = $rightPart -split "'"
     $taskName = $rightPart[6]
   }

   if ($previous_query -ne "") {
     $timeSpent =  $timeInMilis_e - $timeInMilis_s
     if ($includeZOBJECTS -eq 0 -and $previous_query -like "*ZOBJECTS*") {} else {
     if ($timeSpent -ge $minTime) {
     $previous_query = "`n" + $previous_query
     $previous_query = $previous_query -ireplace " and ","`n   AND "
     $previous_query = $previous_query -ireplace " from ","`n  FROM "
     $previous_query = $previous_query -ireplace "select ","`nSELECT "
     $previous_query = $previous_query -ireplace "insert into ","`nINSERT INTO "
     $previous_query = $previous_query -ireplace "delete ","`nDELETE "
     $previous_query = $previous_query -ireplace " where ","`n WHERE "
     $previous_query = $previous_query -ireplace "order by ","`nORDER BY "
     $previous_query = $previous_query -ireplace "group by ","`nGROUP BY "
     $previous_query = $previous_query -ireplace " values \(","`n  VALUES ("
     $previous_query = $previous_query + "`n" 
     $obiekt = New-Object -TypeName PSObject 
     $obiekt | Add-Member -MemberType NoteProperty -Name Duration -Value $timeSpent
     $obiekt | Add-Member -MemberType NoteProperty -Name TaskName -Value $taskName
     $obiekt | Add-Member -MemberType NoteProperty -Name QUERY -Value $previous_query
     
     $obiekt
     }
     }
     # "" + $($timeInMilis_e - $timeInMilis_s) + " " +$previous_query
      $previous_query=""

   }
   $query = $_ -replace "^.*>>> ",""
   $query = $query -replace "^.+][ `t]*","";
   if ($query -match "^insert into*" -or $query -match "^[ `t]*select " -or $query -match "^[ `t]*delete from ") {
      $previous_query = $query

   } else {
      $previous_query = ""
   }

   $hour_s = $_.substring(0,2)/1
   $minute_s = $_.substring(3,2)/1
   $second_s = $_.substring(6,2)/1
   $milisecond_s =$_.substring(9,3)/1
   $timeInMilis_s=$hour_s*60*60*1000+$minute_s*60000+$second_s*1000+$milisecond_s


}
}
}

