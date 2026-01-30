function Test-RefsVolume {
    <#
    .SYNOPSIS
        Internal function to validate if a path is on a ReFS volume.

    .DESCRIPTION
        Checks if the specified file path resides on a ReFS-formatted volume.

    .PARAMETER Path
        Path to validate

    .OUTPUTS
        Boolean indicating if path is on ReFS volume
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction Stop
        $drive = Split-Path -Path $resolvedPath.Path -Qualifier

        if ([string]::IsNullOrEmpty($drive)) {
            throw "Cannot determine drive letter for path: $Path"
        }

        $volume = Get-Volume -DriveLetter $drive.TrimEnd(':') -ErrorAction Stop

        if ($volume.FileSystemType -ne 'ReFS') {
            return $false
        }

        return $true
    }
    catch {
        Write-Verbose "Error checking ReFS volume: $_"
        return $false
    }
}
