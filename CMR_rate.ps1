function ExecuteSqlQueryFromFile  ($con, $SQLQuery) {
                    $Datatable = New-Object System.Data.DataTable
               
                    $Connection = New-Object System.Data.SQLClient.SQLConnection
                    $connection.ConnectionString = $con
                    $Connection.Open()
                    $Command = New-Object System.Data.SQLClient.SQLCommand
                    $Command.Connection = $Connection
                    $Command.CommandText = $SQLQuery
                    $Reader = $Command.ExecuteReader()
                    $Datatable.Load($Reader)
                    $Connection.Close()
               
                    return $Datatable
 
                }

function executesqlquery ($query) {
    
    $con = get-DBConnection
    ExecuteSqlQueryFromFile $con $query
}


function get-DBconnection () {

 $data = get-content ".\connection.properties" -Raw | ConvertFrom-Json
 $connectionString = 'Server = ' + $data.Connection.Server + '; Database = ' + $data.Connection.Database + '; Integrated Security = false; User ID = ' + $data.Connection."User ID" `
                               + '; Password = ' + $data.Connection.Password + ';'
 $connectionString 

}


function get-kgrmd () {

$mdList = @("Assets","FX","Zero Curves", "Swaption Cubes", "Asset Volatility", "FX Volatility", "Caplet Volatility")
$mdMainQueries = @("select Id, RiskFactorMnemonic from rate..FxSpotPriceDefinition", 
                 "select count(*) from BSDATE")

$basicQueries = @{
"Assets" = "select RiskFactorMnemonic from rate..AssetDefinition"
"FX" = “select RiskFactorMnemonic from rate..FxSpotPriceDefinition”
"Zero Curves" = “select RiskFactorMnemonic from rate..YieldCurveDefinition”
"Swaption Cubes" = "select RiskFactorMnemonic from rate..SwaptionCubeDefinition"
"Asset Volatility" = "select RiskFactorMnemonic from rate..AssetVolSurfaceDefinition"
"FX Volatility" = "select RiskFactorMnemonic from rate..FxVolSurfaceDefinition"
"Caplet Volatility" = "select RiskFactorMnemonic from rate..CapletVolSurfaceDefinition"
}

$moreSpecificQueries = @{
"Assets" = "select md.AsOfDate from rate..AssetPrice as asset, rate..MarketData as md
 where asset.MarketDataId = md.Id
   and DefinitionId = (select Id from rate..AssetDefinition 
                        where RiskFactorMnemonic = '___MNEMONIC___')
 order by md.AsOfDate"
"FX" = "select md.AsOfDate from rate..FxSpotPrice as fx, rate..MarketData as md
 where fx.MarketDataId = md.Id
   and DefinitionId = (select Id from rate..FxSpotPriceDefinition 
                        where RiskFactorMnemonic = '___MNEMONIC___')
 order by md.AsOfDate"
"Zero Curves" = "select md.AsOfDate from rate..YieldCurve as yc, rate..MarketData as md
 where yc.MarketDataId = md.Id
   and DefinitionId = (select Id from rate..YieldCurveDefinition 
                        where RiskFactorMnemonic = '___MNEMONIC___')
 order by md.AsOfDate"
"Swaption Cubes" = "select md.AsOfDate from rate..SwaptionCube as sc, rate..MarketData as md
 where sc.MarketDataId = md.Id
   and DefinitionId = (select Id from rate..SwaptionCubeDefinition 
                        where RiskFactorMnemonic = '___MNEMONIC___')
 order by md.AsOfDate"
"Asset Volatility" = "select md.AsOfDate from rate..AssetVolSurface as sc, rate..MarketData as md
 where sc.MarketDataId = md.Id
   and DefinitionId = (select Id from rate..AssetVolSurfaceDefinition 
                        where RiskFactorMnemonic = '___MNEMONIC___')
 order by md.AsOfDate"
"FX Volatility" = "select md.AsOfDate from rate..FxVolSurface as fx, rate..MarketData as md
 where fx.MarketDataId = md.Id
   and DefinitionId = (select Id from rate..FxVolSurfaceDefinition 
                        where RiskFactorMnemonic = '___MNEMONIC___')
 order by md.AsOfDate"
"Caplet Volatility" = "select md.AsOfDate from rate..CapletVolSurface as fx, rate..MarketData as md
 where fx.MarketDataId = md.Id
   and DefinitionId = (select Id from rate..CapletVolSurfaceDefinition 
                        where RiskFactorMnemonic = '___MNEMONIC___')
 order by md.AsOfDate"
}

$detailedDataQueries = @{
"Assets" ="select md.AsOfDate, asset.Price from rate..AssetPrice as asset, rate..MarketData as md
 where asset.MarketDataId = md.Id
   and DefinitionId = (select Id from rate..AssetDefinition 
                        where RiskFactorMnemonic = '___MNEMONIC___')
   and md.AsOfDate = '___DATE___'"
"FX" = "select md.AsOfDate, fx.SpotPrice from rate..FxSpotPrice as fx, rate..MarketData as md
 where fx.MarketDataId = md.Id
   and DefinitionId = (select Id from rate..FxSpotPriceDefinition 
                        where RiskFactorMnemonic = '___MNEMONIC___')
   and md.AsOfDate = '___DATE___'"
"Zero Curves" = "select yp.MaturityDate, yp.Value from rate..YieldPoint yp
 where yp.YieldCurveId = (select yc.Id from rate..YieldCurve as yc, rate..MarketData as md
                              where yc.MarketDataId = md.Id   
                              and DefinitionId = (select ycd.Id from rate..YieldCurveDefinition as ycd
                                                    where ycd.RiskFactorMnemonic = '___MNEMONIC___')
                              and md.AsOfDate = '___DATE___')
                          order by yp.MaturityDate"
"Swaption Cubes" = "select scp.ExpiryDate, scp.MaturityDate, scp.Strike, scp.Vol from rate..SwaptionCubePoint scp
 where scp.SwaptionCubeId = (select sc.Id from rate..SwaptionCube as sc, rate..MarketData as md
                              where sc.MarketDataId = md.Id   
                              and DefinitionId = (select scd.Id from rate..SwaptionCubeDefinition as scd
                                                    where scd.RiskFactorMnemonic = '___MNEMONIC___')
                              and md.AsOfDate = '___DATE___')
      order by scp.ExpiryDate, scp.MaturityDate, scp.Strike"
"Asset Volatility" = "select avp.ExpiryDate, avp.Strike, avp.Vol from rate..AssetVolPoint avp
 where avp.AssetVolSurfaceId = (select avs.Id from rate..AssetVolSurface as avs, rate..MarketData as md
                              where avs.MarketDataId = md.Id   
                              and DefinitionId = (select avsd.Id from rate..AssetVolSurfaceDefinition as avsd
                                                    where avsd.RiskFactorMnemonic = '___MNEMONIC___')
                              and md.AsOfDate = '___DATE___')
       order by avp.ExpiryDate, avp.Strike"
"FX Volatility" = "select fxvp.ExpiryDate, fxvp.Strike, fxvp.Vol from rate..FxVolPoint fxvp
 where fxvp.FxVolSurfaceId = (select fxvs.Id from rate..FxVolSurface as fxvs, rate..MarketData as md
                              where fxvs.MarketDataId = md.Id   
                              and DefinitionId = (select fxvsd.Id from rate..FxVolSurfaceDefinition as fxvsd
                                                    where fxvsd.RiskFactorMnemonic = '___MNEMONIC___')
                              and md.AsOfDate = '___DATE___')
        order by fxvp.ExpiryDate, fxvp.Strike"
"Caplet Volatility" = "select cvp.CapletVolSurfaceId,cvp.ExpiryDate, cvp.Strike, cvp.Vol from rate..CapletVolPoint cvp
 where cvp.CapletVolSurfaceId = (select cvs.Id from rate..CapletVolSurface as cvs, rate..MarketData as md
                              where cvs.MarketDataId = md.Id   
                              and DefinitionId = (select cvsd.Id from rate..CapletVolSurfaceDefinition as cvsd
                                                    where cvsd.RiskFactorMnemonic = '___MNEMONIC___'
                                                    )
                              and md.AsOfDate = '___DATE___'
                              )
        order by cvp.ExpiryDate, cvp.Strike" 
}


$again=1
while ($again -eq 1) {
$category = $mdList | Out-GridView -PassThru 
$category
if ($category -eq $null)  {
  $again = 0
} else {
$basicQueries[$category]
$marketData = ExecuteSqlQuery $basicQueries[$category] | Out-GridView -PassThru | % {$_.RiskFactorMnemonic}
$marketData

$query = $moreSpecificQueries[$category] -replace "___MNEMONIC___",$marketData
$query
$date = ExecuteSqlQuery $query | Out-GridView -PassThru | % {$_.AsOfDate}
$date.ToShortDateString()

$query = $detailedDataQueries[$category] -replace "___MNEMONIC___", $marketData
$query = $query -replace "___DATE___", $date.ToShortDateString()
$query
$result = ExecuteSqlQuery $query | Out-GridView -PassThru

if ($result -eq $null) {
  $again = 0
}
}

}

}

get-kgrmd
