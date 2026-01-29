# What's New

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

## Roadmap

Future versions may include:

- **v1.1**: Restore functionality from snapshots
- **v1.2**: Scheduled snapshot automation
- **v1.3**: Snapshot metadata and tagging
- **v2.0**: Native P/Invoke implementation (optional)
- **v2.1**: Remote ReFS volume support
- **v2.2**: Integration with Windows Backup

---

## Changelog Format

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR**: Incompatible API changes
- **MINOR**: Backwards-compatible new features
- **PATCH**: Backwards-compatible bug fixes

---

*Last Updated: January 29, 2026*
