
. C:\Users\IEUser\getARCfiles.ps1
. C:\Users\IEUser\selectFile.ps1
. C:\Users\IEUser\DecodeDBExport.ps1

function jkd-maps() {


$again=1

while ($again -ne $null) {
   Push-Location
   $selected = dir -Directory | ogv -PassThru

   cd $selected

   $again = dir | ogv -PassThru
   Pop-Location
}

}


function jkd-arc () {
 
 $filesMap = @{}
 $folder = Find-Folders
  cd $folder
  $files = dir -Recurse -file | % {
     "aaa"
     
    $row = New-Object -TypeName PSObject
    $description = ""
    if ($_.Length -eq 0) {
     $description = "Empty file"
    } else {
      if ($_.Length -gt 100kb) {
        $description = "Many lines. (Size: " + $_.Length + ")"
      }
      else {
        $nbOfLines = (Get-Content $_.FullName) | Measure-Object -Line 
        if ($nbOfLines.Lines -eq 1) {
          $description = "Headers only"

        }
        else {
          $description = "" + $nbOfLines.Lines + " lines"
        }
      }
    }
    $filesMap[$_.FullName] = $description

  } 
  $filesMap

  $again=1

  $rootDirectory = pwd
  Push-Location
while ($again -eq 1) {
   
     $currentDirectory = pwd
     if ($currentDirectory.Path -ne $rootDirectory.Path) {
       $title = "OK - Enter the folder or view the file , Cancel - return to previous menu"
     } else {
       $title = "OK - Enter the folder or view the file , Cancel - EXIT"
     }

   
   $selectedRow = dir | % {
    $row = New-Object -TypeName PSObject
    if ( (get-item $_.FullName)  -is [System.IO.DirectoryInfo] ) {
      $row | Add-member -MemberType NoteProperty -Name File        -Value $_.Name
      $row | Add-Member -MemberType NoteProperty -Name Description -Value "FOLDER"

    } else {
      $row | Add-member -MemberType NoteProperty -Name File        -Value $_.Name
      if ($_.Extension -eq ".almDBExport") {
        $name = $null
        $output = decode-dbexportTEST($_) 
        if ($output -ne $null) {
           $name = $output | % {$_.Name}
        }
        if ($name -eq $null) {$name = "???"}
        $name = $name -replace ";",""
      } else { 
        $name = $filesMap[$_.FullName]
      }
      $row | Add-Member -MemberType NoteProperty -Name Description -Value $name 
    }
    $row
   } | ogv -PassThru -title $title


   if ($selectedRow -ne $null) {
   if ($selectedRow.Description -eq "FOLDER") {
      cd $selectedRow.File

   } else {
      $again = 0
   }


   if ($selectedRow.Description -ne "FOLDER") {
       if ($selectedRow.Description -eq "Empty file" -or $selectedRow.Description -eq "Headers only") {
      $again = 1
    } else {
#
      if ($(Get-ChildItem $selectedRow.File).Extension -eq ".almDBExport") {
         $output1 = decode-dbexportTEST($(Get-ChildItem $selectedRow.File)) 
         $attrs = @()
         $output1 = $output1 | % {foreach ($param in $_.PSObject.properties) {
           if ($param.Name -like "*<head>*") {
             $attrs = $attrs + $param.Name
           }
           if ($param.Name -like "*</head>*") {
             $attrs = $attrs + $param.Name
           }
           if ($param.Name -like "*<body>*") {
             $attrs = $attrs + $param.Name
           }
           if ($param.Name -like "*</body>*") {
             $attrs = $attrs + $param.Name
           }
           if ($param.Name -like "*</html>*") {
             $attrs = $attrs + $param.Name
           }
           if ($param.Name -eq "Description") {
             $attrs = $attrs + $param.Name
           }
           if ($param.Name -eq "`";") {
             $attrs = $attrs + $param.Name
           }
         }
         foreach ($attr in $attrs) {
            $_.PSObject.properties.remove($attr)
         }
         $_
         }
         
         $result = $output1 | ogv -PassThru -title "OK - go 1 level up,   Cancel - return to the root folder"
      } else { 
         $importedCsv = Import-Csv -Path $selectedRow.File -delimiter `t
         $output1 = clear-nulls-norename $importedCsv $importedCsv
         $result = $output1 | ogv -PassThru -title "OK - go 1 level up,   Cancel - return to the root folder"
     }
      if ($result -eq $null) {
        $again = 1
        Pop-Location
        Push-Location
      } else {
        $again = 1     
      }
    }

   }
   } else {
     $currentDirectory = pwd
     $currentDirectory.Path
     $rootDirectory.Path
     if ($currentDirectory.Path -eq $rootDirectory.Path) {
        $again = 0
     } else {
        $again = 1
        Pop-Location
        Push-Location    
     }
   }
}
 

}

jkd-arc

