<#
.Synopsis
   Submits a Restore Job
.DESCRIPTION

.PARAMETER SID
    System ID of the Unitrends Appliance.
.PARAMETER BackupID
    Backup ID to be restored   
.PARAMETER ClientID
    ID of the Client Machine
.PARAMETER Directory
    Location on the server to re-direct this restore to. If blank, restore will go to where it was backed up from.
.PARAMETER Includes
    List of file paths to include into the restore
.PARAMETER Excludes
    List of file paths to exclude from the restore
.EXAMPLE
    #Need one/More
#>
function Start-UebRestoreJob{
param(
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
    [int]$sid = 1,
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [int]$backupID,
    [int]$clientID,
    [string]$directory,
    [string[]]$includes,
    [string[]]$excludes
)
# Verb Options?   Start- Submit-




#region RestoreObject
# Build the Restore Object, make $target, $theseIncludes, $theseExcludes, then make $body out of all and more
# Build Target
$target = @{
    flat = $true
    non_destructive = $true
    newer = $true
    today = $false
    unix = $true
    directory = $directory
}

#Build Include(s) and Exclude(s)
[array]$theseIncludes = $includes
[array]$theseExcludes = $excludes

#Build Body
$body = @{
    backup_id = $backupID
    client_id = $clientID
    target = $target
    before_cmd = ""
    after_cmd = ""
    synthesis = $true
    includes = $theseIncludes
    excludes = $theseExcludes
}
#endregion RestoreObject


UebPost "/api/restore/full/?sid=$sid" $body







}
