<#
.Synopsis
   Gets Backup Summary list from connected Unitrends Appliance
.DESCRIPTION
   This cmdlet returns a list of Backup Assets and summarized details from the connected Unitrends Appliance. Use "Connect-UebServer" to connect.
.EXAMPLE
   Get-UebBackupSummary
.EXAMPLE
   Get-UebBackupSummary | Where-Object {$_.type -match "Physical Server"} #Filters list to Physical Servers
#>
function Get-UebBackupSummary {
	[CmdletBinding()]
	param(
        [string]$rpo = 24
	)

	CheckConnection
	
	$response = UebGet("api/catalog")
	$instances = $response.catalog.instances
	
	[array]$vmlist = $null
	$date = Get-Date
    $rpo = New-TimeSpan -Hours $rpo

	foreach($i in $instances){
		$lastbackup = $i.backups | Sort-Object -Property start_date -Descending | Select-Object -First 1
		$backup_date = [datetime] $lastbackup.start_date
		$rpa = New-TimeSpan -Start $backup_date -End $date	
        $thisName = $i.database_name
        if ($i.app_type -eq "Physical Server"){ # Changes where Asset detail is pulled from depending on App_Type. Resembles the GUI more closely.
            $thisname =  $i.client_name
        }
        


        if($rpa -le $rpo) {
            $rpo_compliance = "OK"
        } else {
            $rpo_compliance = "Failed"
        }
            	

		$Object = New-Object PSObject -Property @{ 
			Asset = $thisname
			Backups = $i.backups.count
			RPO_Compliance = $rpo_compliance
			RPA = "$($rpa.days)d $($rpa.hours)h"
			RPAspan = $rpa
			Type = $i.app_type #Physical or Virtual
		}

		$vmlist += $Object
	}

	$obj = $vmlist
	$prop = @('VM','RPO_Compliance','RPA','Backups')

	FormatUebResult $obj $prop
}
