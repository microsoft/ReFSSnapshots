function Update-RefsSnapshotSchedule {
    <#
    .SYNOPSIS
        Updates an existing scheduled ReFS snapshot task.

    .DESCRIPTION
        Modifies the schedule, retention policy, or other settings of an
        existing scheduled snapshot task.

    .PARAMETER TaskName
        Name of the task to update

    .PARAMETER Interval
        New schedule interval

    .PARAMETER At
        New time of day for Daily/Weekly/Once intervals

    .PARAMETER DaysOfWeek
        New days of week for Weekly interval

    .PARAMETER RepetitionInterval
        New TimeSpan for Hourly intervals

    .PARAMETER RetentionDays
        New retention in days (0 = disable)

    .PARAMETER RetentionCount
        New retention count

    .PARAMETER NoRetention
        Disable retention policy

    .PARAMETER Enabled
        Enable or disable the task

    .EXAMPLE
        Update-RefsSnapshotSchedule -TaskName "RefsSnapshot_database.dat_Daily" -RetentionDays 60

        Change retention to 60 days

    .EXAMPLE
        Update-RefsSnapshotSchedule -TaskName "RefsSnapshot_database.dat_Daily" -Interval Hourly

        Change from daily to hourly snapshots

    .EXAMPLE
        Update-RefsSnapshotSchedule -TaskName "RefsSnapshot_database.dat_Daily" -Enabled $false

        Disable the scheduled task

    .OUTPUTS
        None
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$TaskName,

        [Parameter()]
        [ValidateSet('Once', 'Daily', 'Weekly', 'Hourly', 'AtStartup', 'AtLogon')]
        [string]$Interval,

        [Parameter()]
        [datetime]$At,

        [Parameter()]
        [ValidateSet('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')]
        [string[]]$DaysOfWeek,

        [Parameter()]
        [timespan]$RepetitionInterval,

        [Parameter()]
        [ValidateRange(0, 3650)]
        [int]$RetentionDays,

        [Parameter()]
        [ValidateRange(0, 1000)]
        [int]$RetentionCount,

        [switch]$NoRetention,

        [Parameter()]
        [bool]$Enabled
    )

    begin {
        Write-Verbose "Update-RefsSnapshotSchedule: Starting"
    }

    process {
        try {
            # Get existing task
            $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            $taskInfo = Get-RefsScheduledTaskInfo -Task $task

            if (-not $taskInfo) {
                Write-Error "Task '$TaskName' is not a valid RefsSnapshot scheduled task"
                return
            }

            $needsScriptUpdate = $false
            $needsTriggerUpdate = $false
            $needsStateUpdate = $false

            # Determine what needs updating
            if ($PSBoundParameters.ContainsKey('RetentionDays') -or
                $PSBoundParameters.ContainsKey('RetentionCount') -or
                $PSBoundParameters.ContainsKey('NoRetention')) {
                $needsScriptUpdate = $true
            }

            if ($PSBoundParameters.ContainsKey('Interval') -or
                $PSBoundParameters.ContainsKey('At') -or
                $PSBoundParameters.ContainsKey('DaysOfWeek') -or
                $PSBoundParameters.ContainsKey('RepetitionInterval')) {
                $needsTriggerUpdate = $true
            }

            if ($PSBoundParameters.ContainsKey('Enabled')) {
                $needsStateUpdate = $true
            }

            if ($PSCmdlet.ShouldProcess($TaskName, "Update scheduled snapshot task")) {
                # Update script if retention changed
                if ($needsScriptUpdate) {
                    $retDays = 0
                    $retCount = 0

                    if (-not $NoRetention) {
                        if ($PSBoundParameters.ContainsKey('RetentionCount') -and $RetentionCount -gt 0) {
                            $retCount = $RetentionCount
                        }
                        elseif ($PSBoundParameters.ContainsKey('RetentionDays')) {
                            $retDays = $RetentionDays
                        }
                        else {
                            # Keep existing retention
                            $retDays = $taskInfo.RetentionDays
                            $retCount = $taskInfo.RetentionCount
                        }
                    }

                    $script = New-RefsScheduledTaskScript -Path $taskInfo.FilePath -RetentionDays $retDays -RetentionCount $retCount
                    $script | Out-File -FilePath $taskInfo.ScriptPath -Encoding UTF8 -Force
                    Write-Verbose "Updated script file"
                }

                # Update trigger if schedule changed
                if ($needsTriggerUpdate) {
                    $triggerParams = @{
                        Interval = if ($Interval) { $Interval } else { $taskInfo.Interval }
                    }

                    if ($At) {
                        $triggerParams['At'] = $At
                    }

                    if ($DaysOfWeek) {
                        $triggerParams['DaysOfWeek'] = $DaysOfWeek
                    }

                    if ($RepetitionInterval) {
                        $triggerParams['RepetitionInterval'] = $RepetitionInterval
                    }

                    $trigger = ConvertTo-ScheduledTaskTrigger @triggerParams
                    Set-ScheduledTask -TaskName $TaskName -Trigger $trigger -ErrorAction Stop | Out-Null
                    Write-Verbose "Updated task trigger"
                }

                # Update enabled state
                if ($needsStateUpdate) {
                    if ($Enabled) {
                        Enable-ScheduledTask -TaskName $TaskName -ErrorAction Stop | Out-Null
                        Write-Verbose "Enabled scheduled task"
                    }
                    else {
                        Disable-ScheduledTask -TaskName $TaskName -ErrorAction Stop | Out-Null
                        Write-Verbose "Disabled scheduled task"
                    }
                }

                Write-Verbose "Scheduled task '$TaskName' updated successfully"
            }
        }
        catch {
            Write-Error "Failed to update scheduled task: $_"
        }
    }

    end {
        Write-Verbose "Update-RefsSnapshotSchedule: Complete"
    }
}
