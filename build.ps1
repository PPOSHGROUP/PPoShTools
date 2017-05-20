$Global:ErrorActionPreference = 'Stop'
$Global:VerbosePreference = 'Continue'

Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

Install-Module PSDepend
Invoke-PSDepend -Force

Set-BuildEnvironment -Force

Invoke-psake -buildFile "$PSScriptRoot\psake.ps1" -nologo -Verbose:$VerbosePreference
exit ( [int]( -not $psake.build_success ) )