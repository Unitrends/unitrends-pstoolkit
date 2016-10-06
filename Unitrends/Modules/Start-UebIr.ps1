<#
.Synopsis
   Starts a Unitrends Instant Recovery Job
.EXAMPLE
   
#>
function Start-UebIr {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
		$Host,
		$Name,
		$Datastore,
		$BackupId,
		[switch] $Live,
		$Address
	)
	process {
		
		$audit = $true

		if($Live) {
			$audit = $false
		}

		$target = New-Object PSObject -Property @{ 
				host = $Host
				name = $Name
				datastore = $Datastore
		}

		$Object = New-Object PSObject -Property @{ 
			target = $target
			backup_id = $BackupId
			audit = $audit
			address = $Address
		}
		
		$response = UebPost "api/restore/instant/?sid=1" $Object
	}
}

