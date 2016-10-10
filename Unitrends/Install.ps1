##Download

Write-Host "Downloading latest version of Unitrends PSToolkit ..." -ForegroundColor Cyan
$webclient = New-Object System.Net.WebClient
$url = "https://github.com/Unitrends/unitrends-pstoolkit/archive/master.zip"
$file = "$($env:TEMP)\Unitrends-pstoolkit.zip"
$webclient.DownloadFile($url,$file)


##Extract

Write-Host "Extracting latest version of Unitrends PSToolkit ..." -ForegroundColor Cyan
$targetondisk = "$($env:TEMP)"
$shell_app= New-object -com shell.application
$zip_file = $shell_app.namespace($file)
$destination = $shell_app.namespace($targetondisk)
$destination.Copyhere($zip_file.items(), 0x10)


##Install

Write-Host "Installing latest version of Unitrends PSToolkit ..." -ForegroundColor Cyan
$item = $targetondisk + "\unitrends-pstoolkit-master\Unitrends\"
$destination = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Unitrends"
cpi $item -Destination $destination -Recurse -Force


##Validate

Write-Host "Validating install ..." -ForegroundColor Cyan
$testfile = 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Unitrends\Unitrends.psm1'
$TestPath = Test-Path $testfile

If ($TestPath -eq $True)
    
    {
    Write-Host "Importing Unitrends Module..." -ForegroundColor Cyan
    Import-Module Unitrends -Force
    Write-Host "Installation Complete and module loaded!" -ForegroundColor Green
    
    ##Cleanup
    
    $path = $targetondisk + "\unitrends-pstoolkit-master"
    Remove-Item -Recurse $path -Force
    Remove-Item $file -Force
    
    ##END.
    }

Else {
    Write-Host "Installation Failed. Please check and try again." -ForegroundColor Red
    }
