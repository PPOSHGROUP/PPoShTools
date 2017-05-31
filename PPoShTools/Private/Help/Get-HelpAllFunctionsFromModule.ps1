function Get-HelpAllFunctionsFromModule {
    <#
    .SYNOPSIS
    Gets all public functions from given module.

    .PARAMETER ModuleName
    Module name.

    .EXAMPLE
    $functionsToDocument = Get-HelpAllFunctionsFromModule -ModuleName $ModuleName
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ModuleName
    )

    Write-Log -Info "Getting functions from $ModuleName"
    $modulePath = Split-Path -Parent (Get-Module -Name $ModuleName -ListAvailable).Path
    $allPs1Files = Get-ChildItem -Path "$modulePath\Public" -Include "*.ps1" -Recurse | Select-Object -ExpandProperty FullName

    $result = New-Object -TypeName System.Collections.ArrayList
    foreach ($ps1File in $allPs1Files) {
        $funcName = (Split-Path -Path $ps1File -Leaf).Replace('.ps1', '')
        $cmd = Get-Command -Module $ModuleName -Name $funcName -ErrorAction SilentlyContinue
        if ($cmd) {
            $help = Get-Help -Name $funcName -ErrorAction SilentlyContinue
            [void]($result.Add([PSCustomObject]@{
                FunctionName = $funcName
                Path = $ps1File
                Command = $cmd
                Help = $help
            }))
        }
    }
    return $result.ToArray()
}