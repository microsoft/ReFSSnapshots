<#
.SYNOPSIS
    Basic usage examples for ReFSSnapshots module

.DESCRIPTION
    Demonstrates common workflows for managing ReFS stream snapshots
#>

# Import the module
Import-Module ReFSSnapshots

# Example 1: Create a snapshot before making changes
$file = "D:\Data\database.dat"  # Must be on ReFS volume
New-RefsSnapshot -Path $file -Name "BeforeUpdate_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Example 2: List all snapshots for a file
Get-RefsSnapshot -Path $file

# Example 3: List snapshots matching a pattern
Get-RefsSnapshot -Path $file -Name "BeforeUpdate_*"

# Example 4: Compare snapshot with current state
Compare-RefsSnapshot -Path $file -Name "BeforeUpdate_20240129_120000"

# Example 5: Delete old snapshots
Get-RefsSnapshot -Path $file -Name "BeforeUpdate_2023*" |
    Remove-RefsSnapshot -Force

# Example 6: Pipeline processing multiple files
Get-ChildItem D:\Data\*.dat | ForEach-Object {
    New-RefsSnapshot -Path $_.FullName -Name "DailyBackup_$(Get-Date -Format 'yyyyMMdd')"
}

# Example 7: Working with named streams
$fileWithStream = "D:\Data\file.txt:CustomStream"
New-RefsSnapshot -Path $fileWithStream -Name "StreamBackup"
Get-RefsSnapshot -Path $fileWithStream
