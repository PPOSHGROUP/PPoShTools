function Test-LogSeverity() {
    <#
    .SYNOPSIS
        Checks if message severity is greater on equal to config severity.

    .EXAMPLE
        Test-LogSeverity -MessageSeverity  
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param(      
        [Parameter(Mandatory=$true)]  
        [int] 
        $MessageSeverity,

        [Parameter(Mandatory=$false)]
        [string]
        $ConfigSeverity
    )
    
    if (!$ConfigSeverity) {
        if (!$LogConfiguration -or !$LogConfiguration.LogLevel) {
            return $true
         }
         $ConfigSeverity = $LogConfiguration.LogLevel
    }

    switch ($ConfigSeverity.ToUpper()[0]) {
        'E' { $configSeverityInt = 3 }
        'W' { $configSeverityInt = 2 }
        'D' { $configSeverityInt = 0 }
        default { $configSeverityInt = 1 }
    }
    return ($MessageSeverity -ge $configSeverityInt)
}
