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
            # Actual format from refsutil: "VCN: 0x0    Clusters: 0x1    LCN: 0x53200    Properties: 0x10."
            $lines = $Output -split "`r`n|`n" | Where-Object { $_.Trim() -ne '' }

            foreach ($line in $lines) {
                # Parse VCN/Clusters/LCN format (actual refsutil output)
                if ($line -match 'VCN:\s*0x([0-9A-Fa-f]+)\s+Clusters:\s*0x([0-9A-Fa-f]+)\s+LCN:\s*0x([0-9A-Fa-f]+)\s+Properties:\s*0x([0-9A-Fa-f]+)') {
                    $vcn = [Convert]::ToInt64($matches[1], 16)
                    $clusters = [Convert]::ToInt64($matches[2], 16)
                    $lcn = [Convert]::ToInt64($matches[3], 16)
                    $properties = [Convert]::ToInt64($matches[4], 16)

                    # ReFS typically uses 64KB cluster size, calculate byte offsets
                    $clusterSize = 65536

                    [PSCustomObject]@{
                        PSTypeName      = 'RefsSnapshotDelta'
                        VCN             = $vcn
                        Clusters        = $clusters
                        LCN             = $lcn
                        Properties      = $properties
                        OffsetBytes     = $vcn * $clusterSize
                        LengthBytes     = $clusters * $clusterSize
                    }
                }
                # Legacy format: "Offset: 0x1000, Length: 0x2000" (if ever encountered)
                elseif ($line -match 'Offset:\s*0x([0-9A-Fa-f]+).*Length:\s*0x([0-9A-Fa-f]+)') {
                    [PSCustomObject]@{
                        PSTypeName = 'RefsSnapshotDelta'
                        OffsetBytes     = [Convert]::ToInt64($matches[1], 16)
                        LengthBytes     = [Convert]::ToInt64($matches[2], 16)
                    }
                }
                # Legacy format: "Range: offset length" (if ever encountered)
                elseif ($line -match 'Range:\s*(\d+)\s+(\d+)') {
                    [PSCustomObject]@{
                        PSTypeName = 'RefsSnapshotDelta'
                        OffsetBytes     = [int64]$matches[1]
                        LengthBytes     = [int64]$matches[2]
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
