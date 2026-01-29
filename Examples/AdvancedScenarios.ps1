<#
.SYNOPSIS
    Advanced usage scenarios for ReFSSnapshots module

.DESCRIPTION
    Demonstrates advanced workflows including automated backup,
    change tracking, and snapshot lifecycle management
#>

Import-Module ReFSSnapshots

#region Automated Backup with Retention Policy

function Backup-RefsFile {
    param(
        [string]$Path,
        [int]$RetentionDays = 7
    )

    # Create new snapshot
    $snapshotName = "AutoBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-RefsSnapshot -Path $Path -Name $snapshotName -Verbose

    # Clean up old snapshots
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays).ToString('yyyyMMdd')
    Get-RefsSnapshot -Path $Path -Name "AutoBackup_*" | Where-Object {
        $_.SnapshotName -lt "AutoBackup_$cutoffDate"
    } | Remove-RefsSnapshot -Force -Verbose
}

# Usage
Backup-RefsFile -Path "D:\Data\important.dat" -RetentionDays 7

#endregion

#region Change Detection and Reporting

function Get-RefsFileChanges {
    param(
        [string]$Path,
        [string]$BaselineSnapshot
    )

    $deltas = Compare-RefsSnapshot -Path $Path -Name $BaselineSnapshot

    if ($deltas) {
        $totalBytes = ($deltas | Measure-Object -Property Length -Sum).Sum

        [PSCustomObject]@{
            FilePath        = $Path
            BaselineSnapshot = $BaselineSnapshot
            ModifiedRegions = $deltas.Count
            TotalBytesChanged = $totalBytes
            Changes         = $deltas
        }
    }
    else {
        Write-Host "No changes detected since snapshot '$BaselineSnapshot'"
    }
}

# Usage
Get-RefsFileChanges -Path "D:\Data\database.dat" -BaselineSnapshot "BeforeUpdate_20240129"

#endregion

#region Snapshot Comparison Matrix

function Compare-AllSnapshots {
    param([string]$Path)

    $snapshots = Get-RefsSnapshot -Path $Path | Sort-Object SnapshotName

    foreach ($snapshot in $snapshots) {
        Write-Host "`nAnalyzing snapshot: $($snapshot.SnapshotName)"

        try {
            $changes = Compare-RefsSnapshot -Path $Path -Name $snapshot.SnapshotName
            $changeCount = ($changes | Measure-Object).Count

            [PSCustomObject]@{
                Snapshot = $snapshot.SnapshotName
                Changes  = $changeCount
                Status   = if ($changeCount -eq 0) { "No changes" } else { "$changeCount regions modified" }
            }
        }
        catch {
            Write-Warning "Could not compare snapshot: $_"
        }
    }
}

# Usage
Compare-AllSnapshots -Path "D:\Data\logfile.dat"

#endregion

#region Bulk Operations with Error Handling

function New-BulkRefsSnapshot {
    param(
        [string[]]$Paths,
        [string]$SnapshotName
    )

    $results = foreach ($path in $Paths) {
        try {
            New-RefsSnapshot -Path $path -Name $SnapshotName -PassThru -ErrorAction Stop
            [PSCustomObject]@{
                Path    = $path
                Success = $true
                Error   = $null
            }
        }
        catch {
            [PSCustomObject]@{
                Path    = $path
                Success = $false
                Error   = $_.Exception.Message
            }
        }
    }

    # Summary
    $successCount = ($results | Where-Object Success).Count
    $failCount = ($results | Where-Object { -not $_.Success }).Count

    Write-Host "`nSnapshot Creation Summary:"
    Write-Host "  Successful: $successCount"
    Write-Host "  Failed: $failCount"

    $results | Where-Object { -not $_.Success } | Format-Table Path, Error
}

# Usage
$files = Get-ChildItem D:\Data\*.dat | Select-Object -ExpandProperty FullName
New-BulkRefsSnapshot -Paths $files -SnapshotName "BulkBackup_$(Get-Date -Format 'yyyyMMdd')"

#endregion
