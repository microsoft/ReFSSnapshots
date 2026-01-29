#Requires -Version 5.1

<#
.SYNOPSIS
    ReFSSnapshots PowerShell Module

.DESCRIPTION
    PowerShell module for managing ReFS stream snapshots.
    Wraps refsutil.exe streamsnapshot functionality with proper PowerShell cmdlets.

.NOTES
    Requires Windows Server 2019+ or Windows 10+ with ReFS support
#>

# Get public and private function definition files
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName
