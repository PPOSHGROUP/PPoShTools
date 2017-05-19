function Write-LogToStdOut() {
    <#
    .SYNOPSIS
    Outputs the Message to stdout using colors.
    
    .PARAMETER Header
    Message Header
    
    .PARAMETER Message
    Message body
    
    .PARAMETER Severity
    Severity

    .PARAMETER Emphasize
    Emphasize

    .EXAMPLE
    Write-LogToStdOut -Header "Header" -Message "Message" -Severity $Severity 
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [string] 
        $Header, 
        
        [string[]] 
        $Message, 
        
        [LogLevel] 
        $Severity, 
        
        [switch] 
        $Emphasize
    )
    
    Write-Host $Header -NoNewline -Fore "Gray"

    $color = switch ($Severity) {
        ([LogLevel]::ERROR) { [ConsoleColor]::Red }
        ([LogLevel]::WARN) { [ConsoleColor]::Yellow }
        ([LogLevel]::INFO) { 
            if ($Emphasize) { [ConsoleColor]::Cyan } else { [ConsoleColor]::White } 
        }
        ([LogLevel]::DEBUG) { [ConsoleColor]::Gray }
        default { [ConsoleColor]::Red }
    }

    foreach ($msg in $Message) {
        Write-Host $msg -Fore $color
    }
}