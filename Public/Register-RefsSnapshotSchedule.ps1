function Register-RefsSnapshotSchedule {
    <#
    .SYNOPSIS
        Creates a scheduled task for automatic ReFS snapshots.

    .DESCRIPTION
        Registers a Windows scheduled task to automatically create snapshots
        of a file at specified intervals. Includes optional retention policies
        to automatically delete old snapshots.

    .PARAMETER Path
        Path to the file to snapshot. Must be on a ReFS volume.

    .PARAMETER Interval
        Schedule interval: Once, Daily, Weekly, Hourly, AtStartup, AtLogon

    .PARAMETER At
        Time of day for Daily/Weekly/Once intervals (default: 3:00 AM)

    .PARAMETER DaysOfWeek
        Days of week for Weekly interval (default: Sunday)

    .PARAMETER RepetitionInterval
        TimeSpan for Hourly intervals (default: 1 hour)

    .PARAMETER RetentionDays
        Keep snapshots for this many days (default: 30). Set to 0 to disable.

    .PARAMETER RetentionCount
        Keep this many recent snapshots. Overrides RetentionDays if specified.

    .PARAMETER NoRetention
        Disable automatic cleanup of old snapshots.

    .PARAMETER TaskName
        Custom task name (default: auto-generated from file name)

    .PARAMETER RunAs
        User account to run task as (default: SYSTEM)

    .PARAMETER PassThru
        Return the created scheduled task object

    .EXAMPLE
        Register-RefsSnapshotSchedule -Path D:\Data\database.dat -Interval Daily

        Create daily snapshots at 3:00 AM with 30-day retention

    .EXAMPLE
        Register-RefsSnapshotSchedule -Path D:\Data\file.dat -Interval Hourly -RetentionCount 24

        Create hourly snapshots, keep last 24

    .EXAMPLE
        Register-RefsSnapshotSchedule -Path D:\Data\file.dat -Interval Weekly -DaysOfWeek Monday,Friday -NoRetention

        Weekly snapshots on Mon/Fri, keep all snapshots

    .OUTPUTS
        None, or ScheduledTask if -PassThru specified
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FilePath', 'FullName')]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateSet('Once', 'Daily', 'Weekly', 'Hourly', 'AtStartup', 'AtLogon')]
        [string]$Interval,

        [Parameter()]
        [datetime]$At = (Get-Date "3:00 AM"),

        [Parameter()]
        [ValidateSet('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')]
        [string[]]$DaysOfWeek = @('Sunday'),

        [Parameter()]
        [timespan]$RepetitionInterval = (New-TimeSpan -Hours 1),

        [Parameter()]
        [ValidateRange(0, 3650)]
        [int]$RetentionDays = 30,

        [Parameter()]
        [ValidateRange(0, 1000)]
        [int]$RetentionCount = 0,

        [switch]$NoRetention,

        [Parameter()]
        [string]$TaskName,

        [Parameter()]
        [string]$RunAs = 'SYSTEM',

        [switch]$PassThru
    )

    begin {
        Write-Verbose "Register-RefsSnapshotSchedule: Starting"

        # Validate ScheduledTasks module
        if (-not (Get-Module -Name ScheduledTasks -ListAvailable)) {
            throw "ScheduledTasks module not available. This cmdlet requires Windows with Task Scheduler."
        }
    }

    process {
        # Resolve and validate path
        $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            Write-Error "Path not found: $Path"
            return
        }

        # Remove alternate data stream syntax (e.g., file.txt:StreamName -> file.txt)
        $filePath = $resolvedPath.Path -replace ':[^:\\]+$', ''
        if (-not (Test-RefsVolume -Path $filePath)) {
            Write-Error "Path is not on a ReFS volume: $filePath"
            return
        }

        # Generate task name if not provided
        if (-not $TaskName) {
            $fileName = Split-Path -Path $resolvedPath.Path -Leaf
            $TaskName = "RefsSnapshot_$($fileName)_$($Interval)"
        }

        # Check if task already exists
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Error "Scheduled task already exists: $TaskName. Use Update-RefsSnapshotSchedule to modify it."
            return
        }

        # Determine retention settings
        $retDays = 0
        $retCount = 0

        if (-not $NoRetention) {
            if ($RetentionCount -gt 0) {
                $retCount = $RetentionCount
            }
            else {
                $retDays = $RetentionDays
            }
        }

        if ($PSCmdlet.ShouldProcess("$Path", "Create scheduled snapshot task '$TaskName' ($Interval)")) {
            try {
                # Generate PowerShell script
                $script = New-RefsScheduledTaskScript -Path $resolvedPath.Path -RetentionDays $retDays -RetentionCount $retCount

                # Save script to temp location
                $scriptDir = Join-Path $env:ProgramData "ReFSSnapshots\Scripts"
                if (-not (Test-Path $scriptDir)) {
                    New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
                }

                $scriptPath = Join-Path $scriptDir "$TaskName.ps1"
                $script | Out-File -FilePath $scriptPath -Encoding UTF8 -Force

                # Create scheduled task trigger
                $triggerParams = @{
                    Interval = $Interval
                    At = $At
                }

                if ($Interval -eq 'Weekly') {
                    $triggerParams['DaysOfWeek'] = $DaysOfWeek
                }
                elseif ($Interval -eq 'Hourly') {
                    $triggerParams['RepetitionInterval'] = $RepetitionInterval
                }

                $trigger = ConvertTo-ScheduledTaskTrigger @triggerParams

                # Create scheduled task action
                $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$scriptPath`""

                # Create task settings
                $settings = New-ScheduledTaskSettings -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

                # Register task
                $registerParams = @{
                    TaskName = $TaskName
                    Trigger = $trigger
                    Action = $action
                    Settings = $settings
                    Description = "Automated ReFS snapshot for $($resolvedPath.Path)"
                }

                if ($RunAs -eq 'SYSTEM') {
                    $registerParams['User'] = 'SYSTEM'
                    $registerParams['RunLevel'] = 'Highest'
                }
                else {
                    $registerParams['User'] = $RunAs
                }

                $task = Register-ScheduledTask @registerParams -ErrorAction Stop

                Write-Verbose "Scheduled task '$TaskName' registered successfully"

                if ($PassThru) {
                    $task
                }
            }
            catch {
                Write-Error "Failed to register scheduled task: $_"

                # Cleanup script file on error
                if (Test-Path $scriptPath) {
                    Remove-Item $scriptPath -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    end {
        Write-Verbose "Register-RefsSnapshotSchedule: Complete"
    }
}
