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
            $null = New-RefsSnapshot -Path $path -Name $SnapshotName -ErrorAction Stop
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

#region Snapshot Archival and Export

function Export-SnapshotsToArchive {
    param(
        [string]$SourcePath,
        [string]$ArchiveDestination,
        [string]$SnapshotPattern = "*",
        [switch]$PreserveAttributes
    )

    # Create archive directory if it doesn't exist
    if (-not (Test-Path $ArchiveDestination)) {
        New-Item -Path $ArchiveDestination -ItemType Directory -Force | Out-Null
    }

    # Get all matching snapshots
    $snapshots = Get-RefsSnapshot -Path $SourcePath -Name $SnapshotPattern

    if (-not $snapshots) {
        Write-Warning "No snapshots found matching pattern: $SnapshotPattern"
        return
    }

    Write-Host "Exporting $($snapshots.Count) snapshots to archive..." -ForegroundColor Cyan

    $results = foreach ($snapshot in $snapshots) {
        $fileName = Split-Path $SourcePath -Leaf
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        $extension = [System.IO.Path]::GetExtension($fileName)
        $destFileName = "${baseName}_$($snapshot.SnapshotName)${extension}"
        $destPath = Join-Path $ArchiveDestination $destFileName

        try {
            $params = @{
                Path = $SourcePath
                Name = $snapshot.SnapshotName
                Destination = $destPath
                Force = $true
                ErrorAction = 'Stop'
            }

            if ($PreserveAttributes) {
                $params['PreserveAttributes'] = $true
            }

            Export-RefsSnapshot @params

            [PSCustomObject]@{
                Snapshot = $snapshot.SnapshotName
                Destination = $destPath
                Success = $true
                Error = $null
            }

            Write-Verbose "Exported: $($snapshot.SnapshotName) -> $destFileName"
        }
        catch {
            [PSCustomObject]@{
                Snapshot = $snapshot.SnapshotName
                Destination = $destPath
                Success = $false
                Error = $_.Exception.Message
            }

            Write-Warning "Failed to export $($snapshot.SnapshotName): $_"
        }
    }

    # Summary
    $successCount = ($results | Where-Object Success).Count
    $failCount = ($results | Where-Object { -not $_.Success }).Count

    Write-Host "`nExport Summary:" -ForegroundColor Cyan
    Write-Host "  Successful: $successCount" -ForegroundColor Green
    Write-Host "  Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host "  Archive Location: $ArchiveDestination"

    return $results
}

# Usage: Export all daily backups to network storage
# Export-SnapshotsToArchive -SourcePath "D:\Data\database.dat" `
#     -ArchiveDestination "\\nas\archives\database" `
#     -SnapshotPattern "DailyBackup_*" `
#     -PreserveAttributes

# Usage: Export to external drive for offline backup
# Export-SnapshotsToArchive -SourcePath "D:\Data\critical.dat" `
#     -ArchiveDestination "E:\Backups\Critical" `
#     -SnapshotPattern "BeforeUpdate_*"

#endregion
