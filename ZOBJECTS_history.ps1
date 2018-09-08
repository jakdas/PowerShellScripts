
# require oids.ps1


function get-changes4SD() {


$firstQuery = "select SITUATION_DATE,COUNT(DISTINCT OID) CHANGED from ZOBJECTS_HISTO where 1=1
GROUP BY SITUATION_DATE"

$selectedRow = executesqlquery $firstQuery | ogv -PassThru
$selectedSD = $selectedRow.SITUATION_DATE

#wyswietla jakie obiekty sie zmienily
$secondQuery = "select SITUATION_DATE,OID,INTERNAL_NAME,OBJC_CLASS, COUNT(*) changed_times from ZOBJECTS_HISTO histo where OID in (
   SELECT DISTINCT OID FROM ZOBJECTS_HISTO histo1
    WHERE histo1.SITUATION_DATE=histo.SITUATION_DATE)
  AND histo.SITUATION_DATE = '$selectedSD'
GROUP BY SITUATION_DATE, OID, INTERNAL_NAME, OBJC_CLASS"

$selectedRow = executesqlquery $secondQuery | ogv -PassThru
$selectedOID = $selectedRow.OID

$thirdQuery = "select SITUATION_DATE,TICKET,BITS,OID,INTERNAL_NAME,OBJC_CLASS from ZOBJECTS_HISTO histo where OID in (
   SELECT DISTINCT OID FROM ZOBJECTS_HISTO histo1
    WHERE histo1.SITUATION_DATE=histo.SITUATION_DATE)
  AND histo.SITUATION_DATE = '$selectedSD'
  AND histo.OID = '$selectedOID'
ORDER BY TICKET DESC"

$selectedRow = executesqlquery $thirdQuery | ogv -PassThru

}
