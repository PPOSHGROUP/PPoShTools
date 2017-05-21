function Write-ErrorRecord {
    <#
        .SYNOPSIS
            Logs ErrorRecord message, including script StackTrace and exception StackTrace.

        .EXAMPLE
            $Global:ErrorActionPreference = 'Stop'
            try {
                ...
            } catch {
                Write-ErrorRecord
            }
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        # Error record to log. If null, $_ will be used.
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )
    
    if (!$ErrorRecord -and (Test-Path Variable:_)) {
        $ErrorRecord = $_
    }
    if ($ErrorRecord -and $ErrorRecord.Exception) {
        $exception = $ErrorRecord.Exception
    } 
    else {
        $exception = $null
    }

    $messageToLog = ''

    if ($ErrorRecord -and $ErrorRecord.InvocationInfo) {
        $callerInfo = $ErrorRecord.InvocationInfo
        if ($callerInfo.MyCommand -and $callerInfo.MyCommand.Name) {
            $callerCommandName = $callerInfo.MyCommand.Name
        } 
        else {
            $callerCommandName = ''
        }
        if ($callerInfo.ScriptName) {
            $callerScriptName = Split-Path -Leaf $callerInfo.ScriptName
        }
        else {
            $callerScriptName = '';
        }
        $callerLineNumber = $callerInfo.ScriptLineNumber
        $messageToLog += "[$callerScriptName/$callerCommandName/$callerLineNumber] "
    }

    if ($ErrorRecord) {
        $messageToLog += ($errorRecord.ToString()) + "`r`n`r`n"
        $messageToLog += "ERROR RECORD:" + ($ErrorRecord | Format-List -Force | Out-String)
    }
    if ($exception) {
        $messageToLog += "INNER EXCEPTION:" + ($exception | Format-List -Force | Out-String)
    }
    if (!$ErrorRecord -or !$ErrorRecord.ScriptStackTrace) {
        $psStack = Get-PSCallStack
        for ($i = 1; $i -lt $psStack.Length; $i++) {
            $messageToLog += ("Stack trace {0}: location={1}, command={2}, arguments={3}`r`n " -f ($i-1), $psStack[$i].Location, $psStack[$i].Command, $psStack[$i].Arguments)
        }
    }
   
    Write-Error -Message $messageToLog -ErrorAction Continue
    throw
}