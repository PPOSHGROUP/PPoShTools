function Stop-ProcessForcefully {

    <#
    .SYNOPSIS
    Kills process forcefully along with its children.

    .EXAMPLE
    Stop-ProcessForcefully -Process $process
    #>

    [CmdletBinding()]
    [OutputType([void])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWMICmdlet', '')]
    param(
        # Process object.
        [Parameter(Mandatory = $true)]
        [object]
        $Process,

        # Time to wait for process before killing it.
        [Parameter(Mandatory = $true)]
        [int]
        $KillTimeoutInSeconds
    )

    $childProcesses = Get-WmiObject -Class Win32_Process -Filter "ParentProcessID=$($Process.Id)" | Select-Object -ExpandProperty ProcessID

    try {
        if ($childProcesses) {
            Write-Log -Info "Killing child processes: $childProcesses"
            Stop-Process -Id $childProcesses -Force
        }
        else {
            Write-Log -Info "No child processes for pid $($Process.Id)"
        }
        Write-Log -Info "Killing process $($Process.Id)"
        $Process.Kill()
    }
    catch {
        Write-Log -Warn "Kill method thrown exception: $_ - waiting for exit."
    }
    if (!$Process.WaitForExit($KillTimeoutInSeconds * 1000)) {
        throw "Cannot kill process (pid $($Process.Id)) - still running after $($KillTimeoutInSeconds * 1000 * 2) s"
    }
    Write-Log -Info "Process $($Process.Id) killed along with its children."
}