function Export-RefsSnapshot {
    <#
    .SYNOPSIS
        Exports a ReFS stream snapshot to a standalone file.

    .DESCRIPTION
        Reads snapshot data from a ReFS alternate data stream and writes it to a new
        standalone file. The exported file is a normal file with its own primary data
        stream, not an alternate data stream. This is a non-destructive operation that
        leaves the original file and snapshot unchanged.

    .PARAMETER Path
        Path to the file containing the snapshot. Can include :stream syntax for named streams.

    .PARAMETER Name
        Name of the snapshot to export.

    .PARAMETER Destination
        Path where the exported file should be written. If the parent directory does not
        exist, it will be created.

    .PARAMETER PreserveAttributes
        If specified, copies file attributes and timestamps from the snapshot to the
        exported file. Note: Creation time is set to current time by default unless
        this switch is used.

    .PARAMETER Force
        Overwrites the destination file if it already exists without prompting.

    .EXAMPLE
        Export-RefsSnapshot -Path C:\Data\document.txt -Name "Backup_2024" -Destination C:\Archive\document_old.txt

        Exports the "Backup_2024" snapshot to a new file.

    .EXAMPLE
        Export-RefsSnapshot -Path C:\Data\file.txt -Name "Version1" -Destination C:\Export\file_v1.txt -PreserveAttributes

        Exports the snapshot and preserves the original file attributes and timestamps.

    .EXAMPLE
        Get-RefsSnapshot -Path C:\Data\file.txt -Name "Daily_*" | Export-RefsSnapshot -Destination C:\Backups\

        Exports all snapshots matching "Daily_*" pattern. When piping from Get-RefsSnapshot
        without specifying a filename, uses the original filename with snapshot name appended.

    .EXAMPLE
        Export-RefsSnapshot -Path C:\Data\file.txt -Name "Backup" -Destination C:\Archive\file.txt -Force

        Exports the snapshot, overwriting the destination file if it exists.

    .OUTPUTS
        System.IO.FileInfo - Returns the exported file object
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FilePath')]
        [string]$Path,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('SnapshotName')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Destination,

        [switch]$PreserveAttributes,

        [switch]$Force
    )

    begin {
        Write-Verbose "Export-RefsSnapshot: Starting"
    }

    process {
        # Resolve source path
        $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            Write-Error "Path not found: $Path"
            return
        }

        # Validate ReFS volume
        # Remove alternate data stream syntax (e.g., file.txt:StreamName -> file.txt)
        $filePath = $resolvedPath.Path -replace ':[^:\\]+$', ''
        if (-not (Test-RefsVolume -Path $filePath)) {
            Write-Error "Path is not on a ReFS volume: $filePath"
            return
        }

        # Construct snapshot stream path with $SNAPSHOT suffix (ReFS format)
        $snapshotStreamPath = "${filePath}:${Name}:`$SNAPSHOT"

        # Verify snapshot exists by checking if the stream is listed
        try {
            $streams = Get-Item -LiteralPath $filePath -Stream * -ErrorAction Stop
            $snapshotExists = $streams | Where-Object { $_.Stream -eq "${Name}:`$SNAPSHOT" }
            if (-not $snapshotExists) {
                Write-Error "Snapshot '$Name' not found on file: $filePath"
                return
            }
        }
        catch {
            Write-Error "Failed to verify snapshot existence: $_"
            return
        }

        # Resolve destination path (may not exist yet)
        $destinationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)

        # Check if destination exists and handle accordingly
        if ((Test-Path -LiteralPath $destinationPath) -and -not $Force) {
            Write-Error "Destination file already exists: $destinationPath. Use -Force to overwrite."
            return
        }

        # Ensure destination directory exists
        $destinationDir = Split-Path -Parent $destinationPath
        if ($destinationDir -and -not (Test-Path -LiteralPath $destinationDir)) {
            try {
                Write-Verbose "Creating destination directory: $destinationDir"
                New-Item -Path $destinationDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Error "Failed to create destination directory: $_"
                return
            }
        }

        $confirmMessage = "Export snapshot '$Name' from '$filePath' to '$destinationPath'"
        if ($PSCmdlet.ShouldProcess($destinationPath, $confirmMessage)) {
            try {
                # Read snapshot data from alternate data stream using Get-Content
                Write-Verbose "Reading snapshot data from: $filePath (stream: $Name)"
                $snapshotData = Get-Content -LiteralPath $filePath -Stream $Name -Encoding Byte -Raw

                # Write to destination as normal file (primary data stream)
                Write-Verbose "Writing $($snapshotData.Length) bytes to: $destinationPath"
                [System.IO.File]::WriteAllBytes($destinationPath, $snapshotData)

                # Get the exported file object
                $exportedFile = Get-Item -LiteralPath $destinationPath

                # Preserve attributes if requested
                if ($PreserveAttributes) {
                    Write-Verbose "Preserving file attributes"
                    $sourceFile = Get-Item -LiteralPath $filePath

                    # Copy attributes
                    $exportedFile.Attributes = $sourceFile.Attributes

                    # Copy timestamps
                    $exportedFile.CreationTime = $sourceFile.CreationTime
                    $exportedFile.LastWriteTime = $sourceFile.LastWriteTime
                    $exportedFile.LastAccessTime = $sourceFile.LastAccessTime

                    # Refresh to get updated properties
                    $exportedFile = Get-Item -LiteralPath $destinationPath
                }

                Write-Verbose "Snapshot exported successfully: $destinationPath"

                # Return the exported file object
                $exportedFile
            }
            catch {
                Write-Error "Error exporting snapshot: $_"
            }
        }
    }

    end {
        Write-Verbose "Export-RefsSnapshot: Complete"
    }
}
