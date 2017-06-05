# PPoShTools


[![Build status](https://ci.appveyor.com/api/projects/status/ewq04us7gf55pdmi/branch/master?svg=true)](https://ci.appveyor.com/project/PPOSHGROUP/pposhtools/branch/master)

PPoshTools
=============

PowerShell module with basic Tools

This is a PowerShell module with a variety of functions usefull in a day-to-day tasks.

Pull requests and other contributions are more than welcome!

## Instructions

```powershell
# One time setup
    # Download the repository
    # Unblock the zip
    # Extract the PPoshTools folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)

    #Simple alternative, if you have PowerShell 5, or the PowerShellGet module:
        Install-Module PPoshTools

# Import the module.
    Import-Module PPoshTools #Alternatively, Import-Module \\Path\To\PPoshTools

# Get commands in the module
    Get-Command -Module PPoshTools

# Get help
    Get-Help about_PPoshTools
```