function Test-ColumnIsValid {
    <#
      .SYNOPSIS
      Validates a column value in a single CSV row.

      .DESCRIPTION
      It is useful in Get-CsvData / Get-ValidationRules to validate columns read from CSV row.
      It returns empty array if the value is valid, or array of error messages if it's invalid.
    
      .EXAMPLE
      $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'Login' -NonEmpty -NotContains '?', ' '
      $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'Name' -NonEmpty -NotContains '?'
      $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'StartDate' -DateFormat 'yyyy-MM-dd'
      $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'Gender' -ValidSet '', 'F', 'M'
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSPlaceCloseBrace', '')]
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        # CSV row (or any other PSCustomObject).
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Row,
        
        # Name of the column which will be validated.
        [Parameter(Mandatory = $true)]
        [string]$ColumnName,
        
        # If $true, it will be asserted the column value is not empty.
        [Parameter(Mandatory = $false)]
        [switch]$NonEmpty,
        
        # If specified, it will be asserted the column value does not contain any of the specified string.
        [Parameter(Mandatory = $false)]
        [string[]]$NotContains,
        
        # If specified, it will be asserted the column value contain any of the specified string.
        [Parameter(Mandatory = $false)]
        [string[]]$Match,
        
        # If specified, it will be asserted the column value is one of the specified string.
        [Parameter(Mandatory = $false)]
        [string[]]$ValidSet,
        
        # If specified, it will be asserted the column value can be converted to a date using specified format.
        [Parameter(Mandatory = $false)]
        [string]$DateFormat,
        
        # If specified, it will be asserted the column value is specified lenght.
        [Parameter(Mandatory = $false)]
        [int]$LengthMax,
        
        # If specified, it will be asserted the column value does not starts with any of the specified string.
        [Parameter(Mandatory = $false)]
        [string[]]$NotStartsWith,
        
        # If specified, it will be asserted the column value does not ends with any of the specified string.
        [Parameter(Mandatory = $false)]
        [string[]]$NotEndsWith
    )
    
    $errors = @()
    
    try {
        $value = $Row.$ColumnName
    } catch {
        $value = $null
    }
    
    if (!$value) {
        if ($NonEmpty) {
            $errors += "$ColumnName is missing"
        }
        return $errors
    }
    
    if ($NotContains) {
        foreach ($illegalChar in $NotContains) {
            if ([char[]]$value -icontains $illegalChar) {
                $errors += "$ColumnName has invalid value ('$value') - contains illegal character: '$illegalChar'"
            }
        }
    }
    
    if ($Match) {
        $ok = $false
        foreach ($legalString in $Match) {
            if ($value -imatch $legalString) {
                $ok = $true
                break
            }
        }
        if (!$ok) {
            $errors += "$ColumnName has invalid value ('$value') - should be one of '{0}'." -f ($Match -join "', ")
        }
    }
    
    if ($ValidSet) {
        $ok = $false
        foreach ($validValue in $ValidSet) {
            if ($value -ieq $validValue) {
                $ok = $true
                break
            }
        }
        if (!$ok) {
            $errors += "$ColumnName has invalid value ('$value') - should be one of '{0}'." -f ($ValidSet -join "', ")
        }
    }
    
    if ($DateFormat) {
        [datetime]$date = New-Object -TypeName DateTime
        $success = [DateTime]::TryParseExact($value, $DateFormat, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$date)
        
        if (!$success) {
            $errors += "$ColumnName has invalid value ('$value') - should be a date in format '$DateFormat'"
        }
    }
    
    if ($LengthMax) {
        if ($value.Length -gt $LengthMax) {
            $errors += "$ColumnName has invalid value ('$value') - string length is greater then: '$LengthMax'"
        }
    }
    
    if ($NotStartsWith) {
        $valueTemp = [char[]]$value
        foreach ($illegalChar in $NotStartsWith) {
            if ($valueTemp[0] -ieq $illegalChar) {
                $errors += "$ColumnName has invalid value ('$value') - starts with illegal character: '$illegalChar'"
            }
        }
    }
    
    if ($NotEndsWith) {
        $valueTemp = [char[]]$value
        foreach ($illegalChar in $NotEndsWith) {
            if ($valueTemp[-1] -ieq $illegalChar) {
                $errors += "$ColumnName has invalid value ('$value') - ends with illegal character: '$illegalChar'"
            }
        }
    }
    
    return $errors
}
