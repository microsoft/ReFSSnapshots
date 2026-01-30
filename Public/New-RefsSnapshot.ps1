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

    .PARAMETER PassThru
        Returns an object representing the created snapshot.

    .EXAMPLE
        New-RefsSnapshot -Path C:\Data\database.dat -Name "BeforeUpdate"

        Creates a snapshot named "BeforeUpdate" of the default stream.

    .EXAMPLE
        New-RefsSnapshot -Path C:\Data\file.txt:MyStream -Name "Backup_2024"

        Creates a snapshot of the named stream "MyStream".

    .OUTPUTS
        None, or PSCustomObject if -PassThru is specified
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FilePath', 'FullName')]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [switch]$PassThru
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

                    if ($PassThru) {
                        [PSCustomObject]@{
                            PSTypeName   = 'RefsSnapshot'
                            SnapshotName = $Name
                            FilePath     = $resolvedPath.Path
                            Created      = Get-Date
                        }
                    }
                }
                else {
                    Write-Error "Failed to create snapshot: $($result.Error)"
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
