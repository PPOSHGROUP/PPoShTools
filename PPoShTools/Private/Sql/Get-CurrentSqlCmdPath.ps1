function Get-CurrentSqlCmdPath {
    <# 
    .SYNOPSIS 
    Returns sqlcmd.exe folder path

    .DESCRIPTION 
    Search for sqlcmd bin path in system registry. First found version will be returned.

    .EXAMPLE
    Get-CurrentSqlCmdPath
    #> 

    [CmdletBinding()] 
    [OutputType([string])]
    param()

    $sqlServerVersions = @('150', '140', '130', '120', '110', '100', '90')
    foreach ($version in $sqlServerVersions) {
        $regKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$version\Tools\ClientSetup"
        if (Test-Path -LiteralPath $regKey) {
            $path = (Get-ItemProperty -Path $regKey).Path
            if ($path) {
                $path = Join-Path -Path $path -ChildPath 'sqlcmd.exe'
                if (Test-Path -LiteralPath $path) {
                    return $path
                }
            }
            $path = (Get-ItemProperty -Path $regKey).ODBCToolsPath
            if ($path) {
                $path = Join-Path -Path $path -ChildPath 'sqlcmd.exe'
                if (Test-Path -LiteralPath $path) {
                    return $path
                }
            }
        }
        # registry not found - try directory instead
        $path = "$($env:ProgramFiles)\Microsoft SQL Server\$version\Tools\Binn\sqlcmd.exe"
        if (Test-Path -LiteralPath $path) {
            return $path
        }
    }

    return $null
}



