$query1 = "
--NAME 
--CATEGORY 
--To jest opis
--To jest kolejna linia opisu
--I jeszcze jedna...
 SELECT Field1, Field2
  FROM CONTRACTS_SS5, DB2, DB3, adsfas
 WHERE DATE = '___Date__Podaj date ktorej potrzebujesz___'
   AND ID   = ___Contract_Id___
   AND NUMER = ___Amount__Podaj kwote___"


. C:\Users\IEUser\getParameter_mac.ps1

function build-query($query) {

$pola = @()
$values = @{}

$query -split "`n" | % { if ($_ -like "*___*___*") {
      $mnemonic=$_ -replace '^.*(___.*___).*$','$1'
      $mnemonic=$mnemonic -replace "___",""
      $pola = $pola + $mnemonic 
      }
    }

foreach ($pole in $pola) {
   $field = $pole -split "__"
   if ($field[1] -ne $null) {
     $descr= $field[1]
   } else {
     $descr= "Enter $($field[0])"
   }
   $values[$pole]= get-Parameter $descr
   $query=$query -replace "___$($pole)___",$values[$pole]
}

$query


}




