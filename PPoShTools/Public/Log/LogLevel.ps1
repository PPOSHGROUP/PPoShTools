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