function Write-LogToStdOut() {
    <#
    .SYNOPSIS
        Outputs the Message to stdout using colors.
    
    .EXAMPLE
        Write-LogToStdOut -Header "Header" -Message "Message" -Severity $Severity 
    #>

    [CmdletBinding()]
    [OutputType([void])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", '')]
    param(
        [string] 
        $Header, 
        
        [string[]] 
        $Message, 
        
        [int] 
        $Severity, 
        
        [switch] 
        $Emphasize
    )
    
    Write-Host $Header -NoNewline -Fore "Gray"

    $color = switch ($Severity) {
        3 { [ConsoleColor]::Red }
        2 { [ConsoleColor]::Yellow }
        1 { 
            if ($Emphasize) { [ConsoleColor]::Cyan } else { [ConsoleColor]::White } 
        }
        0 { [ConsoleColor]::Gray }
        default { [ConsoleColor]::Red }
    }

    foreach ($msg in $Message) {
        Write-Host $msg -Fore $color
    }
}