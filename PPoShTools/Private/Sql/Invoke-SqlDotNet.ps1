function Invoke-SqlDotNet {
    <# 
    .SYNOPSIS 
    Runs a T-SQL script using .NET SqlCommand. 
    
    .DESCRIPTION 
    Useful especially when neither SMO nor sqlcmd are available.
    
    .EXAMPLE
    Invoke-SqlDotNet -ConnectionString $connectionString -Sql $Query -SqlCmdVariables $param
    #> 

    [CmdletBinding()] 
    [OutputType([object])]
    param( 
        [Parameter(Mandatory=$true)] 
        [object]
        $ConnectionStringBuilder, 
    
        [Parameter(Mandatory=$false)] 
        [string]
        $Query,
        
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
        [ValidateSet($null, 'NonQuery', 'Scalar', 'Dataset')]
        [string]
        $Mode = 'Dataset',
    
        [Parameter(Mandatory=$false)] 
        [hashtable]
        $SqlCmdVariables,

        [Parameter(Mandatory=$false)]
        [Data.SqlClient.SqlParameter[]] 
        $SqlParameters,

        [Parameter(Mandatory=$false)]
        [PSCredential] 
        $Credential
    ) 

    #TODO: handle $Credential

    # Replace SqlCmdVariables in $Query
    if ($SqlCmdVariables) {
        foreach ($var in $SqlCmdVariables.GetEnumerator()) {
            $regex = '\$\({0}\)' -f $var.Key
            if (!$var.Value) {
                $value = ''
            } 
            else {
                $value = $var.Value
            }
            Write-Log -_Debug "Key: $($var.Key), value: $($var.Value)"
            $Query = [System.Text.RegularExpressions.Regex]::Replace($Query, $regex, $value, `
                        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        }
    }

    # Split queries per each 'GO' instance - see http://stackoverflow.com/questions/18596876/go-statements-blowing-up-sql-execution-in-net/18597052#18597052
    $queriesSplit = [System.Text.RegularExpressions.Regex]::Split($Query, '^\s*GO\s* ($ | \-\- .*$)', `
        [System.Text.RegularExpressions.RegexOptions]::Multiline -bor `
        [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace -bor `
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    $queriesSplit = $queriesSplit | Where-Object { ![System.String]::IsNullOrWhiteSpace($_) }

    $ConnectionStringBuilder.set_ConnectTimeout($ConnectTimeoutInSeconds)


    try { 
        $connection = New-Object -TypeName System.Data.SqlClient.SQLConnection -ArgumentList ($ConnectionStringBuilder.ToString())
        $connection.FireInfoMessageEventOnUserErrors = $true
        $errorOccurred = @{ Error = $false }
        $infoEventHandler = [System.Data.SqlClient.SqlInfoMessageEventHandler] { 
            foreach ($err in $_.Errors) { 
                if ($err.Class -le 10) { 
                    Write-Log -Info $err.Message
                } 
                else { 
                    Write-Log -Error $err.Message
                    if (!$IgnoreErrors) {
                        $errorOccurred.Error = $true
                    }
                }
            }    
        } 
        $connection.add_InfoMessage($infoEventHandler)
        $connection.Open()

        foreach ($q in $queriesSplit) { 
            $command = New-Object -TypeName System.Data.SqlClient.SqlCommand -ArgumentList $q, $connection
            $command.CommandTimeout = $QueryTimeoutInSeconds

            if ($SqlParameters) {
                foreach ($sqlParam in $SqlParameters) {
                    Write-Log -_Debug "Key: $($sqlParam.ParameterName), value: $($sqlParam.Valuee)"
                    [void]($command.Parameters.Add($sqlParam))
                }
            }

            if ($Mode -eq 'Dataset') { 
                $dataset = New-Object -TypeName System.Data.DataSet 
                $dataAdapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter -ArgumentList $command
            
                [void]$dataAdapter.fill($dataset) 

                $dataset
            } 
            elseif ($Mode -eq 'NonQuery') {
                [void]($command.ExecuteNonQuery())
            } 
            elseif ($Mode -eq 'Scalar') {
                $command.ExecuteScalar()
            } 
            else {
                throw "Unsupported mode: ${Mode}."
            }

            if ($errorOccurred.Error) {
                throw "SQL error(s) occurred."
            }
        }
    
        $connection.Close();
    } finally {
        if ($connection) {
            $connection.Dispose();
        }
    }  
}
