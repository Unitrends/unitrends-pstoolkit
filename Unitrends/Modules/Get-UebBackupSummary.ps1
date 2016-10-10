<#
.Synopsis
   Gets Backup Summary list from connected Unitrends Appliance
.DESCRIPTION
   This cmdlet returns a list of Backup Assets and summarized details from the connected Unitrends Appliance. Use "Connect-UebServer" to connect.
.PARAMETER DATE
    Supply either an INT/number for 'days back from today' or a date formatted as MM/DD/YYYY. If no date is supplied the default 7 days of backups will be retrieved.
.EXAMPLE
   Get-UebBackupSummary
.EXAMPLE
   Get-UebBackupSummary | Where-Object {$_.type -match "Physical Server"} #Filters list to Physical Servers
.EXAMPLE
   Get-UebBackupSummary -date 20  # Gets Backups going back 20 Days
#>
function Get-UebBackupSummary {
	[CmdletBinding()]
	param(
        [string]$rpo = 24,
        [string]$date
	)

	CheckConnection
    
    # Handle Date Parameter
    if ($date -ne $null){
        # Handle 10/07/2016 Style Dates
        if (([regex]"/").match($date).Success){
            Try
            {
                $StartDate = Get-Date $date -format MM/dd/yyyy
            }
            Catch
            [System.Management.Automation.ParameterBindingException]
            {
                Write-Output "Invalid date, please check and try again."
            }
        }
        # Handle "Days Ago" Style dates
        ElseIF(([regex]"\D").match($date).Success -eq $false)
        {
            $StartDate = (Get-Date).AddDays(-$date).ToString("MM/dd/yyyy")
        }
        Else
        {
            Write-Output "Date is invalid, ignoring"
            $date = $null
        }
    }	
    
    # Build 
    $apiPath = "api/catalog"
    if ($date -ne $null){
        $apiPath += ("/?start_date=" + $StartDate)
    }
    
    
	$response = UebGet($apiPath)
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
	$prop = @('Asset','RPO_Compliance','RPA','Backups')

	FormatUebResult $obj $prop
}
