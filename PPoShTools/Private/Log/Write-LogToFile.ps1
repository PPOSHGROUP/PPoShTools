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
        [string] 
        $Header, 
        
        [string[]] 
        $Message, 
        
        [LogLevel] 
        $Severity
    )
    
    if (!$LogConfiguration.LogFile) {
        return
    }
    if (![System.IO.Path]::IsPathRooted($LogConfiguration.LogFile)) {
        # we need to set absolute path to log file as .NET working directory would be c:\windows\system32
        $LogConfiguration.LogFile = Join-Path -Path ((Get-Location).ProviderPath) -ChildPath $LogConfiguration.LogFile
    }

    $strBuilder = New-Object System.Text.StringBuilder
    [void]($strBuilder.Append($Header))
    foreach ($msg in $Message) {
        [void]($strBuilder.Append($msg).Append("`r`n"))
    }
        
    [System.IO.File]::AppendAllText($LogConfiguration.LogFile, ($strBuilder.ToString()), [System.Text.Encoding]::Unicode)
}