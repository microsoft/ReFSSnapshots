function Get-RefsScheduledTaskInfo {
    <#
    .SYNOPSIS
        Extracts ReFS snapshot schedule information from a scheduled task.

    .DESCRIPTION
        Parses a scheduled task to extract snapshot configuration details
        including path, retention policy, and schedule information.

    .PARAMETER Task
        ScheduledTask object from Get-ScheduledTask

    .OUTPUTS
        PSCustomObject with schedule details
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Microsoft.Management.Infrastructure.CimInstance]$Task
    )

    process {
        # Extract script arguments from task action
        $action = $Task.Actions | Select-Object -First 1
        if (-not $action) { return $null }

        # Parse PowerShell arguments to extract script path
        $arguments = $action.Arguments
        if ($arguments -notmatch '-File\s+"([^"]+)"') { return $null }

        $scriptPath = $matches[1]
        if (-not (Test-Path $scriptPath)) { return $null }

        # Read and parse script content
        $scriptContent = Get-Content -Path $scriptPath -Raw

        # Extract file path
        if ($scriptContent -notmatch "New-RefsSnapshot -Path '([^']+)'") { return $null }
        $filePath = $matches[1]

        # Extract retention settings
        $retentionDays = 0
        $retentionCount = 0
        $hasRetention = $true

        if ($scriptContent -match 'AddDays\(-(\d+)\)') {
            $retentionDays = [int]$matches[1]
        }
        elseif ($scriptContent -match 'Select-Object -Skip (\d+)') {
            $retentionCount = [int]$matches[1]
        }
        else {
            $hasRetention = $false
        }

        # Extract trigger information
        $trigger = $Task.Triggers | Select-Object -First 1
        $interval = 'Unknown'
        $schedule = $null

        if ($trigger) {
            $triggerClass = $trigger.CimClass.CimClassName

            switch ($triggerClass) {
                'MSFT_TaskDailyTrigger' {
                    $interval = 'Daily'
                    $schedule = $trigger.StartBoundary
                }
                'MSFT_TaskWeeklyTrigger' {
                    $interval = 'Weekly'
                    $schedule = $trigger.StartBoundary
                }
                'MSFT_TaskTimeTrigger' {
                    if ($trigger.Repetition.Interval) {
                        $interval = 'Hourly'
                        $schedule = "Every $($trigger.Repetition.Interval)"
                    }
                    else {
                        $interval = 'Once'
                        $schedule = $trigger.StartBoundary
                    }
                }
                'MSFT_TaskBootTrigger' {
                    $interval = 'AtStartup'
                }
                'MSFT_TaskLogonTrigger' {
                    $interval = 'AtLogon'
                }
            }
        }

        # Return structured info
        [PSCustomObject]@{
            PSTypeName      = 'RefsSnapshotSchedule'
            TaskName        = $Task.TaskName
            TaskPath        = $Task.TaskPath
            FilePath        = $filePath
            Interval        = $interval
            Schedule        = $schedule
            Enabled         = $Task.State -eq 'Ready'
            RetentionDays   = $retentionDays
            RetentionCount  = $retentionCount
            HasRetention    = $hasRetention
            LastRunTime     = $Task.LastRunTime
            NextRunTime     = $Task.NextRunTime
            ScriptPath      = $scriptPath
        }
    }
}
