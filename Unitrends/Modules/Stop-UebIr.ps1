<#
.Synopsis
   Stops a Unitrends Instant Recovery Job
.EXAMPLE
   
#>
function Stop-UebIr {
	param (
			[String] $Id
	)
	
		$t = "x"

		if($Id -like "*.vm_ir") {
			$t = "vm_ir"
		} elseif($Id -like "*.hv_ir") {
			$t = "hv_ir"
		} else {
			$t = "wir"
		}

		$body = New-Object PSObject -Property @{
			type = $t
		}

		$response = UebDelete "api/virtual_clients/$Id/?sid=1" $body
}
