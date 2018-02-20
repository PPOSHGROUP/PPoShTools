function Write-EventsToLog {

    <#
    .SYNOPSIS
    Get logs from event.

    .DESCRIPTION
    Catches output from event for OutputDataSourceIdentifier (stdout) and ErrorDataSourceIdentifier (error)
    and writes proper logs.

    .OUTPUTS
    If event was generated for ErrorDataSourceIdentier then "StandardError" will be returned.

    .EXAMPLE
    Write-EventsToLog -OutputDataSourceIdentifier "ExternalProcessOutput" -ErrorDataSourceIdentifier "ExternalProcessError" -Output ([ref]$stdOut) -Quiet $false
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        # Event output data received source identifier.
        [Parameter(Mandatory=$true)]
        [string]
        $OutputDataSourceIdentifier,

        # Event error data received source identifier.
        [Parameter(Mandatory=$true)]
        [string]
        $ErrorDataSourceIdentifier,

        # Reference parameter with STDOUT text.
        [Parameter(Mandatory=$false)]
        [ref]
        $Output,

        # Reference parameter with STDERR text.
        [Parameter(Mandatory=$false)]
        [ref]
        $OutputStdErr,

        # If not null and given string will be present in stdout then "StringPresenceError" will be returned.
        [Parameter(Mandatory=$false)]
        [string]
        $FailOnStringPresence,

        # If true, no output from the command will be passed to the console.
        [Parameter(Mandatory=$true)]
        [bool]
        $Quiet,

        # Each stdout/stderr line that match this regex will be ignored (not written to console/$output).
        [Parameter(Mandatory=$false)]
        [string]
        $IgnoreOutputRegex
    )

    $error = ""
    # note: sometimes 'Collection was modified' is thrown by Get-Event.
    # Tried storing events in a hashset and removing them later in a loop, but it doesn't seem to help.
    # $eventIds = New-Object System.Collections.Generic.HashSet[System.String]

    try {
        Get-Event -SourceIdentifier $OutputDataSourceIdentifier -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.SourceEventArgs.Data -and (!$IgnoreOutputRegex -or $_.SourceEventArgs.Data -inotmatch $IgnoreOutputRegex)) {
                if (!$Quiet) {
                    Write-Log -Info ("[STDOUT] " + $_.SourceEventArgs.Data) -NoHeader
                }

                if ($FailOnStringPresence -and $_.SourceEventArgs.Data -imatch $FailOnStringPresence) {
                    $error = "StringPresenceError"
                }

                if ($Output) {
                    $Output.Value += $_.SourceEventArgs.Data
                }
            }
            Remove-Event -EventIdentifier $_.EventIdentifier -ErrorAction SilentlyContinue
            #[void]($eventIds.Add($_.EventIdentifier))
        }

        Get-Event -SourceIdentifier $ErrorDataSourceIdentifier -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.SourceEventArgs.Data -and (!$IgnoreOutputRegex -or $_.SourceEventArgs.Data -inotmatch $IgnoreOutputRegex)) {
                if (!$Quiet) {
                    Write-Log -Error ("[STDERR] " + $_.SourceEventArgs.Data) -NoHeader
                }
                $error = "StandardError"
                if ($OutputStdErr) {
                    $OutputStdErr.Value += $_.SourceEventArgs.Data
                }
            }
            Remove-Event -EventIdentifier $_.EventIdentifier -ErrorAction SilentlyContinue
            #[void]($eventIds.Add($_.EventIdentifier))
        }
    }
    catch {
      Write-Log -Warn ("Couldn't get events: {0}" -f $_)
    }

    <#try {
        # remove processed events from event queue
        foreach ($eventId in $eventIds) {
            Remove-Event -EventIdentifier $eventId -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Log -Warn ("Couldn't remove event: {0}" -f $_)
    }#>

    return $error
}