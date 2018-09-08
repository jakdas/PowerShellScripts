

function browse-jsons() {

$folder = Find-Folders
cd $folder
$wynik="a";
while ($wynik -ne $null) {
                            $file = ls *.json | select -property Name, Length | ogv -PassThru 
                            if ($file -eq $null) {
                               $wynik = $null
                            } else {
                            $file | `
                                % {
                                    $wynik=Get-Content -Raw $_.Name | ConvertFrom-Json | `
                                      % {
                                          $_.attributesList
                                        } | ogv -PassThru
                                  }
                            }
                         }   
}

