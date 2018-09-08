#main function:    get-arc
#DESCRIPTION:      Both this file and its shortcut should be placed in the folder where ARC files are located.


Function clear-nulls-norename ($data, $data2) {
    
    $properties=$data[0].psobject.properties | % {$_.name} # | Get-Member -membertype noteproperty  | % {$_.Name}
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

function get-arc () {
 
 $folder = Find-Folders
  cd $folder
  $files = dir -file | % {
    $row = New-Object -TypeName PSObject
    $description = ""
    if ($_.Length -eq 0) {
     $description = "Empty file"
    } else {
      if ($_.Length -gt 20kb) {
        $description = "Many lines. (Size: " + $_.Length + ")"
      }
      else {
        $nbOfLines = (Get-Content $_) | Measure-Object -Line 
        if ($nbOfLines.Lines -eq 1) {
          $description = "Headers only"

        }
        else {
          $description = "" + $nbOfLines.Lines + " lines"
        }
      }
    }
    $row | Add-member -MemberType NoteProperty -Name File        -Value $_.Name
    $row | Add-Member -MemberType NoteProperty -Name Description -Value $description
    $row
  } 

  $again = 1
  while ($again -eq 1) {

  $selected = $files | ogv -PassThru
  if ($selected -eq $null) {
    $again=0
  } else {
    $selected.File

    if ($selected.description -eq "Empty file" -or $selected.description -eq "Headers only") {
      #
    } else {
      $importedCsv = Import-Csv -Path $selected.File -delimiter `t
      $output1 = clear-nulls-norename $importedCsv $importedCsv
      $result = $output1 | ogv -PassThru
      if ($result -eq $null) {
        $again = 0
      }
    }
    }
  }
}



