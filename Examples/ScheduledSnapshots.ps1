<#
.SYNOPSIS
    Examples for scheduling automatic ReFS snapshots

.DESCRIPTION
    Demonstrates how to use the scheduling cmdlets to automate
    snapshot creation and management with retention policies
#>

Import-Module ReFSSnapshots

#region Basic Scheduling Examples

# Example 1: Daily snapshots at 3 AM with 30-day retention (default)
Register-RefsSnapshotSchedule -Path "D:\Data\database.dat" -Interval Daily

# Example 2: Hourly snapshots, keep last 24
Register-RefsSnapshotSchedule -Path "D:\Data\logfile.dat" `
    -Interval Hourly `
    -RetentionCount 24

# Example 3: Weekly snapshots on Monday and Friday at 2 AM
Register-RefsSnapshotSchedule -Path "D:\Data\archive.dat" `
    -Interval Weekly `
    -DaysOfWeek Monday,Friday `
    -At (Get-Date "2:00 AM")

# Example 4: Daily snapshots with no automatic cleanup
Register-RefsSnapshotSchedule -Path "D:\Data\important.dat" `
    -Interval Daily `
    -NoRetention

#endregion

#region Managing Schedules

# List all scheduled snapshot tasks
Get-RefsSnapshotSchedule

# Find schedules for specific file
Get-RefsSnapshotSchedule -Path "D:\Data\database.dat"

# Get specific schedule details
Get-RefsSnapshotSchedule -TaskName "RefsSnapshot_database.dat_Daily"

#endregion

#region Updating Schedules

# Change retention policy to 60 days
Update-RefsSnapshotSchedule -TaskName "RefsSnapshot_database.dat_Daily" -RetentionDays 60

# Change from daily to hourly
Update-RefsSnapshotSchedule -TaskName "RefsSnapshot_database.dat_Daily" -Interval Hourly

# Disable a schedule temporarily
Update-RefsSnapshotSchedule -TaskName "RefsSnapshot_database.dat_Daily" -Enabled $false

# Re-enable
Update-RefsSnapshotSchedule -TaskName "RefsSnapshot_database.dat_Daily" -Enabled $true

#endregion

#region Removing Schedules

# Remove with confirmation
Unregister-RefsSnapshotSchedule -TaskName "RefsSnapshot_database.dat_Daily"

# Remove without confirmation
Unregister-RefsSnapshotSchedule -TaskName "RefsSnapshot_database.dat_Daily" -Force

# Remove all schedules for a file
Get-RefsSnapshotSchedule -Path "D:\Data\database.dat" |
    Unregister-RefsSnapshotSchedule -Force

#endregion

#region Advanced Scenarios

# Scenario 1: Multi-tier retention strategy
# Hourly snapshots for recent data, daily for older backups
Register-RefsSnapshotSchedule -Path "D:\Data\active.dat" `
    -Interval Hourly `
    -RetentionCount 24 `
    -TaskName "RefsSnapshot_active_Hourly"

Register-RefsSnapshotSchedule -Path "D:\Data\active.dat" `
    -Interval Daily `
    -RetentionDays 30 `
    -TaskName "RefsSnapshot_active_Daily"

# Scenario 2: Schedule multiple files with same policy
$files = Get-ChildItem "D:\Data\*.dat"
foreach ($file in $files) {
    Register-RefsSnapshotSchedule -Path $file.FullName `
        -Interval Daily `
        -RetentionDays 30 `
        -Verbose
}

# Scenario 3: Custom task name and schedule
Register-RefsSnapshot Schedule -Path "D:\Data\critical.dat" `
    -Interval Daily `
    -At (Get-Date "1:00 AM") `
    -RetentionDays 90 `
    -TaskName "CriticalDB_DailyBackup"

# Scenario 4: Monitoring scheduled snapshots
$schedules = Get-RefsSnapshotSchedule

Write-Host "`nScheduled Snapshot Summary:" -ForegroundColor Cyan
Write-Host "Total Schedules: $($schedules.Count)"
Write-Host "Enabled: $($schedules | Where-Object Enabled | Measure-Object).Count"
Write-Host "With Retention: $($schedules | Where-Object HasRetention | Measure-Object).Count"

$schedules | Format-Table TaskName, FilePath, Interval, @{
    Label = 'Retention'
    Expression = {
        if ($_.RetentionDays -gt 0) { "$($_.RetentionDays) days" }
        elseif ($_.RetentionCount -gt 0) { "$($_.RetentionCount) snapshots" }
        else { "None" }
    }
}, NextRunTime -AutoSize

# Scenario 5: Report on scheduled task health
foreach ($schedule in Get-RefsSnapshotSchedule) {
    $status = if ($schedule.Enabled) { "Active" } else { "Disabled" }

    Write-Host "`n$($schedule.TaskName): $status" -ForegroundColor $(if ($schedule.Enabled) { 'Green' } else { 'Yellow' })
    Write-Host "  File: $($schedule.FilePath)"
    Write-Host "  Schedule: $($schedule.Interval) - $($schedule.Schedule)"
    Write-Host "  Last Run: $($schedule.LastRunTime)"
    Write-Host "  Next Run: $($schedule.NextRunTime)"

    if ($schedule.HasRetention) {
        if ($schedule.RetentionDays -gt 0) {
            Write-Host "  Retention: $($schedule.RetentionDays) days"
        }
        else {
            Write-Host "  Retention: Last $($schedule.RetentionCount) snapshots"
        }
    }
    else {
        Write-Host "  Retention: Disabled (manual cleanup required)"
    }
}

#endregion

#region Bulk Operations

# Setup automated snapshots for entire directory
function Initialize-RefsSnapshotAutomation {
    param(
        [string]$Path,
        [string]$Interval = 'Daily',
        [int]$RetentionDays = 30
    )

    $files = Get-ChildItem -Path $Path -File -Recurse -Filter "*.dat"

    foreach ($file in $files) {
        try {
            # Check if on ReFS volume
            $volume = Get-Volume -FilePath $file.FullName -ErrorAction SilentlyContinue
            if ($volume.FileSystemType -ne 'ReFS') {
                Write-Warning "Skipping $($file.FullName) - not on ReFS volume"
                continue
            }

            Register-RefsSnapshotSchedule -Path $file.FullName `
                -Interval $Interval `
                -RetentionDays $RetentionDays `
                -ErrorAction Stop

            Write-Host "Scheduled: $($file.Name)" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to schedule $($file.Name): $_"
        }
    }
}

# Usage
Initialize-RefsSnapshotAutomation -Path "D:\Data" -Interval Daily -RetentionDays 30

#endregion
