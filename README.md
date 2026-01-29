# ReFSSnapshots PowerShell Module

PowerShell module for managing ReFS (Resilient File System) stream snapshots on Windows. Provides easy-to-use cmdlets that wrap the native `refsutil.exe streamsnapshot` functionality with proper PowerShell semantics, pipeline support, and error handling.

## Features

- **Create snapshots**: Point-in-time snapshots of files and streams
- **List snapshots**: Query existing snapshots with wildcard support
- **Delete snapshots**: Remove snapshots with confirmation safeguards
- **Compare snapshots**: Track changes between snapshot and current state
- **Pipeline support**: Full pipeline integration for bulk operations
- **Type safety**: Strong parameter validation and type checking
- **Error handling**: Comprehensive error handling and ReFS volume validation

## Requirements

- Windows Server 2019+ or Windows 10+
- ReFS-formatted volume (version 3.7+)
- PowerShell 5.1 or later (including PowerShell Core)
- Administrator privileges (for some operations)

## Installation

```powershell
# Clone the repository
git clone https://github.com/microsoft/ReFSSnapshots.git
cd ReFSSnapshots

# Import the module
Import-Module .\ReFSSnapshots.psd1
```

Or install from PowerShell Gallery (when published):

```powershell
Install-Module -Name ReFSSnapshots
```

## Quick Start

```powershell
# Import module
Import-Module ReFSSnapshots

# Create a snapshot
New-RefsSnapshot -Path D:\Data\database.dat -Name "BeforeUpdate"

# List all snapshots
Get-RefsSnapshot -Path D:\Data\database.dat

# Compare with current state
Compare-RefsSnapshot -Path D:\Data\database.dat -Name "BeforeUpdate"

# Delete a snapshot
Remove-RefsSnapshot -Path D:\Data\database.dat -Name "BeforeUpdate" -Force
```

## Cmdlets

### New-RefsSnapshot

Creates a new snapshot of a file or stream.

```powershell
New-RefsSnapshot -Path <String> -Name <String> [-PassThru] [-WhatIf] [-Confirm]
```

**Examples:**

```powershell
# Create a snapshot
New-RefsSnapshot -Path D:\Data\file.dat -Name "Backup_2024"

# Create snapshot with return object
New-RefsSnapshot -Path D:\Data\file.dat -Name "Backup" -PassThru

# Snapshot a named stream
New-RefsSnapshot -Path D:\Data\file.txt:MyStream -Name "StreamBackup"
```

### Get-RefsSnapshot

Lists snapshots for a file with optional pattern matching.

```powershell
Get-RefsSnapshot -Path <String> [-Name <String>]
```

**Examples:**

```powershell
# List all snapshots
Get-RefsSnapshot -Path D:\Data\file.dat

# List with wildcard pattern
Get-RefsSnapshot -Path D:\Data\file.dat -Name "Backup_2024*"

# Pipeline from Get-ChildItem
Get-ChildItem D:\Data\*.dat | Get-RefsSnapshot
```

### Remove-RefsSnapshot

Deletes a snapshot from a file.

```powershell
Remove-RefsSnapshot -Path <String> -Name <String> [-Force] [-WhatIf] [-Confirm]
```

**Examples:**

```powershell
# Delete with confirmation
Remove-RefsSnapshot -Path D:\Data\file.dat -Name "OldBackup"

# Delete without confirmation
Remove-RefsSnapshot -Path D:\Data\file.dat -Name "OldBackup" -Force

# Pipeline deletion
Get-RefsSnapshot -Path D:\Data\file.dat -Name "Temp_*" | Remove-RefsSnapshot -Force
```

### Compare-RefsSnapshot

Shows modifications between a snapshot and the current file state.

```powershell
Compare-RefsSnapshot -Path <String> -Name <String>
```

**Examples:**

```powershell
# Compare with snapshot
Compare-RefsSnapshot -Path D:\Data\file.dat -Name "BeforeUpdate"

# Pipeline to analyze changes
$changes = Compare-RefsSnapshot -Path D:\Data\file.dat -Name "Baseline"
$totalBytes = ($changes | Measure-Object -Property Length -Sum).Sum
Write-Host "Total bytes changed: $totalBytes"
```

## Advanced Usage

### Automated Backup with Retention

```powershell
function Backup-WithRetention {
    param($Path, $RetentionDays = 7)

    # Create new snapshot
    $name = "Auto_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-RefsSnapshot -Path $Path -Name $name

    # Remove old snapshots
    $cutoff = (Get-Date).AddDays(-$RetentionDays).ToString('yyyyMMdd')
    Get-RefsSnapshot -Path $Path -Name "Auto_*" |
        Where-Object { $_.SnapshotName -lt "Auto_$cutoff" } |
        Remove-RefsSnapshot -Force
}
```

### Bulk Operations

```powershell
# Create snapshots for multiple files
Get-ChildItem D:\Data\*.dat | ForEach-Object {
    New-RefsSnapshot -Path $_.FullName -Name "DailyBackup_$(Get-Date -Format 'yyyyMMdd')"
}

# Generate change report
$report = Get-ChildItem D:\Data\*.dat | ForEach-Object {
    $changes = Compare-RefsSnapshot -Path $_.FullName -Name "Baseline"
    [PSCustomObject]@{
        File = $_.Name
        ChangedRegions = $changes.Count
        TotalBytes = ($changes | Measure-Object -Property Length -Sum).Sum
    }
}
$report | Format-Table
```

## Testing

The module includes comprehensive Pester tests:

```powershell
# Run tests
Invoke-Pester .\Tests\ReFSSnapshots.Tests.ps1

# Run with coverage
Invoke-Pester .\Tests\ReFSSnapshots.Tests.ps1 -CodeCoverage .\**\*.ps1
```

Note: Integration tests require a ReFS volume and are skipped by default.

## Examples

See the `Examples\` directory for more scenarios:
- `BasicUsage.ps1` - Common operations
- `AdvancedScenarios.ps1` - Complex workflows and automation

## Architecture

```
ReFSSnapshots/
├── ReFSSnapshots.psd1          # Module manifest
├── ReFSSnapshots.psm1          # Main module loader
├── Public/                      # Exported cmdlets
│   ├── New-RefsSnapshot.ps1
│   ├── Get-RefsSnapshot.ps1
│   ├── Remove-RefsSnapshot.ps1
│   └── Compare-RefsSnapshot.ps1
├── Private/                     # Internal helpers
│   ├── Invoke-RefsUtilStreamSnapshot.ps1
│   ├── Test-RefsVolume.ps1
│   └── ConvertFrom-RefsUtilOutput.ps1
├── Tests/                       # Pester tests
│   └── ReFSSnapshots.Tests.ps1
├── Examples/                    # Usage examples
│   ├── BasicUsage.ps1
│   └── AdvancedScenarios.ps1
└── Results/                     # Test results output
```

## Contributing

Contributions are welcome! Please ensure:
1. All tests pass
2. New features include tests
3. Follow existing code style
4. Update documentation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## References

- [refsutil streamsnapshot documentation](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/refsutil-streamsnapshot)
- [ReFS Overview](https://learn.microsoft.com/en-us/windows-server/storage/refs/refs-overview)
- [MS-FSCC Protocol Specification](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-fscc/0471b2c6-1006-4ac8-98bd-356a522f1f72)

## Support

For issues, questions, or contributions, please visit the [GitHub repository](https://github.com/microsoft/ReFSSnapshots).
