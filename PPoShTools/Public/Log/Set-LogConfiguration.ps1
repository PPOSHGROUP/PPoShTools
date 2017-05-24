Function Set-LogConfiguration {
    <#
    .SYNOPSIS
        Sets global logging configuation (used by Write-Log).

    .DESCRIPTION
        It sets $LogConfiguration object which describes logging configuration (see LogConfiguration.ps1).

    .EXAMPLE
        Set-LogConfiguration -LogLevel 'Warn' -LogFile "$PSScriptRoot\test.log"
    #>
    
    [CmdletBinding()]
    [OutputType([void])]
    param(       
        # Logging level threshold. Only messages with this level or above will be logged (default: Info). 
        [Parameter(Mandatory=$false)]
        [string] 
        [ValidateSet('', 'Debug', 'Info', 'Warn', 'Error')]
        $LogLevel,
        
        # Path to additional file log or $null if shouldn't log to file (default: $null). 
        [Parameter(Mandatory=$false)]
        [string] 
        $LogFile,
        
        # Name of Event Log Source to log to or $null if shouldn't log to Event Log (default: $null).
        [Parameter(Mandatory=$false)]
        [switch] 
        $LogEventLogSource,
        
        # Logging level threshold for Event Log. This would normally have higher threshold than LogLevel (default: Error).
        [Parameter(Mandatory=$false)]
        [switch] 
        [ValidateSet('', 'Debug', 'Info', 'Warn', 'Error')]
        $LogEventLogThreshold
    )

    Begin { 
        if (!(Get-Variable -Scope Script -Name LogConfiguration -ErrorAction SilentlyContinue)) {
            $Script:LogConfiguration = [PSCustomObject]@{
                LogLevel = 'Info';
                LogFile = $null;
                LogEventLogSource = $null;         
                LogEventLogThreshold = 'Error'; 
            }
        }
        if ($LogFile -and (![System.IO.Path]::IsPathRooted($LogFile))) {
            # we need to set absolute path to log file as .NET working directory would be c:\windows\system32
            $LogFile = Join-Path -Path ((Get-Location).ProviderPath) -ChildPath $LogFile
        }
    }
    Process { 
        $newLogConfiguration = $Script:LogConfiguration
        foreach ($param in $PSBoundParameters.GetEnumerator()) {
            if ($param.Key -eq 'LogLevel' -and !($param.Value)) {
                $paramValue = 'Info'
            } 
            elseif ($param.Key -eq 'LogEventLogThreshold' -and !($param.Value)) {
                $paramValue = 'Error'
            } 
            elseif ($param.Key -eq 'Verbose') {
                continue
            }
            else {
                $paramValue = $param.Value
            }
            $newLogConfiguration.$($param.Key) = $paramValue
        }

        if ($PSBoundParameters['Verbose']) {
            $logMsg = "Logging messages with level >= $($newLogConfiguration.LogLevel) to stdout"
            if ($newLogConfiguration.LogFile) {
                $logMsg += " and file '$($newLogConfiguration.LogFile)'"
            }
            if ($newLogConfiguration.LogEventLogSource) {
                $logMsg += ", also logging messages with level >= $($newLogConfiguration.LogEventLogThreshold) to event log source '$($newLogConfiguration.LogEventLogSource)'"
            }
            $logMsg += '.'
            Write-Verbose -Message $logMsg
        }
        $Script:LogConfiguration = $newLogConfiguration
    }

    End {
    }
}