Function Write-Log {
    <#
    .SYNOPSIS
        Writes a nicely formatted Message to stdout/file/event log.

    .DESCRIPTION
        It uses optional $Global:LogConfiguration object which describes logging configuration (see LogConfiguration.ps1).

    .INPUTS
        A string message to log.

    .EXAMPLE
        Write-Log -Info "Generating file test.txt."
        [I] 2017-05-19 11:14:28 [hostName/userName]: (scriptName/commandName/1) Generating file test.txt.

    .EXAMPLE
        $Global.LogConfiguration.LogLevel = 'Warn'
        Write-Log -Info "Generating file test.txt."
        <nothing will be logged>
        Write-Log -Error "Failed to generate file test.txt."
        [E] 2017-05-19 11:14:28 [hostName/userName]: (scriptName/commandName/1) Failed to generate file test.txt.

    .EXAMPLE
        $Global.LogConfiguration.LogFile = 'log.txt'
        Write-Log -Info "Generating file test.txt."

        Logs message to stdout and log.txt file.


    .EXAMPLE
        $Global.LogConfiguration.LogEventLogSource = 'log.txt'
        $Global.LogConfiguration.LogEventLogThreshold = 'log.txt'
        Write-Log -Info "Generating file test.txt."
    #>
    
    [CmdletBinding()]
    [OutputType([void])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", '')]
    param(       
        # If specified, an error will be logged.
        [Parameter(Mandatory=$false)]
        [switch] 
        $Error = $false,
        
        # If specified, a warning will be logged.
        [Parameter(Mandatory=$false)]
        [switch] 
        $Warn = $false,
        
        # If specified, an info message will be logged (default).
        [Parameter(Mandatory=$false)]
        [switch] 
        $Info = $false,
        
        # If specified, a debug message will be logged.
        [Parameter(Mandatory=$false)]
        [switch] 
        $_debug = $false,
        
        # If set, the message at console will be emphasized using colors.
        [Parameter(Mandatory=$false)]
        [switch] 
        $Emphasize = $false,
        
        # If specified, header information will not be logged (e.g. '[ERROR]: (function_name)').
        [Parameter(Mandatory=$false)]
        [switch] 
        $NoHeader = $false,

        # Message to output.
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string[]]
        $Message,

        # Additional indent.
        [Parameter(Mandatory=$false)]
        [int]
        $Indent = 0,

        # If enabled, all log output will be available as return value (will use Write-Output instead of Write-Host).
        [Parameter(Mandatory=$false)]
        [switch] 
        $PassThru = $false
    )

    Begin { 
        if ($Error) {
            $severity = 3;
            $severityChar = 'E'
        } 
        elseif ($warn) {
            $severity = 2;
            $severityChar = 'W'
        } 
        elseif ($_debug) {
            $severity = 0;
            $severityChar = 'D'
        } 
        else {
            $severity = 1;
            $severityChar = 'I'
        }

        if (!(Test-LogSeverity -MessageSeverity $severity)) {
            return
        } 

        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $callerInfo = (Get-PSCallStack)[1]
        if ($callerInfo.InvocationInfo -and $callerInfo.InvocationInfo.MyCommand -and $callerInfo.InvocationInfo.MyCommand.Name) {
            $callerCommandName = $callerInfo.InvocationInfo.MyCommand.Name
        } 
        else {
            $callerCommandName = '';
        }
        if ($callerInfo.ScriptName) {
            $callerScriptName = Split-Path -Leaf $callerInfo.ScriptName
        } 
        else {
            $callerScriptName = 'no script';
        }
        if ($callerInfo.ScriptLineNumber) { 
            $callerLineNumber = $callerInfo.ScriptLineNumber
        } 
        else {
            $callerLineNumber = ''
        }
        $callerInfoString = "$callerScriptName/$callerCommandName/$callerLineNumber"
        
        if ($NoHeader) {
            $outputHeader = ""
        } 
        else {
            $currentHostname = [system.environment]::MachineName
            $currentUsername = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            if (Get-Variable -Name PSSenderInfo -ErrorAction SilentlyContinue) {
                $remotingFlag = '[R] '
            } 
            else {
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
            $msg = "Writing to log failed - script will terminate.`r`n"
            $currentUsername = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            if ($LogConfiguration -and $LogConfiguration.LogFile) {
                $msg += "`r`nPlease ensure that current user ('{0}') has access to file '{1}' or change the path to log file in `$LogConfiguration.LogFile." -f $currentUsername, $LogConfiguration.LogFile
            }
            if ($LogConfiguration -and $LogConfiguration.LogEventLogSource) {
                $msg += "`r`nPlease ensure that current user ('{0}') is able to create Event Log sources or create the source manually." -f $currentUsername
            }
        
            $msg += "`n" + ($_ | Format-List -Force | Out-String) + ($exception | Format-List -Force | Out-String)
            Write-Host $msg
            [void](New-Item -Path "error.txt" -ItemType file -Value $msg -Force)
            throw "Logging failure"
        }
    }

    End {
    }
}