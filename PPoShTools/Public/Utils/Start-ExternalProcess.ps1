
function Start-ExternalProcess {
    <#
        .SYNOPSIS
            Runs external process.

        .DESCRIPTION
            Runs an external process with proper logging and error handling.
            It fails if anything is present in stderr stream or if exitcode is non-zero.

        .EXAMPLE
            Start-ExternalProcess -Command "git" -ArgumentList "--version"
    #>
    [CmdletBinding()]
    [OutputType([int])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidDefaultValueSwitchParameter', '')]
    param(
        # Command to run.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Command,

        # ArgumentList for Command.
        [Parameter(Mandatory = $false)]
        [string]
        $ArgumentList,

        # Working directory. Leave empty for default.
        [Parameter(Mandatory = $false)]
        [string]
        $WorkingDirectory,

        # If true, exit code will be validated (if zero, an error will be thrown).
        # If false, it will not be validated but returned as a result of the function.
        [Parameter(Mandatory = $false)]
        [switch]
        $CheckLastExitCode = $true,

        # If true, the cmdlet will return exit code of the invoked command.
        # If false, the cmdlet will return nothing.
        [Parameter(Mandatory = $false)]
        [switch]
        $ReturnLastExitCode = $true,

        # If true and any output is present in stderr, an error will be thrown.
        [Parameter(Mandatory = $false)]
        [switch]
        $CheckStdErr = $true,

        # If not null and given string will be present in stdout, an error will be thrown.
        [Parameter(Mandatory = $false)]
        [string]
        $FailOnStringPresence,

        # If set, then $Command will be executed under $Credential account.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $Credential,

        # Reference parameter that will get STDOUT text.
        [Parameter(Mandatory = $false)]
        [ref]
        $Output,

        # Reference parameter that will get STDERR text.
        [Parameter(Mandatory = $false)]
        [ref]
        $OutputStdErr,

        # Timeout to wait for external process to be finished.
        [Parameter(Mandatory = $false)]
        [int]
        $TimeoutInSeconds,

        # If true, no output from the command will be passed to the console.
        [Parameter(Mandatory = $false)]
        [switch]
        $Quiet = $false,

        # If true, STDOUT/STDERR will be displayed if error occurs (even if -Quiet is specified).
        [Parameter(Mandatory = $false)]
        [switch]
        $ReportOutputOnError = $true,

        # Each stdout/stderr line that match this regex will be ignored (not written to console/$output).
        [Parameter(Mandatory = $false)]
        [string]
        $IgnoreOutputRegex
    )

    $commandPath = $Command
    if (!(Test-Path -LiteralPath $commandPath)) {
        $exists = $false

        if (![System.IO.Path]::IsPathRooted($commandPath)) {
            # check if $Command exist in PATH
            $exists = $env:PATH.Split(";") | Where-Object { $_ -and (Test-Path (Join-Path -Path $_ -ChildPath $commandPath)) }

            if (!$exists -and $WorkingDirectory) {
                $commandPath = Join-Path -Path $WorkingDirectory -ChildPath $commandPath
                $exists = Test-Path -LiteralPath $commandPath
                $commandPath = (Resolve-Path -LiteralPath $commandPath).ProviderPath
            }
        }

        if (!$exists) {
            throw "'$commandPath' cannot be found."
        }
    }
    else {
        $commandPath = (Resolve-Path -LiteralPath $commandPath).ProviderPath
    }

    if (!$Quiet) {
        $timeoutLog = " (timeout $TimeoutInSeconds s)"
        Write-Log -Info "Running external process${timeoutLog}: $Command $ArgumentList"
    }

    $process = New-Object -TypeName System.Diagnostics.Process
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.FileName = $commandPath
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.RedirectStandardInput = $true

    if ($WorkingDirectory) {
        $process.StartInfo.WorkingDirectory = $WorkingDirectory
    }

    if ($Credential) {
        $networkCred = $Credential.GetNetworkCredential()
        $process.StartInfo.Domain = $networkCred.Domain
        $process.StartInfo.UserName = $networkCred.UserName
        $process.StartInfo.Password = $networkCred.SecurePassword
    }

    $outputDataSourceIdentifier = "ExternalProcessOutput"
    $errorDataSourceIdentifier = "ExternalProcessError"

    Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -SourceIdentifier $outputDataSourceIdentifier
    Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -SourceIdentifier $errorDataSourceIdentifier

    try {
        $stdOut = ''
        $stdErr = ''
        $isStandardError = $false
        $isStringPresenceError = $false

        $process.StartInfo.Arguments = $ArgumentList

        [void]$process.Start()

        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()

        $getEventLogParams = @{
            OutputDataSourceIdentifier = $outputDataSourceIdentifier;
            ErrorDataSourceIdentifier  = $errorDataSourceIdentifier;
            Quiet                      = $Quiet;
            IgnoreOutputRegex          = $IgnoreOutputRegex
        }

        if ($Output -or ($Quiet -and $ReportOutputOnError)) {
            $getEventLogParams["Output"] = ([ref]$stdOut)
        }

        if ($OutputStdErr -or ($Quiet -and $ReportOutputOnError)) {
            $getEventLogParams["OutputStdErr"] = ([ref]$stdErr)
        }

        if ($FailOnStringPresence) {
            $getEventLogParams["FailOnStringPresence"] = $FailOnStringPresence
        }

        $validateErrorScript = {
            switch ($_) {
                'StandardError' { $isStandardError = $true }
                'StringPresenceError' { $isStringPresenceError = $true }
                Default {}
            }
        }

        $secondsPassed = 0
        while (!$process.WaitForExit(1000)) {
            Write-EventsToLog @getEventLogParams | Where-Object -FilterScript $validateErrorScript
            if ($TimeoutInSeconds -gt 0 -and $secondsPassed -gt $TimeoutInSeconds) {
                Write-Log -Info "Killing external process due to timeout $TimeoutInSeconds s."
                Stop-ProcessForcefully -Process $process -KillTimeoutInSeconds 10
                break
            }
            $secondsPassed += 1
        }
        Write-EventsToLog @getEventLogParams | Where-Object -FilterScript $validateErrorScript
    }
    finally {
        Unregister-Event -SourceIdentifier ExternalProcessOutput
        Unregister-Event -SourceIdentifier ExternalProcessError
    }

    if ($Output) {
        [void]($Output.Value = $stdOut)
    }

    if ($OutputStdErr) {
        [void]($OutputStdErr.Value = $stdErr)
    }

    $errMsg = ''
    if ($CheckLastExitCode -and $process.ExitCode -ne 0) {
        $errMsg = "External command failed with exit code '$($process.ExitCode)'."
    }
    elseif ($CheckStdErr -and $isStandardError) {
        $errMsg = "External command failed - stderr Output present"
    }
    elseif ($isStringPresenceError) {
        $errMsg = "External command failed - stdout contains string '$FailOnStringPresence'"
    }

    if ($errMsg) {
        if ($Quiet -and $ReportOutputOnError) {
            Write-Log -Error "Command line failed: `"$Command`" $($ArgumentList -join ' ')`r`nSTDOUT: $stdOut`r`nSTDERR: $stdErr"
        }
        throw $errMsg
    }

    if ($ReturnLastExitCode) {
        return $process.ExitCode
    }
}
