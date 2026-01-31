function Compare-RefsSnapshot {
    <#
    .SYNOPSIS
        Compares a ReFS snapshot with the current stream state.

    .DESCRIPTION
        Lists all modifications between a snapshot and the current state of the stream.
        The snapshot must be older than the current stream state and both must be in
        the same snapshot chain.

    .PARAMETER Path
        Path to the file. Can include :stream syntax for named streams.

    .PARAMETER Name
        Name of the snapshot to compare against current state.

    .EXAMPLE
        Compare-RefsSnapshot -Path C:\Data\database.dat -Name "BeforeUpdate"

        Shows all changes made since the "BeforeUpdate" snapshot was created.

    .EXAMPLE
        Compare-RefsSnapshot -Path C:\Data\file.txt:MyStream -Name "Backup_Jan"

        Compares the named stream against the snapshot.

    .OUTPUTS
        RefsSnapshotDelta objects with Offset and Length properties
    #>
    [CmdletBinding()]
    [OutputType('RefsSnapshotDelta')]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FilePath', 'FullName')]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    begin {
        Write-Verbose "Compare-RefsSnapshot: Starting"
    }

    process {
        # Resolve path
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

        try {
            $result = Invoke-RefsUtilStreamSnapshot -Operation Query -SnapshotName $Name -FilePath $resolvedPath.Path

            if ($result.Success) {
                $deltas = ConvertFrom-RefsUtilOutput -Output $result.Output -Operation Query

                foreach ($delta in $deltas) {
                    $delta | Add-Member -NotePropertyName 'FilePath' -NotePropertyValue $resolvedPath.Path
                    $delta | Add-Member -NotePropertyName 'SnapshotName' -NotePropertyValue $Name
                    $delta
                }
            }
            else {
                $errorMsg = if ($result.Error) { $result.Error } else { $result.Output }
                Write-Error "Failed to query snapshot deltas: $errorMsg"
            }
        }
        catch {
            Write-Error "Error querying snapshot: $_"
        }
    }

    end {
        Write-Verbose "Compare-RefsSnapshot: Complete"
    }
}
