function Escape-Markdown {
    <#
    .SYNOPSIS
    Escapes special characters for markdown.

    .PARAMETER String
    String to escape.

    .EXAMPLE
    Escape-Markdown -String '<test>'
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $String
    )

    return $String -replace '([^\\])<', '$1\<' `
                   -replace '([^\\])>', '$1\>'
}