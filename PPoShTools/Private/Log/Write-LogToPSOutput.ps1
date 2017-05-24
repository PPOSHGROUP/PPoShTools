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
        
        [int] 
        $Severity,

        [Parameter(Mandatory=$false)]
        [switch] 
        $PassThru
    )

    if ($PassThru -and $Message) { 
        $msg = $Message -join "`r`n"
        Write-Output -InputObject "$Header$msg"
    }
}