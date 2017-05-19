Function Write-Log {
    <#
    .SYNOPSIS
    Writes a nicely formatted Message to stdout/file/event log.

    .DESCRIPTION
    It uses optional $Global:LogConfiguration object which describes logging configuration (see LogConfiguration.ps1).

    .PARAMETER Error
    If specified, an error will be logged.

    .PARAMETER Warn
    If specified, a warning will be logged.

    .PARAMETER Info
    If specified, an information will be logged.

    .PARAMETER _debug
    If specified, a debug Message will be logged.

    .PARAMETER Emphasize
    If set, the Message at console will be made more visible (using colors).

    .PARAMETER NoHeader
    If specified, Header information will not be logged (e.g. '[ERROR]: (function_name)').

    .PARAMETER Indent
    Additional indent (optional).

    .PARAMETER Message
    Message to output.

    .PARAMETER PassThru
    If enabled, all log output will be available as return value.

    .PARAMETER CustomCallerInfo
    Custom string containing caller information, used in logging exceptions.

    .EXAMPLE
    Write-Log -Error "A disaster has occurred."
    #>
    
    [CmdletBinding()]
    [OutputType([void])]
    param(       
        [Parameter(Mandatory=$false)]
        [switch] 
        $Error = $false,
        
        [Parameter(Mandatory=$false)]
        [switch] 
        $Warn = $false,
        
        [Parameter(Mandatory=$false)]
        [switch] 
        $Info = $false,
        
        [Parameter(Mandatory=$false)]
        [switch] 
        $_debug = $false,
        
        [Parameter(Mandatory=$false)]
        [switch] 
        $Emphasize = $false,
        
        [Parameter(Mandatory=$false)]
        [switch] 
        $NoHeader = $false,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string[]]
        $Message,

        [Parameter(Mandatory=$false)]
        [int]
        $Indent = 0,

        [Parameter(Mandatory=$false)]
        [switch] 
        $PassThru = $false
    )

    Begin { 
        if ($Error) {
            $severity = [LogLevel]::Error;
            $severityChar = 'E'
        } elseif ($warn) {
            $severity = [LogLevel]::Warn;
            $severityChar = 'W'
        } elseif ($_debug) {
            $severity = [LogLevel]::Debug;
            $severityChar = 'D'
        } else {
            $severity = [LogLevel]::Info;
            $severityChar = 'I'
        }

        if ($severity -lt $Global:LogConfiguration.LogLevel) {
            return
        }

        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $callerInfo = (Get-PSCallStack)[1]
        $callerCommandName = $callerInfo.InvocationInfo.MyCommand.Name
        if ($callerInfo.ScriptName) {
            $callerScriptName = Split-Path -Leaf $callerInfo.ScriptName
        } else {
            $callerScriptName = 'no script';
        }
        $callerLineNumber = $callerInfo.ScriptLineNumber
        $callerInfoString = "$callerScriptName/$callerCommandName/$callerLineNumber"
        
        if ($NoHeader) {
            $outputHeader = ""
        } else {
            $currentHostname = [system.environment]::MachineName
            $currentUsername = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            if (Get-Variable -Name PSSenderInfo -ErrorAction SilentlyContinue) {
                $remotingFlag = '[R] '
            } else {
                $remotingFlag = ''
            }
            $outputHeader = "[$severityChar] $timestamp ${remotingFlag}[$currentHostname/${currentUsername}]: ($callerInfoString) "
        }
        $header = " " * $Indent + $outputHeader
    }
    Process { 
        try { 
            Write-LogToStdOut -Header $Header -Message $Message -Severity $Severity -Emphasize:$Emphasize
            Write-LogToFile -Header $Header -Message $Message -Severity $Severity
            Write-LogToEventLog -Header $Header -Message $Message -Severity $Severity
            Write-LogToPSOutput -Header $Header -Message $Message -Severity $Severity -PassThru:$PassThru
        } catch {
            $exception = $_.Exception
            $Message = "Writing to log failed - script will terminate.`r`n"
            $currentUsername = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            if ($LogConfiguration.LogFile) {
                $Message += "`r`nPlease ensure that current user ('{0}') has access to file '{1}' or change the path to log file in Global:`$LogConfiguration.LogFile." -f $currentUsername, $LogConfiguration.LogFile
            }
            if ($LogConfiguration.LogEventLogSource) {
                $Message += "`r`nPlease ensure that current user ('{0}') is able to create Event Log sources or create the source manually." -f $currentUsername
            }
        
            $Message += "`n" + ($_ | Format-List -Force | Out-String) + ($exception | Format-List -Force | Out-String)
            Write-Host $Message
            [void](New-Item -Path "error.txt" -ItemType file -Value $Message -Force)
            throw "Logging failure"
        }

    }

    End {
    }
}