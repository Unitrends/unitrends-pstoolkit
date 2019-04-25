param(
    $InstanceId,
    [string] $ConfigFile,
    [switch] $RestoreOnly = $false,
    [switch] $ImportOnly = $false,
    [string] $Path
)

# main code, dont modify

$ErrorActionPreference = 'Stop'

if (!(Test-Path "$restore_path/logs" -PathType Container)) {
    New-Item -ItemType Directory -Force -Path "$restore_path/logs"
}

 
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information',
        
        [Parameter()]
        [switch]$Init
    )

    $date = (Get-Date -f g)
	# Modified by BJT.
    $log = $restore_path + "logs/" + $instance + ".log"
    if($Init) {
        if (Test-Path $log)
        {
            Remove-Item $log -Force 
        }
    }

    "$date - [$severity] - $Message" | Out-File -Append -FilePath $log    
}

trap [Exception] {
      Write-Log -Severity Error -Message $("TRAPPED: " + $_.Exception.Message);
	  Write-Log -Severity Error -Message "ERROR:"
	  Write-Log -Severity Error -Message $_.InvocationInfo.PositionMessage
      Write-Log -Severity Error -Message "ExitCode: 9"
      Write-Error -Message "TRAPPED: $_.Exception.Message" -ErrorAction Continue
      Write-Error -Message $_.InvocationInfo.PositionMessage -ErrorAction Continue
      exit 9
}	

# functions


function Get-ParentPath {
    Param([String]$VHDPath)

    Write-Log -Message "Getting disk chain for file $VHDPath"

	$VHDSVC = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_ImageManagementService -ErrorAction Stop
    $VHDInfo = [xml]$VHDSVC.GetVirtualHardDiskSettingData($VHDPath).SettingData
	
    if ($VHDInfo) {
		$ParentPath = ($VHDInfo.INSTANCE.PROPERTY | Where { $_.Name -eq "ParentPath" }).Value
        if ($ParentPath) { 
			$Result = $VHDPath,$ParentPath 
            While ($ParentPath.Split(".")[1] -match "avhd") {
				$VHDInfo = [xml]$VHDSVC.GetVirtualHardDiskSettingData($ParentPath).SettingData
                $ParentPath = ($VHDInfo.INSTANCE.PROPERTY | Where { $_.Name -eq "ParentPath" }).Value
                $Result += $ParentPath
            }
            
            $Result | % { Write-Log -Message "  $_" }
        } else {
			$Result = $VHDPath  
            Write-Log -Message "Disk '$Result' is not a differencing disk - does not have any parent.." 
        }
    } else {
		Write-Log -Message "Disk file '$VHDPath' does not exist" 
    }
    
	$Result
}

function Merge-VMDisks {    

    Param( [Microsoft.HyperV.PowerShell.VirtualMachine] $VM)
    
    Write-Log -Message "Merge-VMDisks(): Starting disk merge"
    $VMDisks = $VM | Get-VMHardDiskDrive

    foreach ($Disk in ($VMDisks | Where { $_.Path -match ":" })) {
        $vdisk_path = $Disk.Path

        if(!(Test-Path $vdisk_path)) {
            # the disk in the config file doesnt exists lets see if there is an autorevery disk and use it.
            Write-Log -Message "The Disk '$($vdisk_path)' doesnt exist. Checking for vmdisk-AutoRecovery disk..."
        
            #if vdisk is not found check if there is vmdisk-autorecovery disk
	        if($vdisk_path.Contains(".avhdx")) { 
                $autorecovery_disk = $vdisk_path.Substring(0,$vdisk_path.Length - 43) + "-AutoRecovery.avhdx"
            } else { 
                $autorecovery_disk = $vdisk_path.Substring(0,$vdisk_path.Length - 42) + "-AutoRecovery.avhd"
            }
            
            #if no vmname-autorecovery disk is not found check if there is vmdisk-randomguid-autorecovery disk
            if(!(Test-Path $autorecovery_disk)){
                Write-Log -Message "The Disk '$($autorecovery_disk)' doesnt exist. Checking for vmdisk-randomguid-AutoRecovery disk..."

                if($vdisk_path.Contains(".avhdx")) { 
                    $vdisk_basename = $vdisk_path.Substring(0,$vdisk_path.Length - 43)
                    $filter = $vdisk_basename + "*-Autorecovery.avhdx"                    
                } else { 
                    $vdisk_basename = $vdisk_path.Substring(0,$vdisk_path.Length - 42)
                    $filter = $vdisk_basename + "*-Autorecovery.avhd"                    
                }
                $filter = Split-Path $filter -Leaf
                
                $dir_path = Split-Path $vdisk_path
                $i = Get-ChildItem -Path $dir_path -Filter $filter
                if($i) {
                   $autorecovery_disk = $i.FullName
                }      
            }

            if(Test-Path $autorecovery_disk){
                $vdisk_path = $autorecovery_disk
		        Write-Log -Message "AutoRecovery disk found, it will be used for merge ($vdisk_path)..."
            } else {
                throw "The disk used in config file $vdisk_path or $autorecovery_disk doesnt exists. Cant continue."
            }
        }

        $DiskTree = Get-ParentPath -VHDPath $vdisk_path
        if ($DiskTree.Count -gt 1) { 
            Write-Log -Message "Processing Disk '$($vdisk_path)'"
            for ($i=0; $i -lt $DiskTree.Count-1; $i++) {
                Write-Log -Message "  Merging file '$($DiskTree[$i])' # $($i+1) of $($DiskTree.Count-1) .." 
                Merge-VHD -Path $DiskTree[$i] -Confirm:$false -Force
            }
                
            $new_path = $DiskTree[$DiskTree.Count-1]
            Write-Log -Message "Setting disk path to $new_path .." 
            Set-VMHardDiskDrive -VMHardDiskDrive $Disk -Path $new_path
        }    
    }           
 } 

function Restore {
    Write-Log -Message "Restore(): Starting Restore"
    Import-Module Unitrends
    Connect-UebServer -Server $ueb -User $user -Password $pass | Out-Null
    
	# Modified by BJT.
	$catalog = ""
	if ($ueb_name)
	{
		$catalog = Get-UebCatalog -InstanceId $instance | Where-Object -Property system_name -eq $ueb_name
	}
	else
	{
		$catalog = Get-UebCatalog -InstanceId $instance
	}
    
    $backup_date = [datetime]::Parse($catalog.last_backup_date).ToString("yyyyMMdd_HHmmss")
    $backup_id = $catalog.last_backup_id
	# Modified by BJT.
    $vm_name = $replica_name_prefix + "_" + $catalog.asset + "_" + $catalog.asset_id + "_" + $backup_date
    $vm_name = $vm_name -replace " ","_"
    $directory = $restore_path + $vm_name
    $directory = $directory -replace " ","_"
    $directory_temp = $directory + "\unitrends_restore"
    
    
    $vm = Get-VM|where-object {$_.name -eq $vm_name}
    if($vm)
    {
        Write-Progress -Id $instance -Activity $instance -Status "Last backup is already restored. VM ($vm_name) already exists with backup_id $backup_id"  -PercentComplete 100 -completed
        Write-Warning "Last backup is already restored. VM ($vm_name) already exists with backup_id $backup_id"
        Write-Log -Severity Warning "Last backup is already restored. VM ($vm_name) already exists with backup_id $backup_id"
        exit 0
    }
      
    if (Test-Path $directory -PathType Container) {
        Remove-Item -Path $directory -Recurse -Force
    }
    
    Write-Progress -Id $instance -Activity $instance -Status "Restoring backup_id $backup_id to $directory_temp"  -PercentComplete 0 -completed
    
    Write-Log -Message "Restoring backup_id $backup_id to $directory_temp"
    $restore = Start-UebRestoreFile -backupID $catalog.last_backup_id -clientID $client_id -directory $directory_temp -flat $false -synthesis $false
    $restore_id = $restore.id
    
    $restore_job = $null
    while($restore_job -eq $null) {
        $restore_job = get-uebjob -Active|Where-Object {$_.id -eq $restore_id}
        Sleep 3
    }
    
    while($restore_job.status -eq "Queued" -or $restore_job.status -eq "Active" -or $restore_job.status -eq "Connecting")
    {
        Write-Progress -Id $instance -Activity $instance -Status "Restoring backup_id $backup_id to $directory_temp"  -PercentComplete $restore_job.percent_complete
        $restore_job = get-uebjob -Active|Where-Object {$_.id -eq $restore_id}
        Sleep 3
    }
    
    Write-Progress  -Id $instance -Activity $instance -Status "Restoring backup_id $backup_id to $directory_temp"  -PercentComplete 100 -completed
        
    return ,$directory
}

function Import
{
    param([string]$directory)

    Write-Log -Message "Import(): Starting Import"
    $vm_name = $directory|split-path -leaf
    $directory=$directory -replace "/","\"
    $directory_temp = $directory + "\unitrends_restore"     

    Write-Progress  -Id $instance -Activity $instance -Status "Import VM as $vm_name"  -PercentComplete 100 -completed    
    #check for open snapshots
    $xml_file = Get-ChildItem -Path $directory_temp -Recurse -include *.xml | Where-Object { $_.DirectoryName.EndsWith("Virtual Machines")}
    if($xml_file.Count -gt 1)
    {
        Write-Warning "Restored backup contains more than one .xml file in Virtual Machines folder"
        Write-Log -Severity Error -Message "Restored backup contains more than one .xml file in Virtual Machines folder"
        Exit 1
    }
   
    #copy config files from Virtual Machines
    if (Test-Path "$directory/config" -PathType Container) {
        Remove-Item -Path "$directory/config" -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path "$directory/config" | Out-Null
    $files = Get-ChildItem -Path $directory_temp -Recurse -include *.xml,*.preCheckpointCopy | Where-Object { $_.DirectoryName.EndsWith("Virtual Machines")}
    foreach($file in $files)
    {
        Copy-Item -Path $file.FullName -Destination "$directory/config"
    }

    #move vhd, vhdx rom temp restore dir to final dir
    $files = Get-ChildItem -Path $directory_temp -Recurse -include *.vhd,*.vhdx,*.avhd,*.avhdx
    foreach($file in $files)
    {
        Move-Item -Path $file.FullName -Destination $directory
    }


    $new_guid = [guid]::NewGuid().ToString().ToUpper()

    # check if restored VM is vmcx (hv2016) or xml (hv2012)
    $vmcx = Get-Item -Path "$directory\config\*.preCheckpointCopy"
    $vm_config = ""
    if($vmcx)  {
        $vm_config = $new_guid + ".vmcx"
        $new_vmrs = $new_guid + ".vmrs"
        Remove-Item -Path "$directory\config\*.vmcx"
        Copy-Item -Path $vmcx -Destination "$directory\config\$vm_config" -Force 
        Copy-Item -Path "$restore_path\empty_vmrs" -Destination "$directory\config\$new_vmrs" -Force
    } else  {
        $vm_config = $new_guid + ".xml"
        $xml = Get-Item -Path "$directory\config\*.xml"
        Rename-Item -Path $xml -NewName $vm_config
    }

    $vm_config = $directory + "\config\" + $vm_config

    #Start-Sleep 5

    Write-Log -Message "Running Compare-VM..."
    $retrycount = 0
    $completed = $false
    $secondsDelay = 2
    $retries = 5

    while (-not $completed) {
        try {
            $report = Compare-VM -Path $vm_config -Register
            Write-Log -Message "Command Compare-VM succeeded."
            $completed = $true
        } catch {
            if ($retrycount -ge $retries) {
                Write-Log -Message "Command Compare-VM failed the maximum number of $retrycount times."
                throw
            } else {
                Write-Log -Message "Command Compare-VM failed. Retrying in $secondsDelay seconds."
                Start-Sleep $secondsDelay
                $retrycount++
            }
        }
    }

    Write-Log -Message "Compare-VM Incompatibilities that we need to fix: $($report.Incompatibilities|Out-String)"
    Write-Log -Message "Fixing VMSavedState"
    $report.VM|Remove-VMSavedState -ErrorAction Ignore
    Write-Log -Message "Renaming VM to $vm_name"
    $report.VM|rename-vm -NewName $vm_name
    Write-Log -Message "Configuring all networks to $switch_name"
    $report.VM|Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName $switch_name
    $mem=$report.vm|Get-VMMemory
    $mem=$mem.Startup/1gb
    Write-Log -Message "Memory size: $mem GB"
    if( $mem -gt $max_vm_mem_gb )
    {
        Write-Log -Message "Memory size is too large: $mem GB, setting it to $max_vm_mem_gb GB"
        $report.vm|set-vmmemory -StartupBytes $($max_vm_mem_gb*1GB)
    }
    

    # wait 3 secs to saved state to be removed
    Sleep 5

    Write-Log -Message "Fixing all VM disks path to use base dir: $directory"
    # set harddisk location to restored folder
    $vhds = $report.VM | Get-VMHardDiskDrive
    foreach($vhd in $vhds)
    {
        $path = $vhd.Path
        $vhd_name = $path.Substring($path.LastIndexOf("\"))
        
        $new_path = $directory + $vhd_name
        Write-Log -Message "  New disk path: $new_path"
        Set-VMHardDiskDrive -VMHardDiskDrive $vhd -Path $new_path #�ControllerType $vhd.ControllerType �ControllerNumber $vhd.ControllerNumber -ControllerLocation $vhd.ControllerLocation
    }
    
    Merge-VMDisks -VM $report.VM
    Write-Log -Message "Removing VM Snapshots"
    $report.VM|Get-VMSnapshot|Remove-VMSnapshot

    Write-Log -Message "Running Import-VM..."
    $out = Import-VM $report | Out-String
    Write-Log -Message "Import-VM result: $out"
    $out

    Remove-Item -Path $directory_temp -Recurse -Force
}

function CleanUp 
{
    param([string]$directory)

    # remove previous restores
    Write-Log -Message "CleanUp(): Starting cleanup"
    $folder_path = $directory.Substring(0,$directory.Length - 15) + "*"
    $vm_prefix = Split-Path $folder_path -Leaf
    Write-Log -Message "Clean up dir: $folder_path"
    Write-Log -Message "Clean up vm prefix: $vm_prefix"

    $vms = get-vm -name $vm_prefix|Sort-Object -Descending|Select-Object -Skip $replicas_n
    foreach ($vm in $vms)
    {
        Write-Log -Message "Deleting VM $($vm.name)"
        Remove-VM -VM $vm -Force
        $remove_dir = (Split-Path $folder_path) + "\" + $vm.name
        Write-Log -Message "Deleting folder $remove_dir"
        Remove-Item -Path $remove_dir -Recurse -Force
    }

    #remove orphaned folders
    $folders = Get-Item $folder_path|Sort-Object -Descending -Property name|Select-Object -Skip $replicas_n
    foreach ($folder in $folders)
    {
        Write-Log -Message "Deleting orphaned folder $folder"
        Remove-Item -Path $folder -Recurse -Force
    }
}

# Samples()
#.\run_replica_id.ps1 -Instance 416
#.\run_replica_id.ps1 -Instance 416 -ConfigFile c:\vmtest\config_for_ueb01.ps1
#.\run_replica_id.ps1 -RestoreOnly
#.\run_replica_id.ps1 -ImportOnly -Path "c:\vmtest\replica\ueb02_378_nano01_20181122_231813"

$config_file = $ConfigFile

if(!$config_file) {
    $config_file= "$PSScriptRoot\run_replica_id.config.ps1"
}

if(!(Test-Path $config_file))
{
    Write-HOST "[ERROR] Config file $config_file doesnt exists"
    exit 1
}

. $config_file

if($InstanceId)
{
    $instance = $InstanceId
}

# Modified by BJT.
$log = $restore_path + "logs/" + $instance + ".log"
if(Test-Path $log) {
    if ((Get-Item $log).length -gt 500kb) {
        Remove-Item $log
    }
}

Write-Host "Starting..."
Write-Host "Check log file: $log"

Write-Log -Message "------------------------------------------------------------------------------------------------------------------ "
Write-Log -Message "Main(): Start"

Write-Log -Message "Using Config: `n ueb=$ueb `n user=$user `n pass=*** `n client_id=$client_id `n replica_name_prefix=$replica_name_prefix `n restore_path=$restore_path `n switch_name=$switch_name `n replicas_n=$replicas_n"

if($ImportOnly) 
{
    $directory = $Path
    Import $directory 
} 
elseif($RestoreOnly) 
{
    Restore
} 
elseif($CleanUpOnly)
{
    $directory = $Path
    CleanUp $directory
} 
else {
    $directory = Restore
    Import $directory 
    CleanUp $directory
}


Write-Log -Message "End(): Script Finished succesfully"