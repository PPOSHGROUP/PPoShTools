function Generate-MarkdownForFunction {
    <#
    .SYNOPSIS
    Generates markdown for specified function.

    .PARAMETER FunctionInfo
    FunctionInfo object as created by Get-AllFunctionsFrom* function.

    .PARAMETER OutputIndexString
    String builder for index markdown.

    .PARAMETER ModuleName
    Name of the module the function belongs to.

    .PARAMETER ModulePath
    Path to the module the function belongs to.

    .PARAMETER GitBaseUrl
    Base Git url to generate links to source files.

    .EXAMPLE
    $outputString = Generate-MarkdownForFunction -FunctionInfo $funcInfo -OutputIndexString $outputIndexString -ModulePath $modulePath -GitBaseUrl $GitBaseUrl
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $FunctionInfo,

        [Parameter(Mandatory=$true)]
        [object]
        $OutputIndexString,

        [Parameter(Mandatory=$true)]
        [string]
        $ModuleName,

        [Parameter(Mandatory=$true)]
        [string]
        $ModulePath,

        [Parameter(Mandatory=$false)]
        [string]
        $GitBaseUrl
    )

    $funcName = $FunctionInfo.FunctionName
    $help = $FunctionInfo.Help

    
    if ((Split-Path -Path $ModulePath -Leaf) -ine 'public') {
        $public = Get-ChildItem -Path $ModulePath -Filter 'public' -Directory | Select-Object -ExpandProperty Name
        $modulePublicPath = Join-Path -Path $ModulePath -ChildPath $public
    } 
    else {
        $modulePublicPath = $ModulePath
    }
    $basePathSlash = $ModulePath -ireplace '\\', '/'

    $arrParameterProperties = @(
        'DefaultValue',
        'PipelineInput',
        'Required'
    )

    Write-Log -Info "Generating markdown for $funcName"

    $funcRelativeLocation = (Split-Path -Path $FunctionInfo.Path -Parent).Replace("$modulePublicPath\", '')
    if ($funcRelativeLocation -ne $Script:currentRelativeLocation) {
        [void]($OutputIndexString.Append("`r`n### $funcRelativeLocation`r`n"))    
        $Script:currentRelativeLocation = $funcRelativeLocation
    }
    

    $outputString = New-Object -TypeName System.Text.StringBuilder
    [void]($OutputIndexString.Append("* [[$funcName]]"))
    [void]($outputString.Append("## $funcName`r`n"))
    $gitLink = ($FunctionInfo.Path -ireplace '\\', '/').Replace($basePathSlash, $GitBaseUrl)
    [void]($outputString.Append("[[$ModuleName]] -\> [$funcName.ps1]($gitLink)`r`n"))
        
    if ($help.Synopsis) {
        [void]($OutputIndexString.Append(" - $($help.Synopsis)`r`n"))
        [void]($outputString.Append("### Synopsis`r`n"))
        [void]($outputString.Append("$($help.Synopsis)`r`n"))
    } 
    else {
        [void]($outputIndexString.Append("`r`n"))
    }

    if ($help.Syntax) {
        [void]($outputString.Append("### Syntax`r`n"))
        $syntax = ($help.Syntax | Out-String -Width 80).Trim()
        [void]($outputString.Append("``````PowerShell`r`n$syntax`r`n```````r`n"))
    }

    if ($help.Description) {
        [void]($outputString.Append("### Description`r`n"))
        [void]($outputString.Append("$($help.Description.Text)`r`n`r`n"))
    }

    if ($help.Parameters) {
        [void]($outputString.Append("### Parameters`r`n"))
        foreach ($item in $help.Parameters.Parameter) {
            [void]($outputString.Append("#### -$($item.Name)\<$($item.Type.Name)\>"))

            if ($item.defaultValue) {
                [void]($outputString.Append(" (default: $($item.defaultValue))"))
            }
            [void]($outputString.Append("`r`n"))
            if ($item.Description.Text) { 
                $escapedDescription = Escape-Markdown -String $item.Description.Text
                [void]($outputString.Append($escapedDescription))
                [void]($outputString.Append("`r`n"))
            }
            [void]($outputString.Append("`r`n<!---->`r`n"))

            $validateSetAttributes = $FunctionInfo.Command.Parameters.$($item.Name).Attributes | Where-Object { $_.TypeId.FullName -eq 'System.Management.Automation.ValidateSetAttribute' }
            if ($validateSetAttributes) {
                $validateSetStr = ($validateSetAttributes.ValidValues -replace '^$', '\<empty\>') -join ', '
                if ($validateSetStr.StartsWith(',')) {
                    $validateSetStr = '$null' + $validateSetStr
                }
                [void]($outputString.Append("- **Valid values**: $validateSetStr`r`n"))
            }

            foreach ($arrParamProperty in $arrParameterProperties){
                if ($item.$arrParamProperty){
                        [void]($outputString.Append("- **$arrParamProperty**: $($item.$arrParamProperty)`r`n"))
                }
            }
            [void]($outputString.Append("`r`n"))
        }
    }

    if ($help.Examples) {
        [void]($outputString.Append("### Examples`r`n"))
        foreach ($item in $help.Examples.Example) {
            $example = $item.title.Replace("--------------------------","").Replace("EXAMPLE","Example")
            [void]($outputString.Append("`r`n#### $example`r`n"))
            if ($item.Code) {
                [void]($outputString.Append("``````PowerShell`r`n"))
                # if code starts with ``` it means it special case - we need to put remarks inside ```. See https://connect.microsoft.com/PowerShell/feedbackdetail/view/952833.
                if (!$item.Code.StartsWith('```')) {
                    [void]($outputString.Append("$($item.Code)`r`n"))
                    [void]($outputString.Append("```````r`n"))
                }
            }
            if ($item.Remarks) {
                foreach ($remark in $item.Remarks.Text) { 
                    if ($remark -and $remark.Trim()) { 
                        [void]($outputString.Append("$($remark.Trim())`r`n"))
                    }
                }
            }
        }
    }

    return $outputString.ToString()
}