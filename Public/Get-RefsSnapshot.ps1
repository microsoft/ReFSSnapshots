function Get-RefsSnapshot {
    <#
    .SYNOPSIS
        Lists ReFS stream snapshots for a file.

    .DESCRIPTION
        Retrieves all snapshots matching the specified pattern for a file/stream on a ReFS volume.
        Supports wildcard patterns for snapshot names.

    .PARAMETER Path
        Path to the file. Can include :stream syntax for named streams.

    .PARAMETER Name
        Snapshot name or pattern to match. Supports wildcards (* and ?).
        Default is "*" to list all snapshots.

    .EXAMPLE
        Get-RefsSnapshot -Path C:\Data\database.dat

        Lists all snapshots for the file.

    .EXAMPLE
        Get-RefsSnapshot -Path C:\Data\file.txt -Name "Backup_*"

        Lists all snapshots starting with "Backup_".

    .EXAMPLE
        Get-ChildItem C:\Data\*.dat | Get-RefsSnapshot

        Lists snapshots for all .dat files via pipeline.

    .OUTPUTS
        RefsSnapshot objects with SnapshotName and FilePath properties
    #>
    [CmdletBinding()]
    [OutputType('RefsSnapshot')]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FilePath', 'FullName')]
        [string]$Path,

        [Parameter()]
        [string]$Name = '*'
    )

    begin {
        Write-Verbose "Get-RefsSnapshot: Starting"
    }

    process {
        # Resolve path
        $resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            Write-Error "Path not found: $Path"
            return
        }

        # Validate ReFS volume
        $filePath = $resolvedPath.Path -replace ':.*$', ''
        if (-not (Test-RefsVolume -Path $filePath)) {
            Write-Error "Path is not on a ReFS volume: $filePath"
            return
        }

        try {
            $result = Invoke-RefsUtilStreamSnapshot -Operation List -SnapshotName $Name -FilePath $resolvedPath.Path

            if ($result.Success) {
                $snapshots = ConvertFrom-RefsUtilOutput -Output $result.Output -Operation List

                foreach ($snapshot in $snapshots) {
                    $snapshot | Add-Member -NotePropertyName 'FilePath' -NotePropertyValue $resolvedPath.Path -PassThru
                }
            }
            else {
                Write-Error "Failed to list snapshots: $($result.Error)"
            }
        }
        catch {
            Write-Error "Error listing snapshots: $_"
        }
    }

    end {
        Write-Verbose "Get-RefsSnapshot: Complete"
    }
}
