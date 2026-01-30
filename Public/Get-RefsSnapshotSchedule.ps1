function Get-RefsSnapshotSchedule {
    <#
    .SYNOPSIS
        Gets scheduled ReFS snapshot tasks.

    .DESCRIPTION
        Retrieves information about registered scheduled snapshot tasks.
        Returns details including schedule, retention policy, and status.

    .PARAMETER TaskName
        Name of specific task to retrieve

    .PARAMETER Path
        Filter tasks by file path

    .EXAMPLE
        Get-RefsSnapshotSchedule

        List all scheduled snapshot tasks

    .EXAMPLE
        Get-RefsSnapshotSchedule -TaskName "RefsSnapshot_database.dat_Daily"

        Get specific scheduled task

    .EXAMPLE
        Get-RefsSnapshotSchedule -Path D:\Data\file.dat

        Find schedules for specific file

    .OUTPUTS
        RefsSnapshotSchedule objects with schedule details
    #>
    [CmdletBinding()]
    [OutputType('RefsSnapshotSchedule')]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$TaskName,

        [Parameter()]
        [Alias('FilePath')]
        [string]$Path
    )

    begin {
        Write-Verbose "Get-RefsSnapshotSchedule: Starting"
    }

    process {
        try {
            # Get scheduled tasks
            if ($TaskName) {
                $tasks = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            }
            else {
                # Get all tasks, filter to RefsSnapshot tasks
                $tasks = Get-ScheduledTask -TaskName "RefsSnapshot_*" -ErrorAction SilentlyContinue
            }

            if (-not $tasks) {
                Write-Verbose "No scheduled snapshot tasks found"
                return
            }

            foreach ($task in $tasks) {
                # Parse task info
                $taskInfo = Get-RefsScheduledTaskInfo -Task $task

                if ($taskInfo) {
                    # Filter by path if specified
                    if ($Path) {
                        $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
                        if ($resolvedPath -and $taskInfo.FilePath -ne $resolvedPath.Path) {
                            continue
                        }
                    }

                    $taskInfo
                }
            }
        }
        catch {
            Write-Error "Error retrieving scheduled tasks: $_"
        }
    }

    end {
        Write-Verbose "Get-RefsSnapshotSchedule: Complete"
    }
}
