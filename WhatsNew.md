# What's New

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

*Last Updated: January 29, 2026*
