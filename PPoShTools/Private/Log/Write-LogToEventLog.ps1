function Write-LogToEventLog() {
    <#
    .SYNOPSIS
        Outputs the Message to event log.
    
    .DESCRIPTION
        Creates new event log source if not exists.

    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string] 
        $Header, 
        
        [string[]] 
        $Message, 
        
        [LogLevel] 
        $Severity
    )
    
    if (!$LogConfiguration.LogEventLogSource -or [int]$Severity -lt [int]$LogConfiguration.LogEventLogThreshold) {
        return
    }
        
    if ($Severity -eq [LogLevel]::ERROR) {
        $entryType = [System.Diagnostics.EventLogEntryType]::Error
    } 
    elseif ($Severity -eq [LogLevel]::WARN) {
        $entryType = [System.Diagnostics.EventLogEntryType]::Warning
    } 
    else {
        $entryType = [System.Diagnostics.EventLogEntryType]::Information
    }

    if (![System.Diagnostics.EventLog]::SourceExists($LogConfiguration.LogEventLogSource)) {
        [void](New-EventLog -LogName Application -Source $LogConfiguration.LogEventLogSource)
    }

    $strBuilder = New-Object System.Text.StringBuilder
    [void]($strBuilder.Append($Header))
    foreach ($msg in $Message) {
        [void]($strBuilder.Append($msg).Append("`r`n"))
    }
    Write-EventLog -LogName Application -Source $LogConfiguration.LogEventLogSource -EntryType $entryType -EventID 1 -Message ($strBuilder.ToString())
}
