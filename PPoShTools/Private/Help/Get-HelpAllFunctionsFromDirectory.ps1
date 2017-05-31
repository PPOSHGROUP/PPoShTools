function Get-HelpAllFunctionsFromDirectory {
    <#
    .SYNOPSIS
    Gets all functions from given directory.

    .PARAMETER Path
    Path to directory.

    .EXAMPLE
    $functionsToDocument = Get-HelpAllFunctionsFromDirectory -Path 'c:\MyModule'
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '')]
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )

    $allPs1Files = Get-ChildItem -Path $Path -Include "*.ps1" -Recurse | Select-Object -ExpandProperty FullName
    $result = New-Object -TypeName System.Collections.ArrayList
    foreach ($ps1File in $allPs1Files) {
        . $ps1File
        $funcName = (Split-Path -Path $ps1File -Leaf).Replace('.ps1', '')
        $cmd = Get-Command -Name $funcName -ErrorAction SilentlyContinue
        if (!$cmd) {
            throw "Cannot get command for function '$funcName'"
        }
        $help = $null
        # Get-Help does not work well for Configurations... we need to trick it it's a function
        if ($cmd.CommandType -eq 'Configuration') {

            $contents = Get-Content -Path $ps1File -ReadCount 0 | Out-String
            if ($contents -match '(?smi){.*(<#.*\.SYNOPSIS.*#>)') {
                $synopsis = $Matches[1]
                $cmdText = "function $($cmd.Name) {`r`n$synopsis`r`n}"
                Invoke-Expression $cmdText
                $help = Get-Help -Name $funcName -ErrorAction SilentlyContinue
            }
        }
        if (!$help) {
            $help = Get-Help -Name $funcName -ErrorAction SilentlyContinue
        }
        [void]($result.Add([PSCustomObject]@{
                FunctionName = $funcName
                Path = $ps1File
                Command = $cmd
                Help = $help
        }))
    }
    return $result.ToArray()
}