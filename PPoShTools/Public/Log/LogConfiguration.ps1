if (-not ('LogLevel' -as [System.Type])) {
    $logLevelDef = "
    public enum LogLevel : int
    {
        DEBUG=0,
        INFO,
        WARN,
        ERROR
    }
    "

    Add-Type -TypeDefinition $logLevelDef
}


$Script:LogConfiguration = [PSCustomObject]@{
    # Logging level threshold - available values: DEBUG, INFO, WARN, ERROR
    LogLevel = [LogLevel]::Info;

    # Path to file log or $null if shouldn't log to file. 
    LogFile = $null;

    # Name of Event Log Source to log to or $null if shouldn't log to Event Log.
    LogEventLogSource = $null;         

    # Logging level threshold for Event Log - available values: DEBUG, INFO, WARN, ERROR. 
    # This would normally have higher threshold than LogLevel.
    LogEventLogThreshold = [LogLevel]::ERROR; 
}