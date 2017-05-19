function Write-LogToPSOutput() {
    <#
    .SYNOPSIS
        Outputs the Message using Write-Output function. Helper function.
    
    .EXAMPLE
        Write-LogToPSOutput -Header "Header" -Message "Message"
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

        [Parameter(Mandatory=$false)]
        [switch] 
        $PassThru
    )

    if ($PassThru) { 
        $msg = $Message -join "`r`n"
        Write-Output -InputObject "$Header$msg"
    }
}