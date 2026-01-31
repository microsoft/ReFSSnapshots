function New-RefsSnapshot {
    <#
    .SYNOPSIS
        Creates a new ReFS stream snapshot.

    .DESCRIPTION
        Creates a point-in-time snapshot of a data stream within a file on a ReFS volume.
        Requires Windows Server 2019+ or Windows 10+ with ReFS support.

    .PARAMETER Path
        Path to the file. Can include :stream syntax for named streams.
        If no stream is specified, defaults to the unnamed $DATA stream.

    .PARAMETER Name
        Name for the snapshot. Must be unique for this file/stream.

    .EXAMPLE
        New-RefsSnapshot -Path C:\Data\database.dat -Name "BeforeUpdate"

        Creates a snapshot named "BeforeUpdate" and returns the snapshot object.

    .EXAMPLE
        $snapshot = New-RefsSnapshot -Path C:\Data\file.txt -Name "Backup_2024"

        Creates a snapshot and stores the returned object in a variable.

    .EXAMPLE
        Get-ChildItem C:\Data\*.dat | New-RefsSnapshot -Name "Daily_Backup"

        Creates snapshots for all .dat files via pipeline.

    .OUTPUTS
        PSCustomObject with SnapshotName, FilePath, and DateCreated properties
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType('RefsSnapshot')]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FilePath', 'FullName')]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    begin {
        Write-Verbose "New-RefsSnapshot: Starting"
    }

    process {
        # Resolve path
        $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            Write-Error "Path not found: $Path"
            return
        }

        # Validate ReFS volume (only for file path, not stream)
        # Remove alternate data stream syntax (e.g., file.txt:StreamName -> file.txt)
        $filePath = $resolvedPath.Path -replace ':[^:\\]+$', ''
        if (-not (Test-RefsVolume -Path $filePath)) {
            Write-Error "Path is not on a ReFS volume: $filePath"
            return
        }

        if ($PSCmdlet.ShouldProcess($Path, "Create snapshot '$Name'")) {
            try {
                $result = Invoke-RefsUtilStreamSnapshot -Operation Create -SnapshotName $Name -FilePath $resolvedPath.Path

                if ($result.Success) {
                    Write-Verbose "Snapshot '$Name' created successfully"

                    # Always return snapshot object
                    [PSCustomObject]@{
                        PSTypeName   = 'RefsSnapshot'
                        SnapshotName = $Name
                        FilePath     = $resolvedPath.Path
                        DateCreated  = Get-Date
                    }
                }
                else {
                    $errorMsg = if ($result.Error) { $result.Error } else { $result.Output }
                    Write-Error "Failed to create snapshot: $errorMsg"
                }
            }
            catch {
                Write-Error "Error creating snapshot: $_"
            }
        }
    }

    end {
        Write-Verbose "New-RefsSnapshot: Complete"
    }
}
