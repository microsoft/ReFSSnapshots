function Invoke-RefsUtilStreamSnapshot {
    <#
    .SYNOPSIS
        Internal wrapper function to invoke refsutil.exe streamsnapshot with proper error handling.

    .DESCRIPTION
        Executes refsutil.exe streamsnapshot with specified arguments and captures output/errors.
        Provides consistent error handling and output parsing.

    .PARAMETER Operation
        Snapshot operation: Create (/c), List (/l), Delete (/d), Query (/q)

    .PARAMETER SnapshotName
        Name of the snapshot to create, delete, query, or list pattern

    .PARAMETER FilePath
        Path to the file (with optional :stream syntax)

    .OUTPUTS
        PSCustomObject with Success, Output, and Error properties
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Create', 'List', 'Delete', 'Query')]
        [string]$Operation,

        [Parameter(Mandatory)]
        [string]$SnapshotName,

        [Parameter(Mandatory)]
        [string]$FilePath
    )

    $refsUtilPath = "$env:SystemRoot\System32\refsutil.exe"

    if (-not (Test-Path $refsUtilPath)) {
        throw "refsutil.exe not found at $refsUtilPath. This tool requires Windows Server 2019+ or Windows 10+"
    }

    # Build arguments array
    $arguments = @('streamsnapshot')

    switch ($Operation) {
        'Create' { $arguments += '/c' }
        'List'   { $arguments += '/l' }
        'Delete' { $arguments += '/d' }
        'Query'  { $arguments += '/q' }
    }

    $arguments += $SnapshotName
    $arguments += $FilePath

    try {
        Write-Verbose "Executing: refsutil.exe $($arguments -join ' ')"

        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $refsUtilPath
        $processInfo.RedirectStandardError = $true
        $processInfo.RedirectStandardOutput = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        $processInfo.Arguments = $arguments -join ' '

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        $process.Start() | Out-Null

        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()

        $process.WaitForExit()
        $exitCode = $process.ExitCode

        Write-Verbose "Exit Code: $exitCode"
        if ($stdout) { Write-Verbose "STDOUT: $stdout" }
        if ($stderr) { Write-Verbose "STDERR: $stderr" }

        return [PSCustomObject]@{
            Success   = ($exitCode -eq 0)
            ExitCode  = $exitCode
            Output    = $stdout
            Error     = $stderr
        }
    }
    catch {
        throw "Failed to execute refsutil.exe streamsnapshot: $_"
    }
}
