function New-MarkdownDoc {
    <#
    .SYNOPSIS
    Generates markdown documentation for each public function from given module.

    .PARAMETER ModulePath
    Module to scan.

    .PARAMETER OutputPath
    Base output path.

    .PARAMETER GitBaseUrl
    Base Git url to generate links to source files.

    .EXAMPLE
    New-MarkdownDoc -ModuleName 'PSCI' -OutputPath '..\PSCI.wiki\api' -GitBaseUrl 'https://github.com/ObjectivityBSS/PSCI/tree/master'
    #>

    [CmdletBinding(DefaultParameterSetName = 'Module')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName = 'Module')]
        [string]
        $ModulePath,

        [Parameter(Mandatory=$true, ParameterSetName = 'Directory')]
        [string]
        $DirectoryPath,

        [Parameter(Mandatory=$true)]
        [string]
        $OutputPath,

        [Parameter(Mandatory=$false)]
        [string]
        $GitBaseUrl
    )

    if ($DirectoryPath) {
        $DirectoryPath = (Resolve-Path -LiteralPath $DirectoryPath).ProviderPath
        $ModulePath = $DirectoryPath
    }

    $ModuleName = Split-Path -Path $ModulePath -Leaf
    if ((Test-Path -Path $OutputPath)) {
        Write-Log -Info "Deleting directory '$OutputPath'"
        Remove-Item -Path $OutputPath -Recurse -Force
    }
    [void](New-Item -Path $OutputPath -ItemType Directory -Force)

    $outputIndexString = New-Object -TypeName System.Text.StringBuilder
    [void]($OutputIndexString.Append("## Module $ModuleName`r`n"))

    if ($PSCmdlet.ParameterSetName -eq 'Directory') {
        $functionsToDocument = Get-HelpAllFunctionsFromDirectory -Path $DirectoryPath
    }
    else {
        $functionsToDocument = Get-HelpAllFunctionsFromModule -ModulePath $ModulePath -ModuleName $ModuleName
    }
    foreach ($funcInfo in $functionsToDocument) {
        $outputString = Generate-MarkdownForFunction -FunctionInfo $funcInfo -OutputIndexString $outputIndexString -ModulePath $ModulePath -ModuleName $moduleName -GitBaseUrl $GitBaseUrl

        $outputFilePath = Join-Path -Path $OutputPath -ChildPath "$($funcInfo.FunctionName).md"
        $outputString.ToString() | Out-File -FilePath $outputFilePath
    }

    $outputIndexPath = Join-Path -Path $OutputPath -ChildPath "$ModuleName.md"
    $outputIndexString.ToString() | Out-File -FilePath $OutputIndexPath

    $Script:currentRelativeLocation = $null
}
