<#
.SYNOPSIS
    Comprehensive examples for restoring files from ReFS snapshots

.DESCRIPTION
    Demonstrates various restore scenarios including safety features,
    error handling, pipeline operations, and recovery workflows
#>

# Import the module
Import-Module ReFSSnapshots

#region Setup
# These examples assume you have a ReFS volume (e.g., D:\)
# Adjust paths to match your environment
$TestFile = "D:\Data\important.dat"
$SnapshotName = "BeforeUpdate_20260203"
#endregion

#region Scenario 1: Basic Restore with Confirmation
Write-Host "`n=== Scenario 1: Basic Restore with Confirmation ===" -ForegroundColor Cyan

# Interactive restore - prompts for confirmation
Restore-RefsSnapshot -Path $TestFile -Name $SnapshotName

# Use -Confirm:$false to suppress prompt (same as -Force)
Restore-RefsSnapshot -Path $TestFile -Name $SnapshotName -Confirm:$false
#endregion

#region Scenario 2: Safe Restore with Backup
Write-Host "`n=== Scenario 2: Safe Restore with Backup ===" -ForegroundColor Cyan

# Always create a backup before restoring
# This creates a file like: important.dat.bak.20260203145530
Restore-RefsSnapshot -Path $TestFile -Name $SnapshotName -CreateBackup -Force

# Verify backup was created
$backupFiles = Get-ChildItem "$TestFile.bak.*" | Sort-Object LastWriteTime -Descending
Write-Host "Latest backup: $($backupFiles[0].Name)" -ForegroundColor Green

# You can restore from the backup if needed
# Copy-Item $backupFiles[0].FullName -Destination $TestFile -Force
#endregion

#region Scenario 3: Restore with Attribute Preservation
Write-Host "`n=== Scenario 3: Restore with Attribute Preservation ===" -ForegroundColor Cyan

# Get original file metadata
$original = Get-Item $TestFile
Write-Host "Original creation time: $($original.CreationTime)"
Write-Host "Original attributes: $($original.Attributes)"

# Restore while preserving creation time and attributes
Restore-RefsSnapshot -Path $TestFile -Name $SnapshotName -PreserveAttributes -Force

# Verify attributes were preserved
$restored = Get-Item $TestFile
Write-Host "Restored creation time: $($restored.CreationTime)" -ForegroundColor Green
Write-Host "Match: $($original.CreationTime -eq $restored.CreationTime)" -ForegroundColor Green
#endregion

#region Scenario 4: Pipeline Restore Operations
Write-Host "`n=== Scenario 4: Pipeline Restore Operations ===" -ForegroundColor Cyan

# Restore the most recent snapshot
$latestSnapshot = Get-RefsSnapshot -Path $TestFile |
    Sort-Object SnapshotName -Descending |
    Select-Object -First 1

if ($latestSnapshot) {
    Write-Host "Restoring from latest snapshot: $($latestSnapshot.SnapshotName)"
    $latestSnapshot | Restore-RefsSnapshot -Force -PassThru
}

# Restore a specific snapshot by pattern
Get-RefsSnapshot -Path $TestFile -Name "BeforeUpdate_*" |
    Where-Object SnapshotName -match "202602" |
    Select-Object -First 1 |
    Restore-RefsSnapshot -CreateBackup -Force
#endregion

#region Scenario 5: Batch Restore Multiple Files
Write-Host "`n=== Scenario 5: Batch Restore Multiple Files ===" -ForegroundColor Cyan

# Restore all database files to their "DailyBackup" snapshots
Get-ChildItem D:\Data\*.dat | ForEach-Object {
    $file = $_.FullName
    $snapshot = "DailyBackup_$(Get-Date -Format 'yyyyMMdd')"

    # Check if snapshot exists before restoring
    if (Get-RefsSnapshot -Path $file -Name $snapshot) {
        Write-Host "Restoring $($_.Name) from $snapshot"
        Restore-RefsSnapshot -Path $file -Name $snapshot -CreateBackup -Force
    }
    else {
        Write-Warning "Snapshot not found for $($_.Name): $snapshot"
    }
}
#endregion

#region Scenario 6: Conditional Restore Based on Comparison
Write-Host "`n=== Scenario 6: Conditional Restore Based on Comparison ===" -ForegroundColor Cyan

# Only restore if significant changes detected
$changes = Compare-RefsSnapshot -Path $TestFile -Name $SnapshotName

if ($changes) {
    $totalChanged = ($changes | Measure-Object -Property Length -Sum).Sum
    Write-Host "Total bytes changed: $totalChanged"

    if ($totalChanged -gt 1MB) {
        Write-Host "Significant changes detected - restoring from snapshot" -ForegroundColor Yellow
        Restore-RefsSnapshot -Path $TestFile -Name $SnapshotName -CreateBackup -Force
    }
    else {
        Write-Host "Minor changes - no restore needed" -ForegroundColor Green
    }
}
else {
    Write-Host "No changes detected" -ForegroundColor Green
}
#endregion

#region Scenario 7: WhatIf Testing
Write-Host "`n=== Scenario 7: WhatIf Testing ===" -ForegroundColor Cyan

# Preview restore operation without making changes
Restore-RefsSnapshot -Path $TestFile -Name $SnapshotName -WhatIf

# Useful for testing in scripts
$whatIfPreference = $true
Restore-RefsSnapshot -Path $TestFile -Name $SnapshotName -Force
$whatIfPreference = $false
#endregion

#region Scenario 8: Error Handling
Write-Host "`n=== Scenario 8: Error Handling ===" -ForegroundColor Cyan

# Robust restore with error handling
try {
    # Verify file exists
    if (-not (Test-Path $TestFile)) {
        throw "File not found: $TestFile"
    }

    # Verify snapshot exists
    $snapshot = Get-RefsSnapshot -Path $TestFile -Name $SnapshotName
    if (-not $snapshot) {
        throw "Snapshot not found: $SnapshotName"
    }

    # Perform restore with all safety features
    $result = Restore-RefsSnapshot `
        -Path $TestFile `
        -Name $SnapshotName `
        -CreateBackup `
        -PreserveAttributes `
        -Force `
        -PassThru `
        -ErrorAction Stop

    Write-Host "Restore successful!" -ForegroundColor Green
    Write-Host "  File: $($result.FullName)"
    Write-Host "  Size: $($result.Length) bytes"
    Write-Host "  Modified: $($result.LastWriteTime)"
}
catch {
    Write-Error "Restore failed: $_"

    # Optionally restore from backup if it exists
    $latestBackup = Get-ChildItem "$TestFile.bak.*" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($latestBackup) {
        Write-Host "Restoring from backup: $($latestBackup.Name)" -ForegroundColor Yellow
        Copy-Item $latestBackup.FullName -Destination $TestFile -Force
    }
}
#endregion

#region Scenario 9: Restore Point Selection
Write-Host "`n=== Scenario 9: Restore Point Selection ===" -ForegroundColor Cyan

# Interactive restore point selection
$snapshots = Get-RefsSnapshot -Path $TestFile
if ($snapshots) {
    Write-Host "`nAvailable snapshots:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $snapshots.Count; $i++) {
        Write-Host "  [$i] $($snapshots[$i].SnapshotName)"
    }

    # In a real scenario, you might prompt the user
    # $selection = Read-Host "Select snapshot to restore (0-$($snapshots.Count - 1))"
    # For this example, we'll select the first one
    $selection = 0

    if ($selection -ge 0 -and $selection -lt $snapshots.Count) {
        $selectedSnapshot = $snapshots[$selection]
        Write-Host "Restoring from: $($selectedSnapshot.SnapshotName)" -ForegroundColor Green

        Restore-RefsSnapshot `
            -Path $TestFile `
            -Name $selectedSnapshot.SnapshotName `
            -CreateBackup `
            -Force
    }
}
#endregion

#region Scenario 10: Disaster Recovery Workflow
Write-Host "`n=== Scenario 10: Disaster Recovery Workflow ===" -ForegroundColor Cyan

# Complete disaster recovery procedure
function Invoke-DisasterRecovery {
    param(
        [string]$FilePath,
        [string]$RecoverySnapshotPattern = "DailyBackup_*"
    )

    Write-Host "Starting disaster recovery for: $FilePath" -ForegroundColor Yellow

    # Step 1: Verify file is corrupted or needs recovery
    if (Test-Path $FilePath) {
        Write-Host "  Current file exists - creating emergency backup"
        Copy-Item $FilePath "$FilePath.emergency.$(Get-Date -Format 'yyyyMMddHHmmss')"
    }

    # Step 2: Find latest viable snapshot
    $snapshots = Get-RefsSnapshot -Path $FilePath -Name $RecoverySnapshotPattern |
        Sort-Object SnapshotName -Descending

    if (-not $snapshots) {
        Write-Error "No recovery snapshots found matching pattern: $RecoverySnapshotPattern"
        return
    }

    # Step 3: Attempt restore from latest snapshot
    foreach ($snapshot in $snapshots) {
        Write-Host "  Attempting restore from: $($snapshot.SnapshotName)"

        try {
            Restore-RefsSnapshot `
                -Path $FilePath `
                -Name $snapshot.SnapshotName `
                -PreserveAttributes `
                -Force `
                -ErrorAction Stop

            Write-Host "  Recovery successful from: $($snapshot.SnapshotName)" -ForegroundColor Green
            return
        }
        catch {
            Write-Warning "  Failed to restore from $($snapshot.SnapshotName): $_"
            continue
        }
    }

    Write-Error "All recovery attempts failed"
}

# Example usage
# Invoke-DisasterRecovery -FilePath $TestFile -RecoverySnapshotPattern "BeforeUpdate_*"
#endregion

#region Scenario 11: Restore with Verification
Write-Host "`n=== Scenario 11: Restore with Verification ===" -ForegroundColor Cyan

# Restore and verify file integrity
$originalHash = $null

# Capture current file hash before restore (if file exists)
if (Test-Path $TestFile) {
    $originalHash = (Get-FileHash $TestFile -Algorithm SHA256).Hash
}

# Perform restore
Restore-RefsSnapshot -Path $TestFile -Name $SnapshotName -Force

# Verify restore by checking file hash
$restoredHash = (Get-FileHash $TestFile -Algorithm SHA256).Hash

Write-Host "Original hash: $originalHash"
Write-Host "Restored hash: $restoredHash"

# You could also compare with a known good hash from snapshot metadata
# if ($restoredHash -eq $expectedHash) { ... }
#endregion

#region Scenario 12: Scheduled Restore Points
Write-Host "`n=== Scenario 12: Working with Scheduled Snapshots ===" -ForegroundColor Cyan

# Find and restore from today's scheduled snapshot
$todaySnapshot = "DailyBackup_$(Get-Date -Format 'yyyyMMdd')"

if (Get-RefsSnapshot -Path $TestFile -Name $todaySnapshot) {
    Write-Host "Restoring from today's scheduled snapshot: $todaySnapshot"
    Restore-RefsSnapshot -Path $TestFile -Name $todaySnapshot -CreateBackup -Force
}
else {
    Write-Warning "Today's snapshot not found: $todaySnapshot"

    # Fallback to yesterday's snapshot
    $yesterdaySnapshot = "DailyBackup_$(Get-Date (Get-Date).AddDays(-1) -Format 'yyyyMMdd')"

    if (Get-RefsSnapshot -Path $TestFile -Name $yesterdaySnapshot) {
        Write-Host "Restoring from yesterday's snapshot: $yesterdaySnapshot"
        Restore-RefsSnapshot -Path $TestFile -Name $yesterdaySnapshot -CreateBackup -Force
    }
}
#endregion

Write-Host "`n=== Restore Scenarios Complete ===" -ForegroundColor Green
Write-Host "Remember: Always use -CreateBackup for production restores!" -ForegroundColor Yellow
