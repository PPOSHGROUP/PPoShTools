function Get-CsvData {

    <#
    .SYNOPSIS
        Reads CSV file using specific encoding and running optional Validation and Transformation rules.

    .DESCRIPTION
        After CSV file is read, Validation phase is run, that is for each row $CsvValidationRules scriptblock is invoked, which returns array of string:
            - if the array is empty it is assumed the row is valid.
            - if the array is non-empty, it is assumed the row is invalid and the strings will be displayed after the Validation phase.
        Then, Transformation phase is run, that is for each row $CsvTransformationRules scriptblock is invoked, which returns a hashtable that is then
        passed as a final result.

    .EXAMPLE
    function Get-ValidationRules {

        [CmdletBinding()]
        [OutputType([string[]])]
        param(
            [Parameter(Mandatory = $true)]
            [PSCustomObject]
            $CsvRow,

            [Parameter(Mandatory = $true)]
            [int]
            $CsvRowNum
        )

        $errors = @()
        $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'Login' -NonEmpty -NotContains '?', ' '
        $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'Name' -NonEmpty -NotContains '?'
        $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'First Name' -NonEmpty -NotContains '?', ' '
        $errors += Test-ColumnIsValid -Row $CsvRow -ColumnName 'Last Name' -NonEmpty -NotContains '?'

        return $errors
    }

    function Get-TransformRules {

        [CmdletBinding()]
        [OutputType([hashtable])]
        param(
            [Parameter(Mandatory = $true)]
            [PSCustomObject]
            $CsvRow,

            [Parameter(Mandatory = $true)]
            [int]
            $CsvRowNum
        )

        $result = @{
            Name = Remove-DiacriticChars -String (($CsvRow.'Name'))
            FirstName = Remove-DiacriticChars -String (($CsvRow.'First Name'))
            LastName = Remove-DiacriticChars -String (($CsvRow.'Last Name'))
            Login = $CsvRow.Login
        }

        return $result
    }

    $csvParams = @{
        CsvPath = 'test.csv'
        CsvDelimiter = ';'
        CsvValidationRules = (Get-Command -Name Get-ValidationRules).ScriptBlock
        CsvTransformRules = (Get-Command -Name Get-TransformRules).ScriptBlock
        CustomEncoding = 'Windows-1250'
    }
    $employeeData = Get-CsvData @csvParams
    #>
    [CmdletBinding()]
    [OutputType([hashtable[]])]
    param(
        # Path to input CSV file.
        [Parameter(Mandatory = $true)]
        [string]
        $CsvPath,

        # CSV delimiter in input CSV file.
        [Parameter(Mandatory = $true)]
        [string]
        $CsvDelimiter,

        # If specified, CSV file will be first reencoded to UTF-8 (to a temporary file).
        [Parameter(Mandatory = $false)]
        [string]
        $CustomEncoding,

        # A scriptblock invoked for each row that accepts [PSCustomObject]$CsvRow and [int]$CsvRowNum. It returns array of string.
        [Parameter(Mandatory = $false)]
        [scriptblock]
        $CsvValidationRules,

        # A scriptblock ivoked for each row that accepts [PSCustomObject]$CsvRow and [int]$CsvRowNum. It returns hashtable.
        [Parameter(Mandatory = $false)]
        [scriptblock]
        $CsvTransformRules
    )

    if (!(Test-Path -LiteralPath $CsvPath)) {
        throw "Csv input file '$CsvPath' does not exist at $((Get-Location).Path)."
    }

    $tempFileName = ''
    try {

        if ($CustomEncoding) {
            $inputEncodingObj = [System.Text.Encoding]::GetEncoding($CustomEncoding)
            $outputEncodingObj = [System.Text.Encoding]::GetEncoding('UTF-8')
            $tempFileName = [System.IO.Path]::GetTempFileName()
            Write-Log -Info "Converting file '$CsvPath' from $CustomEncoding to UTF-8 - saving as '$tempFileName'."
            $text = [System.IO.File]::ReadAllText($CsvPath, $inputEncodingObj)
            [System.IO.File]::WriteAllText($tempFileName, $text, $outputEncodingObj)
            $csvFileToRead = $tempFileName
        }
        else {
            $csvFileToRead = $CsvPath
        }

        Write-Log -Info "Reading file '$csvFileToRead' using delimiter '$CsvDelimiter'"
        $inputData = Import-Csv -Path $csvFileToRead -Delimiter $CsvDelimiter -Encoding UTF8
        if (!$inputData) {
            throw "There is no data to import. Please check file '$CsvPath'."
        }
        Write-Log -Info "Read $($inputData.Length) rows."

        $emptyRows = @()
        $rowNum = 2
        foreach ($row in $inputData) {
            $isRowEmpty = $true
            foreach ($prop in $row.PSObject.Properties.Name) {
                $row.$prop = $row.$prop.Trim()
                if ($row.$prop) {
                    $isRowEmpty = $false
                }
            }
            if ($isRowEmpty) {
                $emptyRows += $rowNum
            }
            $rowNum++
        }

        if ($emptyRows) {
            Write-Log -Info "Ignoring empty row numbers: $($rowNum -join ', ')."
        }

        # Run Validation Rules
        if ($CsvValidationRules) {
            $errorArray = New-Object -TypeName System.Collections.ArrayList
            $rowNum = 2

            Write-Log -Info 'Validating CSV data.'
            foreach ($row in $inputData) {
                if ($emptyRows -contains $rowNum) {
                    $rowNum++
                    continue
                }

                try {
                    $errors = Invoke-Command -ScriptBlock $CsvValidationRules -ArgumentList $row, $rowNum
                }
                catch {
                    Write-ErrorRecord
                }
                foreach ($err in $errors) {
                    [void]($errorArray.Add("Validation error in row ${rowNum}: $err"))
                }
                $rowNum++
            }

            if ($errorArray) {
                $msg = "`r`n" + ($errorArray -join "`r`n")
                Write-Log -Error $msg
                throw "Input CSV file has not passed validation rules. Please fix the file and try again."
            }
        }

        $added = 0
        $ignored = 0
        # Run Transformation Rules
        if ($CsvTransformRules) {
            $resultArray = New-Object -TypeName System.Collections.ArrayList
            $rowNum = 2

            Write-Log -Info 'Transforming CSV data.'
            foreach ($row in $inputData) {
                if ($emptyRows -contains $rowNum) {
                    $rowNum++
                    $ignored++
                    continue
                }
                try {
                    $resultRow = Invoke-Command -ScriptBlock $CsvTransformRules -ArgumentList $row, $rowNum
                }
                catch {
                    Write-ErrorRecord -ErrorRecord $_
                }
                if ($resultRow) {
                    [void]($resultArray.Add($resultRow))
                    $added++
                }
                else {
                    $ignored++
                }
                $rowNum++
            }
            Write-Log -Info "CSV file read successfully ($added rows returned, $ignored rows ignored)."
            return $resultArray
        }
        else {
            return $inputData
        }
    }
    finally {
        if ($tempFileName -and (Test-Path -Path $tempFileName)) {
            Remove-Item -Path $tempFileName -Force
        }
    }
}