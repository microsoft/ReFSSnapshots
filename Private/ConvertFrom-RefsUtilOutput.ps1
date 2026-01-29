function ConvertFrom-RefsUtilOutput {
    <#
    .SYNOPSIS
        Parses refsutil.exe output into structured PowerShell objects.

    .DESCRIPTION
        Converts text output from refsutil streamsnapshot commands into
        structured PSCustomObject instances for pipeline use.

    .PARAMETER Output
        Raw text output from refsutil.exe

    .PARAMETER Operation
        Type of operation (List, Query, Create, Delete) to determine parsing logic

    .OUTPUTS
        PSCustomObject or PSCustomObject[] depending on operation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Output,

        [Parameter(Mandatory)]
        [ValidateSet('List', 'Query', 'Create', 'Delete')]
        [string]$Operation
    )

    switch ($Operation) {
        'List' {
            # Parse snapshot listing output
            # Expected format: One snapshot name per line
            $lines = $Output -split "`r`n|`n" | Where-Object { $_.Trim() -ne '' }

            foreach ($line in $lines) {
                if ($line -match '^\s*(.+?)\s*$') {
                    [PSCustomObject]@{
                        PSTypeName   = 'RefsSnapshot'
                        SnapshotName = $matches[1].Trim()
                    }
                }
            }
        }

        'Query' {
            # Parse delta query output
            # Expected format: Offset and length information for modified regions
            $lines = $Output -split "`r`n|`n" | Where-Object { $_.Trim() -ne '' }

            foreach ($line in $lines) {
                # Parse format like "Offset: 0x1000, Length: 0x2000"
                if ($line -match 'Offset:\s*0x([0-9A-Fa-f]+).*Length:\s*0x([0-9A-Fa-f]+)') {
                    [PSCustomObject]@{
                        PSTypeName = 'RefsSnapshotDelta'
                        Offset     = [Convert]::ToInt64($matches[1], 16)
                        Length     = [Convert]::ToInt64($matches[2], 16)
                    }
                }
                # Alternative format: "Range: offset length"
                elseif ($line -match 'Range:\s*(\d+)\s+(\d+)') {
                    [PSCustomObject]@{
                        PSTypeName = 'RefsSnapshotDelta'
                        Offset     = [int64]$matches[1]
                        Length     = [int64]$matches[2]
                    }
                }
            }
        }

        'Create' {
            # Create typically returns success/failure status
            [PSCustomObject]@{
                PSTypeName = 'RefsSnapshotResult'
                Success    = $true
                Message    = $Output.Trim()
            }
        }

        'Delete' {
            # Delete typically returns success/failure status
            [PSCustomObject]@{
                PSTypeName = 'RefsSnapshotResult'
                Success    = $true
                Message    = $Output.Trim()
            }
        }
    }
}
