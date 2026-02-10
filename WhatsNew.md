# What's New

## Version 1.3.0 (February 2026)

Snapshot export functionality - enables archiving snapshots to any storage medium.

### New Features

#### Snapshot Export
- **Export-RefsSnapshot**: Extract snapshots to standalone files
  - Export snapshot data from alternate data streams to primary streams
  - Non-destructive operation preserving original file and snapshot
  - Support for exporting to any volume type (NTFS, FAT32, network shares, etc.)
  - Full `ShouldProcess` support with `ConfirmImpact = 'Medium'`
  - Pipeline support for batch export operations

#### Export Options
- **PreserveAttributes**: Maintain original file metadata during export
  - Preserves creation time from source file
  - Preserves last write time
  - Preserves last access time
  - Useful for maintaining accurate timestamps in archives

- **Force**: Overwrite existing destination files without prompting
  - Bypasses confirmation prompts for automated scenarios
  - Enables scripted backup workflows
  - Compatible with pipeline operations

#### Use Cases
- **Archive snapshots**: Copy snapshots to external storage or network shares
- **Cross-volume backup**: Transfer snapshot data to non-ReFS volumes
- **Offline backup**: Create standalone backup files for archival
- **Analysis**: Export snapshots for comparison or forensic analysis
- **Migration**: Move snapshot data between systems

### Examples
- Export single snapshot to standalone file
- Batch export with pipeline operations
- Archive snapshots to network storage
- Export with preserved file attributes

### Technical Details

**Implementation:** Stream-to-file extraction using .NET I/O
- `Get-Content -Stream` for reading snapshot alternate data stream
- `[System.IO.File]::WriteAllBytes()` for writing primary stream
- Automatic directory creation for destination paths
- Stream path format: `${FilePath}:${SnapshotName}`

**Performance Considerations:**
- Reads entire snapshot into memory before writing
- Performance scales with snapshot size
- Suitable for snapshots up to several GB
- Network storage may impact export speed

### Pipeline Integration
Export integrates seamlessly with existing cmdlets:
```powershell
# Export all snapshots matching a pattern
Get-RefsSnapshot -Path D:\Data\file.dat -Name "Daily_*" |
    ForEach-Object { Export-RefsSnapshot -Path $_.FilePath -Name $_.SnapshotName -Destination "\\nas\backups\$($_.SnapshotName).dat" }
```

### Breaking Changes

None - fully backwards compatible with v1.2.0

---

## Version 1.2.0 (February 2026)

Snapshot restore functionality release - completes the snapshot lifecycle.

### New Features

#### Snapshot Restore
- **Restore-RefsSnapshot**: Revert files to previous snapshot state
  - Full file restoration from ReFS stream snapshots
  - Direct read from snapshot named streams
  - Atomic file replacement for reliability
  - Full `ShouldProcess` support with `ConfirmImpact = 'High'`
  - Pipeline support for batch operations

#### Safety Features
- **CreateBackup**: Automatically create timestamped backup (.bak.yyyyMMddHHmmss) before restoring
  - Preserves current file state before destructive operations
  - Timestamped for easy identification
  - Allows recovery if restore fails or was unintended

- **PreserveAttributes**: Maintain original file metadata after restore
  - Preserves creation time
  - Preserves last write time
  - Preserves file attributes (ReadOnly, Hidden, etc.)
  - Useful for maintaining audit trails

- **PassThru**: Return FileInfo object for restored file
  - Enables further pipeline processing
  - Provides immediate verification of restore operation
  - Compatible with standard PowerShell file cmdlets

#### Reliability
- **Atomic file replacement**: Minimize risk during restore operations
- **Snapshot verification**: Validates snapshot exists before attempting restore
- **ReFS volume validation**: Ensures operation on supported file system
- **Comprehensive error handling**: Clear error messages for common failure scenarios

### Examples
- Updated `BasicUsage.ps1` with restore examples
- New `RestoreScenarios.ps1` demonstrating restore workflows
- Pipeline restore patterns
- Backup and recovery scenarios

### Snapshot Lifecycle (as of v1.2.0)
The module now supports the complete snapshot workflow:
1. **Create** → `New-RefsSnapshot`
2. **List** → `Get-RefsSnapshot`
3. **Compare** → `Compare-RefsSnapshot`
4. **Restore** → `Restore-RefsSnapshot` ✨ NEW in v1.2.0
5. **Delete** → `Remove-RefsSnapshot`

(Export functionality added in v1.3.0)

### Technical Details

**Implementation:** Direct .NET file I/O for snapshot stream access
- `[System.IO.File]::ReadAllBytes()` for snapshot data retrieval
- Temporary file creation for atomic replacement
- Stream path format: `${FilePath}:${SnapshotName}`

**Known Limitations:**
- Loads entire file into memory (may be slow for files >1GB)
- Cannot restore if file is locked by another process
- Atomic replacement has brief gap between delete and rename operations
- Snapshot stream syntax not yet tested for complex stream names

**Performance Considerations:**
- Memory usage proportional to file size
- Full-file restore (not delta-based)
- Future optimization: streaming with buffered reads for large files

### Breaking Changes

None - fully backwards compatible with v1.1.0

---

## Version 1.1.0 (January 2026)

Scheduled snapshot automation feature release.

### New Features

#### Scheduled Snapshot Automation
- **Register-RefsSnapshotSchedule**: Create automated snapshot schedules using Windows Task Scheduler
  - Support for multiple intervals: Daily, Weekly, Hourly, Once, AtStartup, AtLogon
  - Configurable schedule times and repetition
  - Custom task naming
  - Full `ShouldProcess` support

- **Get-RefsSnapshotSchedule**: Query and list scheduled snapshot tasks
  - Filter by task name or file path
  - Returns detailed schedule information including retention policies
  - Pipeline support for management operations

- **Update-RefsSnapshotSchedule**: Modify existing scheduled tasks
  - Change schedule intervals and timing
  - Update retention policies
  - Enable/disable tasks
  - Full `ShouldProcess` support

- **Unregister-RefsSnapshotSchedule**: Remove scheduled tasks
  - Automatic cleanup of associated script files
  - High-impact operation with confirmation
  - Pipeline support for bulk removal

#### Automatic Retention Policies
- **Default 30-day retention**: Automatically delete snapshots older than 30 days
- **Retention by days**: Keep snapshots for specified number of days (0-3650)
- **Retention by count**: Keep last N snapshots (1-1000)
- **Optional no-retention**: Disable automatic cleanup with `-NoRetention` switch
- Retention policies execute automatically with each scheduled snapshot

#### Integration
- Windows Task Scheduler integration for persistent, system-level scheduling
- Scripts stored in `%ProgramData%\ReFSSnapshots\Scripts`
- Tasks run with SYSTEM privileges by default
- Survives system reboots and PowerShell session termination

### Examples
- New `ScheduledSnapshots.ps1` example demonstrating scheduling scenarios
- Multi-tier retention strategies
- Bulk scheduling operations
- Schedule monitoring and reporting

### Technical Details

**Platform Support:** Windows with Task Scheduler (Server 2016+, Windows 10+)

**Dependencies:** ScheduledTasks PowerShell module (included in Windows)

**Task Naming:** Auto-generated as `RefsSnapshot_{filename}_{interval}` or custom

**Script Generation:** Dynamic PowerShell scripts created for each schedule

---

## Version 1.0.0 (January 2026)

Initial release of the ReFSSnapshots PowerShell module.

### Features

#### Cmdlets
- **New-RefsSnapshot**: Create point-in-time snapshots of files and data streams
  - Support for both default ($DATA) and named streams
  - `-PassThru` parameter to return snapshot objects
  - Full `ShouldProcess` support for `-WhatIf` and `-Confirm`

- **Get-RefsSnapshot**: List and query existing snapshots
  - Wildcard pattern matching for snapshot names
  - Pipeline support for bulk operations
  - Returns strongly-typed `RefsSnapshot` objects

- **Remove-RefsSnapshot**: Delete snapshots with safeguards
  - High-impact operation with confirmation prompts
  - `-Force` parameter to suppress confirmations
  - Pipeline support from `Get-RefsSnapshot`

- **Compare-RefsSnapshot**: Track file modifications
  - Query byte-level changes between snapshot and current state
  - Returns `RefsSnapshotDelta` objects with offset and length
  - Supports both default and named streams

#### Infrastructure
- **Pipeline Integration**: All cmdlets support PowerShell pipeline for composable operations
- **Parameter Validation**: Comprehensive input validation and type safety
- **Error Handling**: Detailed error messages with actionable information
- **ReFS Validation**: Automatic volume type checking before operations
- **Verbose Logging**: `-Verbose` support for troubleshooting

#### Testing
- Comprehensive Pester test suite
- Unit tests for all public cmdlets
- Parameter validation tests
- Integration tests for ReFS volumes (skipped in CI)
- Output type validation

#### Documentation
- Complete README with usage examples
- Inline help for all cmdlets
- Basic and advanced example scripts
- Architecture documentation

### Technical Details

**Platform Support:**
- Windows Server 2019, 2022, 2025
- Windows 10, Windows 11
- PowerShell 5.1+ (Desktop and Core)

**Dependencies:**
- Native `refsutil.exe` (included in Windows)
- ReFS volume with version 3.7+

**Known Limitations:**
- Requires Administrator privileges for some operations
- Stream syntax must match refsutil format (`file:stream`)
- No support for remote ReFS volumes
- Snapshot comparison requires snapshots in same chain

### Breaking Changes

N/A - Initial release

---

## Changelog Format

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR**: Incompatible API changes
- **MINOR**: Backwards-compatible new features
- **PATCH**: Backwards-compatible bug fixes

---

*Last Updated: February 10, 2026*
