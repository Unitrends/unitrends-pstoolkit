function Get-UebBackup {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
		$Asset
	)

	CheckConnection
	
	$inst = $Asset
	if($Asset -is [String]) {
		$inst =  Get-UebCatalog -Name $Asset
	}

	$obj = $inst.backups
	$prop = @('id','type','start_date','system_name')

	FormatUebResult $obj $prop
}