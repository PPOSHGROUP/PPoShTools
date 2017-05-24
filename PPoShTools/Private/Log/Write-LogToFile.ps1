function Write-LogToFile() {
    <#
    .SYNOPSIS
        Outputs the Message to file. Helper function.

    .EXAMPLE
        Write-LogToFile -Header "Header" -Message "Message" -Severity $Severity 
    #>

    [CmdletBinding()]
    [OutputType([void])]
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
        $PassThru
    )

    if (!(Get-Variable -Scope Script -Name LogConfiguration -ErrorAction SilentlyContinue)) {
        return
    }
    
    if (!$Script:LogConfiguration.LogFile) {
        return
    }

    $logFile = $Script:LogConfiguration.LogFile

    $strBuilder = New-Object System.Text.StringBuilder
    if ($Header) { 
        [void]($strBuilder.Append($Header))
    }
    if ($Message) {
        foreach ($msg in $Message) {
            [void]($strBuilder.Append($msg).Append("`r`n"))
        }
    }
        
    [System.IO.File]::AppendAllText($logFile, ($strBuilder.ToString()), [System.Text.Encoding]::Unicode)
}