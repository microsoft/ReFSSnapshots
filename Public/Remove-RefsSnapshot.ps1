function Remove-RefsSnapshot {
    <#
    .SYNOPSIS
        Deletes a ReFS stream snapshot.

    .DESCRIPTION
        Removes a specified snapshot from a file/stream on a ReFS volume.
        This operation cannot be undone.

    .PARAMETER Path
        Path to the file. Stream portion (:stream) is ignored for delete operations.

    .PARAMETER Name
        Name of the snapshot to delete.

    .PARAMETER Force
        Suppresses confirmation prompts.

    .EXAMPLE
        Remove-RefsSnapshot -Path C:\Data\database.dat -Name "OldBackup"

        Deletes the snapshot named "OldBackup" with confirmation.

    .EXAMPLE
        Remove-RefsSnapshot -Path C:\Data\database.dat -Name "OldBackup" -Force

        Deletes the snapshot without confirmation.

    .EXAMPLE
        Get-RefsSnapshot -Path C:\Data\file.txt -Name "Temp_*" | Remove-RefsSnapshot -Force

        Deletes all snapshots matching "Temp_*" pattern.

    .OUTPUTS
        None
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FilePath')]
        [string]$Path,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('SnapshotName')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [switch]$Force
    )

    begin {
        Write-Verbose "Remove-RefsSnapshot: Starting"
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

        $confirmMessage = "Delete snapshot '$Name' from '$($resolvedPath.Path)'"
        if ($Force -or $PSCmdlet.ShouldProcess($resolvedPath.Path, $confirmMessage)) {
            try {
                $result = Invoke-RefsUtilStreamSnapshot -Operation Delete -SnapshotName $Name -FilePath $resolvedPath.Path

                if ($result.Success) {
                    Write-Verbose "Snapshot '$Name' deleted successfully"
                }
                else {
                    Write-Error "Failed to delete snapshot: $($result.Error)"
                }
            }
            catch {
                Write-Error "Error deleting snapshot: $_"
            }
        }
    }

    end {
        Write-Verbose "Remove-RefsSnapshot: Complete"
    }
}
