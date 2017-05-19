Invoke-psake -buildFile "$PSScriptRoot\psake.ps1" -taskList "Deploy" -nologo -Verbose:$VerbosePreference
exit ( [int]( -not $psake.build_success ) )