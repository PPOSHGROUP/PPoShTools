function Invoke-Sql {
    <# 
    .SYNOPSIS 
    Runs a T-SQL script using .NET classes (default, no prerequisites needed) or sqlcmd.exe. 
    
    .DESCRIPTION 
    Runs sql command or sql script file 

    .OUTPUTS
    String if Mode = sqlcmd.
    System.Data.DataSet if Mode = .net.

    .EXAMPLE
    Invoke-Sql -ConnectionString $connectionString -Sql $Query-TimeoutInSeconds -SqlCmdVariables $param
    #> 

    [CmdletBinding()] 
    [OutputType([object])]
    param( 
        [Parameter(Mandatory=$true)] 
        [string]
        $ConnectionString, 
    
        # Sql queries that will be run - need to specify either this parameter or $InputFile.
        [Parameter(Mandatory=$false)] 
        [string[]]
        $Query,
    
        # File(s) containing sql query to run - need to specify either this parameter or $Query.
        [Parameter(Mandatory=$false)] 
        [string[]]
        $InputFile,

        # Determines how the sql is run - by sqlcmd.exe or .NET SqlCommand.
        [Parameter(Mandatory=$false)] 
        [string]
        [ValidateSet($null, 'sqlcmd', '.net')]
        $Mode = '.net',

        # Sql command mode to use if Mode = .net (NonQuery / Scalar / Dataset). Ignored if mode is different than .net.   
        [Parameter(Mandatory=$false)] 
        [string]
        [ValidateSet($null, 'NonQuery', 'Scalar', 'Dataset')]
        $SqlCommandMode = 'Dataset',
    
        # If set ignore errors when sqlcmd.exe is running.
        [Parameter(Mandatory=$false)] 
        [bool]
        $IgnoreErrors,
    
        [Parameter(Mandatory=$false)] 
        [int]
        $QueryTimeoutInSeconds = 3600,

        [Parameter(Mandatory=$false)] 
        [int]
        $ConnectTimeoutInSeconds = 60,
    
        # Hashtable containing sqlcmd variables.
        [Parameter(Mandatory=$false)] 
        [hashtable]
        $SqlCmdVariables,

        # Array of SqlParameters for .NET SqlCommand.
        [Parameter(Mandatory=$false)]
        [Data.SqlClient.SqlParameter[]] 
        $SqlParameters,

        # Credential to impersonate in Integrated Security mode.
        [Parameter(Mandatory=$false)]
        [PSCredential] 
        $Credential,

        # Database name to use, regardless of Initial Catalog settings in connection string.
        # Can also be used to remove database name from connection string (when passed empty string).
        [Parameter(Mandatory=$false)]
        [string] 
        $DatabaseName
    ) 

    if (!$Mode) {
        $Mode = '.net'
    }

    if (!$Query -and !$InputFile) {
        throw 'Missing -Query or -InputFile parameter'
    }

    if ($Mode -eq 'sqlcmd') {
        $sqlCmdPath = Get-CurrentSqlCmdPath
        if (!$sqlCmdPath) {
            Write-Log -Warn 'Cannot find sqlcmd.exe - falling back to .NET'
            $Mode = '.net'
        }
    }

    if ($InputFile) {
        foreach ($file in $Inputfile) { 
            if (!(Test-Path -LiteralPath $file)) { 
                throw "$InputFile does not exist. Current directory: $(Get-Location)"
            }
        }
    }
      
    $csb = New-Object -TypeName System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $ConnectionString

    if ($PSBoundParameters.ContainsKey('DatabaseName')) {
        $csb.set_InitialCatalog($DatabaseName)
    }

    $params = @{
        ConnectionStringBuilder = $csb
        IgnoreErrors = $IgnoreErrors
        QueryTimeoutInSeconds = $QueryTimeoutInSeconds
        ConnectTimeoutInSeconds = $ConnectTimeoutInSeconds
        SqlCmdVariables = $SqlCmdVariables
        Credential = $Credential
    }

    $targetLog = "$($csb.DataSource)"
    if ($csb.InitialCatalog) {
        $targetLog += " / $($csb.InitialCatalog)"
    }

    if ($Mode -eq 'sqlcmd') {
        foreach ($q in $Query) { 
            $params['Query'] = $q
            if ($q.Trim().Length -gt 40) {
                $qLog = ($q.Trim().Substring(0, 40) -replace "`r", '' -replace "`n", '; ') + '...'
            } 
            else {
                $qLog = $q.Trim()
            }
            Write-Log -_Debug "Running custom query at $targetLog using sqlcmd, QueryTimeout = $QueryTimeoutInSeconds s (${qLog}...)"
            Invoke-SqlSqlcmd @params
        }

        [void]($params.Remove('Query'))
        foreach ($file in $InputFile) {
            $file = (Resolve-Path -LiteralPath $file).ProviderPath
            $params['InputFile'] = $file
            Write-Log -_Debug "Running sql file '$file' at $targetLog using sqlcmd, QueryTimeout = $QueryTimeoutInSeconds s"
            Invoke-SqlSqlcmd @params
        }
    } 
    elseif ($Mode -eq '.net') {
        $params['Mode'] = $SqlCommandMode
        $params['SqlParameters'] = $SqlParameters
        foreach ($q in $Query) { 
            $params['Query'] = $q
            if ($q.Trim().Length -gt 40) {
                $qLog = ($q.Trim().Substring(0, 40) -replace "`r", '' -replace "`n", '; ') + '...'
            } 
            else {
                $qLog = $q.Trim()
            }
            Write-Log -_Debug "Running custom query at $targetLog using .Net (${qLog})"
            Invoke-SqlDotNet @params
        }

        foreach ($file in $InputFile) {
            $file = (Resolve-Path -LiteralPath $file).ProviderPath
            Write-Log -_Debug "Running sql file '$file' at $targetLog using .Net, QueryTimeout = $QueryTimeoutInSeconds s"
            $params['Query'] = Get-Content -LiteralPath $file -ReadCount 0 | Out-String
            Invoke-SqlDotNet @params
        }
    } 
    else {
        throw "Unrecognized mode: ${Mode}."
    }
}
