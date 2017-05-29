function ConvertTo-Date {

    <#
    .SYNOPSIS
    Converts a string to a DateTime using specified DateFormat.

    .DESCRIPTION
    See https://msdn.microsoft.com/en-us/library/az4se3k1%28v=vs.110%29.aspx for description of format strings.

    .EXAMPLE
    $date = ConvertTo-Date -String '2015-03-05' -DateFormat 'yyyy-MM-dd'
    #>

    [CmdletBinding()]
    [OutputType([DateTime])]
    param(
        # String to be converted to date.
        [Parameter(Mandatory = $false)]
        [string]
        $String,

        # Date formats that will be used to parse the string. If not specified, system default will be used.
        [Parameter(Mandatory = $false)]
        [string[]]
        $DateFormat,

        # If true, exception will be thrown if failed to convert string to date. Otherwise, $null will be returned.
        [Parameter(Mandatory = $false)]
        [switch]
        $ThrowOnFailure
    )

    if (!$String) {
        return $null
    }

    $success = $false

    if ($DateFormat) {
        [datetime]$result = New-Object -TypeName DateTime
        $success = [DateTime]::TryParseExact($String, $DateFormat, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$result)
    } 
    else {
        [datetime]$result = New-Object -TypeName DateTime
        $success = [DateTime]::TryParse($String, [ref]$result)
    }

    if ($success) {
        return $result
    }

    if ($ThrowOnFailure) {
        throw "Failed to convert string '$String' to date using formats $DateFormat."
    }

    return $null
}

        