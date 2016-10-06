<#
.Synopsis
   Gets Alerts from connected Unitrends Appliance
.DESCRIPTION
   This cmdlet returns the alerts from the connected Unitrends Appliance. Use "Connect-UebServer" to connect.
.EXAMPLE
   Get-UebObject
#>
function Get-UebAlert {
	param()

	CheckConnection
	$response = UebGet("api/reports/system/alerts")

	$obj = $response.data
	$prop = @('sname','severity','created','message')

	FormatUebResult $obj $prop
}
