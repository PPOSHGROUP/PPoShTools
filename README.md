# PSVeeamTools

[![Build status](https://ci.appveyor.com/api/projects/status/ewq04us7gf55pdmi/branch/master?svg=true)](https://ci.appveyor.com/project/DomBros/PSVeeamTools/branch/master)

PSVeeamTools
=============

PowerShell module with basic Tools for Veeam B&R mgmt

This is a PowerShell module with a variety of functions usefull in a day-to-day tasks.

Pull requests and other contributions are more than welcome!

## Instructions

```powershell

# One time setup
    # Download the repository
    # Unblock the zip
    # Extract the PSVeeamTools folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)

    #Simple alternative, if you have PowerShell 5, or the PowerShellGet module:
        Install-Module PSVeeamTools

# Import the module.
    Import-Module PSVeeamTools #Alternatively, Import-Module \\Path\To\PSVeeamTools

# Get commands in the module
    Get-Command -Module PSVeeamTools

# Get help
    Get-Help about_PSVeeamTools
```

# Examples

## Example 1
```powershell
Remove-VTvLabAllDependVM -Verbose
Set-VTvLabAllDependency -Verbose

$Cred = Get-Credential -Message 'Credentials for Scheduled Tasks creation and running' -UserName "$env:USERDOMAIN\$env:USERNAME" Set-VTVbrSureBackupScheduledTask -Credential $Cred
```

## Schema
```mermaid
graph TD
A[1. Remove SureBackup Jobs<br \>2. Remove Application Groups] -- Creation --> B[1. Take VM list fream Veeam Backup, remove duplicate, remove unwanted, sort it<br \>2. Take all hosts connected to Veeam<br \>3. Take all vLan for all VM on hosts]
B --> C[Take VM from list]
```