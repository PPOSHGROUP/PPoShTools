function Write-LogToStdOut() {
    <#
    .SYNOPSIS
        Outputs the Message to stdout using colors.
    
    .EXAMPLE
        Write-LogToStdOut -Header "Header" -Message "Message" -Severity $Severity 
    #>

    [CmdletBinding()]
    [OutputType([void])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    param(
        [Parameter(Mandatory=$false)]
        [string] 
        $Header, 
        
        [Parameter(Mandatory=$false)]
        [string[]] 
        $Message, 
        
        [Parameter(Mandatory=$false)]
        [int] 
        $Severity, 
        
        [Parameter(Mandatory=$false)]
        [switch] 
        $Emphasize,

        [Parameter(Mandatory=$false)]
        [switch] 
        $PassThru
    )

    if ($PassThru) {
        return
    }
    
    $color = switch ($Severity) {
        3 { [ConsoleColor]::Red }
        2 { [ConsoleColor]::Yellow }
        1 { 
            if ($Emphasize) { [ConsoleColor]::Cyan } else { [ConsoleColor]::White } 
        }
        0 { [ConsoleColor]::Gray }
        default { [ConsoleColor]::Red }
    }

    if ($Header) { 
        Write-Host -Object $Header.Substring(0, 3) -NoNewline -Fore $color
        Write-Host -Object $Header.Substring(3) -NoNewline -Fore "Gray"
    }

    if ($Message) { 
        foreach ($msg in $Message) {
            Write-Host $msg -Fore $color
        }
    }
}