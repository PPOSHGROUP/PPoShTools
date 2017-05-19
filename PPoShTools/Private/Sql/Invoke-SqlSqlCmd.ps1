function Invoke-SqlSqlcmd {
    <# 
    .SYNOPSIS 
    Runs a T-SQL script using sqlcmd.exe. 
    
    .DESCRIPTION 
    Runs sql command or sql script file. Gives proper error handling as opposed to Invoke-Sqlcmd.
    See https://connect.microsoft.com/SQLServer/feedback/details/779320/invoke-sqlcmd-does-not-return-t-sql-errors.

    .EXAMPLE
    Invoke-SqlSqlcmd -ConnectionString $connectionString -Sql $Query -SqlCmdVariables $param
    #> 

    [CmdletBinding()] 
    [OutputType([string])]
    param( 
        [Parameter(Mandatory=$true)] 
        [object]
        $ConnectionStringBuilder, 
    
        [Parameter(Mandatory=$false)] 
        [string]
        $Query,
    
        [Parameter(Mandatory=$false)] 
        [string]
        $InputFile,
    
        [Parameter(Mandatory=$false)] 
        [bool]
        $IgnoreErrors,
    
        [Parameter(Mandatory=$true)] 
        [int]
        $QueryTimeoutInSeconds,

        [Parameter(Mandatory=$true)] 
        [int]
        $ConnectTimeoutInSeconds,
    
        [Parameter(Mandatory=$false)] 
        [hashtable]
        $SqlCmdVariables,

        [Parameter(Mandatory=$false)]
        [PSCredential] 
        $Credential
    ) 

    [string[]]$params = ""

    if ($InputFile) {
        $params += "-i `"$InputFile`""
    } 
    else { 
        $params += "-Q ""$Query"""
    }

    $serverAddress = $ConnectionStringBuilder.DataSource
    
    if (![string]::IsNullOrEmpty($ConnectionStringBuilder.InitialCatalog)) {
        $params += "-d $($ConnectionStringBuilder.InitialCatalog)"
    }
    
    if (![string]::IsNullOrEmpty($ConnectionStringBuilder.UserID) -and ![string]::IsNullOrEmpty($ConnectionStringBuilder.Password)) {
        $params += "-U $($ConnectionStringBuilder.UserID)"
        $params += "-P ""$($ConnectionStringBuilder.Password)"""
    } 
    else {
        $params += '-E'
    }
    
    if ($SqlCmdVariables) {
        $sqlCmdVariables.GetEnumerator() | Foreach-Object { $params += "-v $($_.key)=""$($_.value)""" }
    }

    if (!$IgnoreErrors) {
        $params += '-b'
    } 

    $output = ''

    $sqlCmdPath = Get-CurrentSqlCmdPath

    $startSqlCmdParams = @{ Command=$sqlcmdPath
             ArgumentList="-S $serverAddress -t $QueryTimeoutInSeconds -l $ConnectTimeoutInSeconds $params -w 65535 -h -1 -W -s "","""
             Output=([ref]$output)
             Credential=$Credential
             }

    if ($Credential) {
        # this is to ensure we don't get error 'The directory name is invalid'
        $startSqlCmdParams.WorkingDirectory = (Get-Location)
        Write-Log -Info "Running sqlcmd as user '$($Credential.UserName)'"
    }

    [void](Start-ExternalProcess @startSqlCmdParams)
 
    return $output
}