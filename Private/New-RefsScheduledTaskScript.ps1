function New-RefsScheduledTaskScript {
    <#
    .SYNOPSIS
        Generates PowerShell script for scheduled snapshot task.

    .DESCRIPTION
        Creates a PowerShell script that will be executed by Task Scheduler
        to create snapshots and optionally clean up old ones.

    .PARAMETER Path
        Path to the file to snapshot

    .PARAMETER RetentionDays
        Number of days to retain snapshots (0 = no retention)

    .PARAMETER RetentionCount
        Number of snapshots to retain (0 = no retention)

    .OUTPUTS
        String containing PowerShell script
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [int]$RetentionDays = 0,

        [Parameter()]
        [int]$RetentionCount = 0
    )

    $modulePath = $PSScriptRoot | Split-Path -Parent
    $snapshotName = "AutoSnapshot_`$(Get-Date -Format 'yyyyMMdd_HHmmss')"

    $script = @"
# Auto-generated scheduled snapshot script
Import-Module '$modulePath\ReFSSnapshots.psd1' -Force

try {
    # Create snapshot
    `$snapshot = New-RefsSnapshot -Path '$Path' -Name '$snapshotName' -ErrorAction Stop
    Write-Output "Snapshot created: `$(`$snapshot.SnapshotName) at `$(`$snapshot.DateCreated)"

"@

    if ($RetentionDays -gt 0) {
        $script += @"

    # Retention: Delete snapshots older than $RetentionDays days
    `$cutoffDate = (Get-Date).AddDays(-$RetentionDays).ToString('yyyyMMdd')
    `$oldSnapshots = Get-RefsSnapshot -Path '$Path' -Name 'AutoSnapshot_*' -ErrorAction SilentlyContinue |
        Where-Object { `$_.SnapshotName -lt "AutoSnapshot_`$cutoffDate" }

    foreach (`$snapshot in `$oldSnapshots) {
        Remove-RefsSnapshot -Path '$Path' -Name `$snapshot.SnapshotName -Force -ErrorAction Continue
        Write-Output "Deleted old snapshot: `$(`$snapshot.SnapshotName)"
    }
"@
    }
    elseif ($RetentionCount -gt 0) {
        $script += @"

    # Retention: Keep only last $RetentionCount snapshots
    `$allSnapshots = Get-RefsSnapshot -Path '$Path' -Name 'AutoSnapshot_*' -ErrorAction SilentlyContinue |
        Sort-Object SnapshotName -Descending

    `$toDelete = `$allSnapshots | Select-Object -Skip $RetentionCount

    foreach (`$snapshot in `$toDelete) {
        Remove-RefsSnapshot -Path '$Path' -Name `$snapshot.SnapshotName -Force -ErrorAction Continue
        Write-Output "Deleted old snapshot: `$(`$snapshot.SnapshotName)"
    }
"@
    }

    $script += @"

}
catch {
    Write-Error "Scheduled snapshot failed: `$_"
    exit 1
}
"@

    return $script
}
