@{
    # Script module or binary module file associated with this manifest
    RootModule = 'ReFSSnapshots.psm1'

    # Version number of this module
    ModuleVersion = '1.2.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = 'a7f3e2c1-8d4b-4f9a-b5c6-1e3d7a9f2b4c'

    # Author of this module
    Author = 'Microsoft'

    # Company or vendor of this module
    CompanyName = 'Microsoft Corporation'

    # Copyright statement for this module
    Copyright = '(c) Microsoft Corporation. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'PowerShell module for managing ReFS stream snapshots. Provides cmdlets to create, list, delete, and compare file-level snapshots on ReFS volumes using native Windows capabilities.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()

    # Functions to export from this module
    FunctionsToExport = @(
        'New-RefsSnapshot',
        'Get-RefsSnapshot',
        'Remove-RefsSnapshot',
        'Compare-RefsSnapshot',
        'Restore-RefsSnapshot',
        'Export-RefsSnapshot',
        'Register-RefsSnapshotSchedule',
        'Get-RefsSnapshotSchedule',
        'Update-RefsSnapshotSchedule',
        'Unregister-RefsSnapshotSchedule'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module to aid in module discovery
            Tags = @('ReFS', 'Snapshot', 'Storage', 'Windows', 'FileSystem', 'Backup', 'Automation', 'Schedule')

            # A URL to the license for this module
            LicenseUri = 'https://github.com/microsoft/ReFSSnapshots/blob/main/LICENSE'

            # A URL to the main website for this project
            ProjectUri = 'https://github.com/microsoft/ReFSSnapshots'

            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 1.2.0
- NEW: Snapshot restore functionality
- Restore-RefsSnapshot: Revert files to previous snapshot state
- Safety features: CreateBackup option, PreserveAttributes support
- Atomic file replacement for reliability
- Full pipeline support with PassThru option
- Completes snapshot lifecycle: Create → List → Compare → Restore → Delete

## Version 1.1.0
- NEW: Scheduled snapshot automation via Windows Task Scheduler
- Register-RefsSnapshotSchedule: Create automated snapshot schedules
- Get-RefsSnapshotSchedule: List and query scheduled tasks
- Update-RefsSnapshotSchedule: Modify existing schedules
- Unregister-RefsSnapshotSchedule: Remove scheduled tasks
- Automatic retention policies (default: 30 days)
- Support for Daily, Weekly, Hourly, and custom intervals
- Optional retention by days or snapshot count

## Version 1.0.0
- Initial release
- New-RefsSnapshot: Create stream snapshots
- Get-RefsSnapshot: List snapshots with wildcard support
- Remove-RefsSnapshot: Delete snapshots with confirmation
- Compare-RefsSnapshot: Query changes between snapshot and current state
- Full pipeline support for all cmdlets
- Comprehensive parameter validation
- ReFS volume validation
'@
        }
    }
}
