**WARNING: These community scripts are “as is” & are not officially supported by Unitrends.**

Chat Room
---------

Want to chat with other members of the Unitrends community?

[![Join the chat at https://gitter.im/Unitrends/unitrends-pstoolkit](https://badges.gitter.im/Unitrends/unitrends-pstoolkit.svg)](https://gitter.im/Unitrends/unitrends-pstoolkit?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Engage, Contribute and Provide Feedback
---------------------------------------

Some of the best ways to contribute are to try things out, file bugs, and join in gitter conversations. You are encouraged to start a discussion by filing an issue. 

Looking for something to work on? The list of [issues](https://github.com/Unitrends/unitrends-pstoolkit/issues) is a great place to start.

**Request new features or report bugs:**

1. Open github [issue](https://github.com/Unitrends/unitrends-pstoolkit/issues)

Requirements
---------------------------------------

1. PowerShell 4.0+
2. Unitrends UEB/RS 9.0+

Download and getting started
---------------------------------------

**Download and install:**

1. Open Powershell as Administrator and allow execution of unsigned scripts by running command: Set-ExecutionPolicy Bypass
2. Run commmand to download last version and install:  
``` iwr https://raw.githubusercontent.com/Unitrends/unitrends-pstoolkit/master/Unitrends/Install.ps1 | iex ```

**Usage:**

    PS> Import-Module Unitrends
      [*] Welcome to Unitrends Powershell Toolkit! ---------------------------------------------------------
      
    Sample usage:   

            Connect-UebServer -Server ueb01 -User root -Password yourpass
            Get-UebJob
            Get-UebJob -Active
            Get-UebJob -Recent
            Get-UebJob -Active|Stop-UebJob
            Get-UebJob -Active|Stop-UebJob
            Get-UebJob -Name job1*|Start-UebJob
            Get-UebAlert
            Get-UebVirtualClient


    Copyright (C) Unitrends,Inc. All rights reserved.

**Update:**

Once installed you can update to last version using Cmdlet Update-UebPsToolkit

**Help:**

You can list all available cmdlets using:

PS C:\> Get-Uebhelp

**Blogs articles about Unitrends PsToolkit:**

[Unitrends PowerShell Toolkit](http://blogs.unitrends.com/unitrends-powershell-toolkit/)  
  
[How to create your own Powershell Cmdlets](http://blogs.unitrends.com/create-powershell-cmdlets/)  
  
[Automating backup protection of Virtual Machines using Powershell](http://blogs.unitrends.com/automating-backup-protection-virtual-machines-using-powershell/)  
  
[RPO, RPA: How to measure RPO compliance of your backups using Powershell](http://blogs.unitrends.com/rpo-rpa-measure-rpo-compliance-backups-using-powershell/)  
  
[Automate multiple Instant Recoveries from your backups using Powershell](http://blogs.unitrends.com/automate-multiple-instant-recoveries-backups-using-powershell/)  
  
[TO/RTA: How to measure RTO compliance of your backups using Powershell](http://blogs.unitrends.com/rtorta-measure-rto-compliance-backups-using-powershell/)  

