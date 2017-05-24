function Write-LogToEventLog() {
    <#
    .SYNOPSIS
        Outputs the Message to event log.
    
    .DESCRIPTION
        Creates new event log source if not exists.

    #>

    [CmdletBinding()]
    [OutputType([string])]
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
        $PassThru
    )

    if (!(Get-Variable -Scope Script -Name LogConfiguration -ErrorAction SilentlyContinue)) {
        return
    }
    
    if (!$Script:LogConfiguration.LogEventLogSource) {
        return
    } 

    $logEventLogSource = $Script:LogConfiguration.LogEventLogSource
    $logEventLogThreshold = $Script:LogConfiguration.LogEventLogThreshold

    if ($logEventLogSource -and !(Test-LogSeverity -MessageSeverity $Severity -ConfigSeverity $logEventLogThreshold)) {
        return
    }
        
    if ($Severity -eq 3) {
        $entryType = [System.Diagnostics.EventLogEntryType]::Error
    } 
    elseif ($Severity -eq 2) {
        $entryType = [System.Diagnostics.EventLogEntryType]::Warning
    } 
    else {
        $entryType = [System.Diagnostics.EventLogEntryType]::Information
    }

    if (![System.Diagnostics.EventLog]::SourceExists($logEventLogSource)) {
        Write-Host "Creating log event source '$logEventLogSource'."
        [void](New-EventLog -LogName Application -Source $logEventLogSource)
    }

    $strBuilder = New-Object System.Text.StringBuilder
    if ($Header) {
        [void]($strBuilder.Append($Header))
    }
    if ($Message) {
        foreach ($msg in $Message) {
            [void]($strBuilder.Append($msg).Append("`r`n"))
        }
    }
    Write-EventLog -LogName Application -Source $logEventLogSource -EntryType $entryType -EventID 1 -Message ($strBuilder.ToString())
}
