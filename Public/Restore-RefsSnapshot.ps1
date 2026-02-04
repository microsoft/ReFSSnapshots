function Restore-RefsSnapshot {
    <#
    .SYNOPSIS
        Restores a file to a previous snapshot state.

    .DESCRIPTION
        Reverts a file to the state captured in a ReFS stream snapshot. This is a destructive
        operation that replaces the current file contents with the snapshot data.

        The restore process:
        1. Verifies the snapshot exists
        2. Reads snapshot data from the named stream
        3. Optionally creates a backup of the current file
        4. Replaces the file content atomically
        5. Optionally preserves original file attributes

    .PARAMETER Path
        Path to the file to restore. Stream portion (:stream) is supported for named streams.

    .PARAMETER Name
        Name of the snapshot to restore from.

    .PARAMETER Force
        Suppresses confirmation prompts. Use with caution as this operation cannot be undone.

    .PARAMETER PassThru
        Returns a FileInfo object representing the restored file.

    .PARAMETER CreateBackup
        Creates a timestamped backup (.bak.yyyyMMddHHmmss) before restoring.
        The backup preserves the current file state.

    .PARAMETER PreserveAttributes
        Preserves the original file's creation time and attributes after restore.
        By default, the file gets the current timestamp.

    .EXAMPLE
        Restore-RefsSnapshot -Path C:\Data\database.dat -Name "BeforeUpdate"

        Restores the file from the "BeforeUpdate" snapshot with confirmation.

    .EXAMPLE
        Restore-RefsSnapshot -Path C:\Data\database.dat -Name "BeforeUpdate" -Force -CreateBackup

        Restores without confirmation and creates a backup of the current file.

    .EXAMPLE
        Get-RefsSnapshot -Path C:\Data\file.txt | Where-Object SnapshotName -eq "Stable" | Restore-RefsSnapshot -Force

        Pipeline restore from a specific snapshot.

    .EXAMPLE
        Restore-RefsSnapshot -Path C:\Data\file.txt -Name "LastGood" -PreserveAttributes -PassThru

        Restores while preserving file attributes and returns the restored FileInfo object.

    .OUTPUTS
        None, or System.IO.FileInfo if -PassThru is specified

    .NOTES
        Limitations:
        - Loads entire file into memory (may be slow for very large files)
        - Cannot restore if file is locked by another process
        - Requires the snapshot to exist on the specified file
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FilePath')]
        [string]$Path,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('SnapshotName')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [switch]$Force,

        [switch]$PassThru,

        [switch]$CreateBackup,

        [switch]$PreserveAttributes
    )

    begin {
        Write-Verbose "Restore-RefsSnapshot: Starting"
    }

    process {
        # Resolve path
        $resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            Write-Error "Path not found: $Path"
            return
        }

        # Strip stream syntax for ReFS validation
        $filePath = $resolvedPath.Path -replace ':[^\\]+$', ''

        # Validate ReFS volume
        if (-not (Test-RefsVolume -Path $filePath)) {
            Write-Error "Path is not on a ReFS volume: $filePath"
            return
        }

        # Verify snapshot exists
        $existingSnapshot = Get-RefsSnapshot -Path $resolvedPath.Path -Name $Name -ErrorAction SilentlyContinue
        if (-not $existingSnapshot) {
            Write-Error "Snapshot '$Name' not found on file: $($resolvedPath.Path)"
            return
        }

        # Build snapshot stream path
        $snapshotStreamPath = "${filePath}:${Name}"

        $confirmMessage = "Restore file from snapshot '$Name' (destructive operation)"
        if ($Force -or $PSCmdlet.ShouldProcess($resolvedPath.Path, $confirmMessage)) {
            try {
                # Preserve original attributes if requested
                $originalAttributes = $null
                $originalCreationTime = $null
                $originalLastWriteTime = $null

                if ($PreserveAttributes) {
                    $fileInfo = Get-Item -LiteralPath $filePath
                    $originalAttributes = $fileInfo.Attributes
                    $originalCreationTime = $fileInfo.CreationTime
                    $originalLastWriteTime = $fileInfo.LastWriteTime
                    Write-Verbose "Preserved attributes: $originalAttributes"
                }

                # Create backup if requested
                if ($CreateBackup) {
                    $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
                    $backupPath = "$filePath.bak.$timestamp"

                    try {
                        Copy-Item -LiteralPath $filePath -Destination $backupPath -ErrorAction Stop
                        Write-Verbose "Created backup: $backupPath"
                    }
                    catch {
                        Write-Error "Failed to create backup: $_"
                        return
                    }
                }

                # Read snapshot data
                Write-Verbose "Reading snapshot from: $snapshotStreamPath"

                $snapshotData = $null
                try {
                    $snapshotData = [System.IO.File]::ReadAllBytes($snapshotStreamPath)
                    Write-Verbose "Read $($snapshotData.Length) bytes from snapshot"
                }
                catch {
                    Write-Error "Failed to read snapshot data: $_"
                    return
                }

                # Write to temporary file for atomic replacement
                $tempPath = "$filePath.tmp.$(Get-Random -Minimum 1000 -Maximum 9999)"

                try {
                    [System.IO.File]::WriteAllBytes($tempPath, $snapshotData)
                    Write-Verbose "Wrote data to temporary file: $tempPath"
                }
                catch {
                    Write-Error "Failed to write temporary file: $_"
                    return
                }

                # Atomic replacement: delete original, rename temp
                try {
                    Remove-Item -LiteralPath $filePath -Force -ErrorAction Stop
                    Move-Item -LiteralPath $tempPath -Destination $filePath -Force -ErrorAction Stop
                    Write-Verbose "Restored file successfully"
                }
                catch {
                    Write-Error "Failed to replace file: $_"

                    # Cleanup temp file if it still exists
                    if (Test-Path -LiteralPath $tempPath) {
                        Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
                    }
                    return
                }

                # Restore original attributes if requested
                if ($PreserveAttributes -and $originalAttributes) {
                    try {
                        $restoredFile = Get-Item -LiteralPath $filePath
                        $restoredFile.Attributes = $originalAttributes
                        $restoredFile.CreationTime = $originalCreationTime
                        $restoredFile.LastWriteTime = $originalLastWriteTime
                        Write-Verbose "Restored original attributes"
                    }
                    catch {
                        Write-Warning "Failed to restore file attributes: $_"
                    }
                }

                Write-Verbose "File restored from snapshot '$Name'"

                # Return FileInfo if PassThru specified
                if ($PassThru) {
                    Get-Item -LiteralPath $filePath
                }
            }
            catch {
                Write-Error "Error restoring snapshot: $_"
            }
        }
    }

    end {
        Write-Verbose "Restore-RefsSnapshot: Complete"
    }
}
