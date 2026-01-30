function Unregister-RefsSnapshotSchedule {
    <#
    .SYNOPSIS
        Removes a scheduled ReFS snapshot task.

    .DESCRIPTION
        Unregisters a scheduled task and deletes its associated script file.
        Requires confirmation by default.

    .PARAMETER TaskName
        Name of the task to remove

    .PARAMETER Force
        Skip confirmation prompt

    .EXAMPLE
        Unregister-RefsSnapshotSchedule -TaskName "RefsSnapshot_database.dat_Daily"

        Remove scheduled task with confirmation

    .EXAMPLE
        Get-RefsSnapshotSchedule | Unregister-RefsSnapshotSchedule -Force

        Remove all scheduled snapshot tasks without confirmation

    .OUTPUTS
        None
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$TaskName,

        [switch]$Force
    )

    begin {
        Write-Verbose "Unregister-RefsSnapshotSchedule: Starting"
    }

    process {
        try {
            # Get the task
            $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            $taskInfo = Get-RefsScheduledTaskInfo -Task $task

            if (-not $taskInfo) {
                Write-Error "Task '$TaskName' is not a valid RefsSnapshot scheduled task"
                return
            }

            $confirmMessage = "Remove scheduled snapshot task '$TaskName' for '$($taskInfo.FilePath)'"

            if ($Force -or $PSCmdlet.ShouldProcess($TaskName, $confirmMessage)) {
                # Unregister the task
                Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
                Write-Verbose "Scheduled task '$TaskName' unregistered"

                # Delete script file
                if ($taskInfo.ScriptPath -and (Test-Path $taskInfo.ScriptPath)) {
                    Remove-Item -Path $taskInfo.ScriptPath -Force -ErrorAction SilentlyContinue
                    Write-Verbose "Deleted script file: $($taskInfo.ScriptPath)"
                }
            }
        }
        catch {
            Write-Error "Failed to unregister scheduled task: $_"
        }
    }

    end {
        Write-Verbose "Unregister-RefsSnapshotSchedule: Complete"
    }
}
