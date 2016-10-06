<#
.Synopsis
   Gets a list of Unitrends Instant Recovery Jobs
.EXAMPLE
   
#>
function Get-UebIr {
	param()

	CheckConnection
	$response = UebGet("api/virtual_clients")

	$obj
	if($response.data.vm_ir.data.length -gt 0) 
	{
		$obj = $response.data.vm_ir.data 
	}

	if($response.data.hv_ir.data.length -gt 0)
	{
		$obj = $obt + $response.data.hv_ir.data
	}

	$prop = @('virtual_id','vm_name','status','mode')

	FormatUebResult $obj $prop
}
