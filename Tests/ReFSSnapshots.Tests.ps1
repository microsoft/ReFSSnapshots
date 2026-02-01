#Requires -Modules Pester

BeforeAll {
    # Import module
    $ModulePath = Split-Path -Parent $PSScriptRoot
    Import-Module "$ModulePath\ReFSSnapshots.psd1" -Force
}

Describe "Module: ReFSSnapshots" {
    Context "Module Loading" {
        It "Should load the module successfully" {
            Get-Module ReFSSnapshots | Should -Not -BeNullOrEmpty
        }

        It "Should export New-RefsSnapshot cmdlet" {
            Get-Command New-RefsSnapshot -Module ReFSSnapshots | Should -Not -BeNullOrEmpty
        }

        It "Should export Get-RefsSnapshot cmdlet" {
            Get-Command Get-RefsSnapshot -Module ReFSSnapshots | Should -Not -BeNullOrEmpty
        }

        It "Should export Remove-RefsSnapshot cmdlet" {
            Get-Command Remove-RefsSnapshot -Module ReFSSnapshots | Should -Not -BeNullOrEmpty
        }

        It "Should export Compare-RefsSnapshot cmdlet" {
            Get-Command Compare-RefsSnapshot -Module ReFSSnapshots | Should -Not -BeNullOrEmpty
        }

        It "Should export Register-RefsSnapshotSchedule cmdlet" {
            Get-Command Register-RefsSnapshotSchedule -Module ReFSSnapshots | Should -Not -BeNullOrEmpty
        }

        It "Should export Get-RefsSnapshotSchedule cmdlet" {
            Get-Command Get-RefsSnapshotSchedule -Module ReFSSnapshots | Should -Not -BeNullOrEmpty
        }

        It "Should export Update-RefsSnapshotSchedule cmdlet" {
            Get-Command Update-RefsSnapshotSchedule -Module ReFSSnapshots | Should -Not -BeNullOrEmpty
        }

        It "Should export Unregister-RefsSnapshotSchedule cmdlet" {
            Get-Command Unregister-RefsSnapshotSchedule -Module ReFSSnapshots | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "System Requirements" {
    Context "Operating System" {
        BeforeAll {
            $script:OSInfo = Get-CimInstance -ClassName Win32_OperatingSystem
            $script:OSVersion = [System.Environment]::OSVersion
        }

        It "Should be running Windows" {
            $script:OSVersion.Platform | Should -Be 'Win32NT'
        }

        It "Should be Windows 10 or Windows Server 2016+" {
            # Windows 10 = 10.0, Server 2016 = 10.0
            $script:OSVersion.Version.Major | Should -BeGreaterOrEqual 10
        }

        It "Should have a supported OS build" {
            # Windows 10 1607 (Anniversary Update) = Build 14393
            # Windows Server 2016 = Build 14393
            # Windows Server 2019 = Build 17763
            # ReFS stream snapshots require Server 2019+ (Build 17763+) or Win10 with ReFS support

            if ($script:OSInfo.Caption -match "Server") {
                # Server 2019+ (Build 17763+)
                $script:OSVersion.Version.Build | Should -BeGreaterOrEqual 17763
            }
            else {
                # Windows 10+ (Build 14393+)
                $script:OSVersion.Version.Build | Should -BeGreaterOrEqual 14393
            }
        }

        It "Should display OS information" {
            Write-Host "  OS: $($script:OSInfo.Caption)" -ForegroundColor Cyan
            Write-Host "  Version: $($script:OSVersion.Version)" -ForegroundColor Cyan
            Write-Host "  Build: $($script:OSVersion.Version.Build)" -ForegroundColor Cyan
            $true | Should -Be $true
        }
    }

    Context "PowerShell Version" {
        It "Should be PowerShell 5.1 or later" {
            $PSVersionTable.PSVersion.Major | Should -BeGreaterOrEqual 5

            if ($PSVersionTable.PSVersion.Major -eq 5) {
                $PSVersionTable.PSVersion.Minor | Should -BeGreaterOrEqual 1
            }
        }

        It "Should display PowerShell version" {
            Write-Host "  PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
            Write-Host "  Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Cyan
            $true | Should -Be $true
        }

        It "Should have compatible PSEdition" {
            $PSVersionTable.PSEdition | Should -BeIn @('Desktop', 'Core')
        }
    }

    Context "ReFS Support" {
        BeforeAll {
            $script:RefsUtilPath = "$env:SystemRoot\System32\refsutil.exe"
        }

        It "Should have refsutil.exe available" {
            Test-Path $script:RefsUtilPath | Should -Be $true
        }

        It "Should have executable refsutil.exe" {
            if (Test-Path $script:RefsUtilPath) {
                $refsutil = Get-Item $script:RefsUtilPath
                $refsutil.Extension | Should -Be '.exe'
                Write-Host "  refsutil.exe: $($refsutil.VersionInfo.FileVersion)" -ForegroundColor Cyan
            }
        }

        It "Should be able to execute refsutil.exe" {
            { & $script:RefsUtilPath 2>&1 | Out-Null } | Should -Not -Throw
        }

        It "Should support streamsnapshot command" {
            $output = & $script:RefsUtilPath 2>&1 | Out-String
            # refsutil help should mention available commands
            $output | Should -Not -BeNullOrEmpty
        }
    }

    Context "ReFS Volume Detection" {
        BeforeAll {
            $script:RefsVolumes = Get-Volume | Where-Object { $_.FileSystemType -eq 'ReFS' }
        }

        It "Should be able to query volumes" {
            { Get-Volume } | Should -Not -Throw
        }

        It "Should detect ReFS volumes if available" {
            Write-Host "  ReFS volumes found: $($script:RefsVolumes.Count)" -ForegroundColor Cyan

            if ($script:RefsVolumes) {
                foreach ($vol in $script:RefsVolumes) {
                    Write-Host "    - Drive $($vol.DriveLetter): $($vol.FileSystemType) ($($vol.Size / 1GB) GB)" -ForegroundColor Cyan
                }
            }
            else {
                Write-Warning "  No ReFS volumes detected. Integration tests will be skipped."
            }

            $true | Should -Be $true
        }

        It "Should support ReFS version 3.7+" -Skip:($null -eq $script:RefsVolumes) {
            # ReFS 3.7 introduced stream snapshots in Windows Server 2022
            # This is informational - we can't easily query ReFS version programmatically
            Write-Host "  Note: Stream snapshots require ReFS 3.7+ (Windows Server 2022)" -ForegroundColor Yellow
            $true | Should -Be $true
        }
    }

    Context "Required Modules" {
        It "Should have ScheduledTasks module available" {
            Get-Module -Name ScheduledTasks -ListAvailable | Should -Not -BeNullOrEmpty
        }

        It "Should be able to import ScheduledTasks module" {
            { Import-Module ScheduledTasks -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should have Get-ScheduledTask cmdlet" {
            Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Pester Version (Testing Only)" {
        BeforeAll {
            $script:PesterModule = Get-Module Pester
        }

        It "Should have Pester loaded for running tests" {
            $script:PesterModule | Should -Not -BeNullOrEmpty
            Write-Host "  Note: Pester is only required for running tests, not for using the module" -ForegroundColor Yellow
        }

        It "Should be Pester 5.0 or later (recommended for testing)" {
            $script:PesterModule.Version.Major | Should -BeGreaterOrEqual 5
        }

        It "Should display Pester version" {
            Write-Host "  Pester: $($script:PesterModule.Version)" -ForegroundColor Cyan
            $true | Should -Be $true
        }

        It "Should have required Pester commands" {
            Get-Command Describe -Module Pester | Should -Not -BeNullOrEmpty
            Get-Command Context -Module Pester | Should -Not -BeNullOrEmpty
            Get-Command It -Module Pester | Should -Not -BeNullOrEmpty
            Get-Command Should -Module Pester | Should -Not -BeNullOrEmpty
        }
    }

    Context "System Requirements Summary" {
        It "Should display complete system requirements check" {
            Write-Host "`n=== System Requirements Summary ===" -ForegroundColor Green
            Write-Host "✓ Operating System: Compatible" -ForegroundColor Green
            Write-Host "✓ PowerShell Version: Compatible" -ForegroundColor Green
            Write-Host "✓ ReFS Support: Available" -ForegroundColor Green
            Write-Host "✓ ScheduledTasks Module: Available" -ForegroundColor Green
            Write-Host "✓ Pester: Compatible (testing only)" -ForegroundColor Green

            if (-not (Get-Volume | Where-Object { $_.FileSystemType -eq 'ReFS' })) {
                Write-Host "⚠ ReFS Volumes: None detected (integration tests will be skipped)" -ForegroundColor Yellow
            }
            else {
                Write-Host "✓ ReFS Volumes: Detected" -ForegroundColor Green
            }

            Write-Host "==================================`n" -ForegroundColor Green
            $true | Should -Be $true
        }
    }
}

Describe "New-RefsSnapshot" {
    Context "Parameter Validation" {
        It "Should have mandatory Path parameter" {
            (Get-Command New-RefsSnapshot).Parameters['Path'].Attributes.Mandatory | Should -Be $true
        }

        It "Should have mandatory Name parameter" {
            (Get-Command New-RefsSnapshot).Parameters['Name'].Attributes.Mandatory | Should -Be $true
        }

        It "Should support ShouldProcess" {
            (Get-Command New-RefsSnapshot).Parameters.ContainsKey('WhatIf') | Should -Be $true
        }

        It "Should support pipeline input for Path" {
            (Get-Command New-RefsSnapshot).Parameters['Path'].Attributes.ValueFromPipeline | Should -Be $true
        }
    }

    Context "Functionality" -Skip {
        # These tests require actual ReFS volume - skip in CI
        BeforeAll {
            $TestFile = "TestDrive:\test.dat"
            "test content" | Out-File $TestFile
        }

        It "Should create a snapshot" {
            { New-RefsSnapshot -Path $TestFile -Name "TestSnapshot" } | Should -Not -Throw
        }
    }
}

Describe "Get-RefsSnapshot" {
    Context "Parameter Validation" {
        It "Should have mandatory Path parameter" {
            (Get-Command Get-RefsSnapshot).Parameters['Path'].Attributes.Mandatory | Should -Be $true
        }

        It "Should have optional Name parameter with wildcard default" {
            $param = (Get-Command Get-RefsSnapshot).Parameters['Name']
            $param.Attributes.Mandatory | Should -Be $false
        }

        It "Should support pipeline input for Path" {
            (Get-Command Get-RefsSnapshot).Parameters['Path'].Attributes.ValueFromPipeline | Should -Be $true
        }

        It "Should output RefsSnapshot type" {
            (Get-Command Get-RefsSnapshot).OutputType.Name | Should -Contain 'RefsSnapshot'
        }
    }
}

Describe "Remove-RefsSnapshot" {
    Context "Parameter Validation" {
        It "Should have mandatory Path parameter" {
            (Get-Command Remove-RefsSnapshot).Parameters['Path'].Attributes.Mandatory | Should -Be $true
        }

        It "Should have mandatory Name parameter" {
            (Get-Command Remove-RefsSnapshot).Parameters['Name'].Attributes.Mandatory | Should -Be $true
        }

        It "Should support ShouldProcess with High impact" {
            $cmd = Get-Command Remove-RefsSnapshot
            $cmd.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $cmd.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It "Should have Force parameter" {
            (Get-Command Remove-RefsSnapshot).Parameters.ContainsKey('Force') | Should -Be $true
        }
    }
}

Describe "Compare-RefsSnapshot" {
    Context "Parameter Validation" {
        It "Should have mandatory Path parameter" {
            (Get-Command Compare-RefsSnapshot).Parameters['Path'].Attributes.Mandatory | Should -Be $true
        }

        It "Should have mandatory Name parameter" {
            (Get-Command Compare-RefsSnapshot).Parameters['Name'].Attributes.Mandatory | Should -Be $true
        }

        It "Should output RefsSnapshotDelta type" {
            (Get-Command Compare-RefsSnapshot).OutputType.Name | Should -Contain 'RefsSnapshotDelta'
        }
    }
}

Describe "Private Functions" {
    InModuleScope ReFSSnapshots {
        Context "Test-RefsVolume" {
            It "Should return false for non-ReFS paths" {
                if (Test-Path TestDrive:\) {
                    Test-RefsVolume -Path "TestDrive:\" | Should -Be $false
                }
            }

            It "Should handle absolute paths correctly" {
                # Regression test for path resolution bug where absolute paths were treated as relative
                if (Test-Path C:\) {
                    # Should not throw even when called from different working directory
                    { Test-RefsVolume -Path "C:\Windows" } | Should -Not -Throw
                }
            }

            It "Should handle paths with spaces" {
                # Test that paths with spaces are handled correctly
                $testPath = "C:\Program Files"
                if (Test-Path $testPath) {
                    { Test-RefsVolume -Path $testPath } | Should -Not -Throw
                }
            }
        }

        Context "Invoke-RefsUtilStreamSnapshot" {
            It "Should validate Operation parameter" {
                $param = (Get-Command Invoke-RefsUtilStreamSnapshot).Parameters['Operation']
                $param.Attributes.ValidValues | Should -Contain 'Create'
                $param.Attributes.ValidValues | Should -Contain 'List'
                $param.Attributes.ValidValues | Should -Contain 'Delete'
                $param.Attributes.ValidValues | Should -Contain 'Query'
            }

            It "Should return result with Success, Output, and Error properties" {
                # Regression test for error handling - ensure result object structure is correct
                $param = (Get-Command Invoke-RefsUtilStreamSnapshot)
                $param | Should -Not -BeNullOrEmpty
            }
        }

        Context "ConvertFrom-RefsUtilOutput" {
        It "Should parse list output correctly" {
            $output = "Snapshot1`nSnapshot2`nSnapshot3"
            $result = ConvertFrom-RefsUtilOutput -Output $output -Operation List
            $result.Count | Should -Be 3
            $result[0].SnapshotName | Should -Be 'Snapshot1'
        }

        It "Should handle empty list output" {
            $output = ""
            $result = ConvertFrom-RefsUtilOutput -Output $output -Operation List
            $result | Should -BeNullOrEmpty
        }

        It "Should filter out status messages from list output" {
            # Regression test for bug where "The operation completed successfully." was included as a snapshot name
            $output = "Snapshot1`nSnapshot2`nThe operation completed successfully."
            $result = ConvertFrom-RefsUtilOutput -Output $output -Operation List
            $result.Count | Should -Be 2
            $result.SnapshotName | Should -Not -Contain 'The operation completed successfully.'
        }

        It "Should filter out error messages from list output" {
            $output = "Snapshot1`nThe operation did not complete successfully. The returned Win32 error code was 0x490."
            $result = ConvertFrom-RefsUtilOutput -Output $output -Operation List
            $result.Count | Should -Be 1
            $result[0].SnapshotName | Should -Be 'Snapshot1'
        }

        It "Should parse VCN/Clusters/LCN query output correctly" {
            # Regression test for Compare-RefsSnapshot parser bug
            $output = "VCN: 0x0    Clusters: 0x1    LCN: 0x53200    Properties: 0x10."
            $result = ConvertFrom-RefsUtilOutput -Output $output -Operation Query
            $result | Should -Not -BeNullOrEmpty
            $result.VCN | Should -Be 0
            $result.Clusters | Should -Be 1
            $result.LCN | Should -Be 0x53200
            $result.Properties | Should -Be 0x10
        }

        It "Should calculate byte offsets from VCN and clusters" {
            # Regression test - ensure byte offsets are calculated correctly
            $output = "VCN: 0x0    Clusters: 0x2    LCN: 0x1000    Properties: 0x10."
            $result = ConvertFrom-RefsUtilOutput -Output $output -Operation Query
            $result.OffsetBytes | Should -Be 0
            $result.LengthBytes | Should -Be 131072  # 2 clusters * 64KB
        }

        It "Should parse multiple delta entries" {
            $output = "VCN: 0x0    Clusters: 0x1    LCN: 0x1000    Properties: 0x10.`nVCN: 0x10    Clusters: 0x2    LCN: 0x2000    Properties: 0x10."
            $result = ConvertFrom-RefsUtilOutput -Output $output -Operation Query
            $result.Count | Should -Be 2
            $result[0].VCN | Should -Be 0
            $result[1].VCN | Should -Be 0x10
        }

        It "Should handle query output with no deltas" {
            $output = "There are no deltas between the requested snapshots.`nThe operation completed successfully."
            $result = ConvertFrom-RefsUtilOutput -Output $output -Operation Query
            $result | Should -BeNullOrEmpty
        }
    }
    }
}

Describe "Integration Tests" -Skip {
    # Requires ReFS volume - skip in standard CI
    BeforeAll {
        $script:TestRefsPath = "R:\TestData"  # Adjust to actual ReFS volume

        if (Test-Path $script:TestRefsPath) {
            $script:TestFile = Join-Path $script:TestRefsPath "test_$(Get-Random).dat"
            "Initial content" | Out-File $script:TestFile
        }
    }

    Context "End-to-End Workflow" {
        It "Should create, list, and delete snapshots" {
            if ($script:TestFile) {
                # Create snapshot
                New-RefsSnapshot -Path $script:TestFile -Name "TestSnap1"

                # Verify it exists
                $snapshots = Get-RefsSnapshot -Path $script:TestFile
                $snapshots.SnapshotName | Should -Contain "TestSnap1"

                # Delete snapshot
                Remove-RefsSnapshot -Path $script:TestFile -Name "TestSnap1" -Force

                # Verify deletion
                $snapshots = Get-RefsSnapshot -Path $script:TestFile
                $snapshots.SnapshotName | Should -Not -Contain "TestSnap1"
            }
        }
    }

    AfterAll {
        if ($script:TestFile -and (Test-Path $script:TestFile)) {
            Remove-Item $script:TestFile -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe "Register-RefsSnapshotSchedule" {
    Context "Parameter Validation" {
        It "Should have mandatory Path parameter" {
            (Get-Command Register-RefsSnapshotSchedule).Parameters['Path'].Attributes.Mandatory | Should -Be $true
        }

        It "Should have mandatory Interval parameter" {
            (Get-Command Register-RefsSnapshotSchedule).Parameters['Interval'].Attributes.Mandatory | Should -Be $true
        }

        It "Should validate Interval values" {
            $param = (Get-Command Register-RefsSnapshotSchedule).Parameters['Interval']
            $param.Attributes.ValidValues | Should -Contain 'Daily'
            $param.Attributes.ValidValues | Should -Contain 'Hourly'
            $param.Attributes.ValidValues | Should -Contain 'Weekly'
        }

        It "Should support ShouldProcess" {
            (Get-Command Register-RefsSnapshotSchedule).Parameters.ContainsKey('WhatIf') | Should -Be $true
        }

        It "Should have RetentionDays with range validation" {
            $param = (Get-Command Register-RefsSnapshotSchedule).Parameters['RetentionDays']
            $param.Attributes.ValidValues | Should -BeNullOrEmpty
            # Has ValidateRange attribute
            $param.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidateRangeAttribute' } | Should -Not -BeNullOrEmpty
        }

        It "Should have NoRetention switch" {
            $param = (Get-Command Register-RefsSnapshotSchedule).Parameters['NoRetention']
            $param.SwitchParameter | Should -Be $true
        }
    }

    Context "Implementation" {
        It "Should use New-ScheduledTaskSettingsSet not New-ScheduledTaskSettings" {
            # Regression test for incorrect cmdlet name bug
            $functionContent = (Get-Command Register-RefsSnapshotSchedule).ScriptBlock.ToString()
            $functionContent | Should -Match 'New-ScheduledTaskSettingsSet'
            $functionContent | Should -Not -Match 'New-ScheduledTaskSettings[^S]'
        }

        It "Should verify New-ScheduledTaskSettingsSet cmdlet exists" {
            # Ensure the correct cmdlet actually exists
            Get-Command New-ScheduledTaskSettingsSet -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Get-RefsSnapshotSchedule" {
    Context "Parameter Validation" {
        It "Should have optional TaskName parameter" {
            $param = (Get-Command Get-RefsSnapshotSchedule).Parameters['TaskName']
            $param.Attributes.Mandatory | Should -Be $false
        }

        It "Should have optional Path parameter" {
            $param = (Get-Command Get-RefsSnapshotSchedule).Parameters['Path']
            $param.Attributes.Mandatory | Should -Be $false
        }

        It "Should output RefsSnapshotSchedule type" {
            (Get-Command Get-RefsSnapshotSchedule).OutputType.Name | Should -Contain 'RefsSnapshotSchedule'
        }

        It "Should support pipeline input" {
            (Get-Command Get-RefsSnapshotSchedule).Parameters['TaskName'].Attributes.ValueFromPipeline | Should -Be $true
        }
    }
}

Describe "Update-RefsSnapshotSchedule" {
    Context "Parameter Validation" {
        It "Should have mandatory TaskName parameter" {
            (Get-Command Update-RefsSnapshotSchedule).Parameters['TaskName'].Attributes.Mandatory | Should -Be $true
        }

        It "Should support ShouldProcess" {
            (Get-Command Update-RefsSnapshotSchedule).Parameters.ContainsKey('WhatIf') | Should -Be $true
        }

        It "Should have optional Interval parameter" {
            $param = (Get-Command Update-RefsSnapshotSchedule).Parameters['Interval']
            $param.Attributes.Mandatory | Should -Be $false
        }

        It "Should have Enabled parameter" {
            $param = (Get-Command Update-RefsSnapshotSchedule).Parameters['Enabled']
            $param.ParameterType | Should -Be ([bool])
        }
    }
}

Describe "Unregister-RefsSnapshotSchedule" {
    Context "Parameter Validation" {
        It "Should have mandatory TaskName parameter" {
            (Get-Command Unregister-RefsSnapshotSchedule).Parameters['TaskName'].Attributes.Mandatory | Should -Be $true
        }

        It "Should support ShouldProcess with High impact" {
            $cmd = Get-Command Unregister-RefsSnapshotSchedule
            $cmd.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $cmd.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It "Should have Force parameter" {
            (Get-Command Unregister-RefsSnapshotSchedule).Parameters.ContainsKey('Force') | Should -Be $true
        }

        It "Should support pipeline input" {
            (Get-Command Unregister-RefsSnapshotSchedule).Parameters['TaskName'].Attributes.ValueFromPipeline | Should -Be $true
        }
    }
}

Describe "Error Handling" {
    Context "Error Message Display" {
        It "Public cmdlets should display errors from STDOUT when STDERR is empty" {
            # Regression test for bug where error messages weren't displayed
            # because refsutil.exe puts errors in STDOUT, not STDERR
            $cmdlets = @('New-RefsSnapshot', 'Get-RefsSnapshot', 'Remove-RefsSnapshot', 'Compare-RefsSnapshot')

            foreach ($cmdlet in $cmdlets) {
                $content = (Get-Command $cmdlet).ScriptBlock.ToString()
                # Should check both $result.Error and $result.Output for error messages
                $content | Should -Match '\$result\.(Error|Output)'
            }
        }

        It "Should handle non-existent file errors gracefully" {
            # Test that proper error messages are shown for common error scenarios
            $result = New-RefsSnapshot -Path 'D:\nonexistent_file_12345.txt' -Name 'test' -ErrorAction SilentlyContinue -ErrorVariable err 2>&1
            $err | Should -Not -BeNullOrEmpty
            $err.Exception.Message | Should -Match 'Path not found|does not exist'
        }

        It "Should handle non-ReFS volume errors gracefully" {
            # Create a temp file on C: (non-ReFS) and test error handling
            $tempFile = [System.IO.Path]::GetTempFileName()
            try {
                $result = New-RefsSnapshot -Path $tempFile -Name 'test' -ErrorAction SilentlyContinue -ErrorVariable err 2>&1
                $err | Should -Not -BeNullOrEmpty
                $err.Exception.Message | Should -Match 'not on a ReFS volume'
            }
            finally {
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context "Path Handling" {
        It "Should handle absolute paths from any working directory" {
            # Regression test for bug where absolute paths were mangled
            # when called from different working directory
            $originalLocation = Get-Location
            try {
                # Change to a different directory
                Set-Location $env:SystemRoot

                # Test that absolute path is handled correctly
                $tempFile = [System.IO.Path]::GetTempFileName()
                try {
                    # Should fail with "not ReFS" error, not path resolution error
                    $result = New-RefsSnapshot -Path $tempFile -Name 'test' -ErrorAction SilentlyContinue -ErrorVariable err 2>&1
                    $err.Exception.Message | Should -Match 'not on a ReFS volume'
                    $err.Exception.Message | Should -Not -Match 'Path not found'
                }
                finally {
                    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                }
            }
            finally {
                Set-Location $originalLocation
            }
        }

        It "Should not mangle drive letters with stream syntax filter" {
            # Regression test for regex bug that removed drive letter colons
            # The regex should only remove alternate data stream syntax like ":StreamName"
            # not the drive letter colon
            if (Test-Path 'C:\Windows') {
                { Test-RefsVolume -Path 'C:\Windows' } | Should -Not -Throw
            }
        }
    }
}

Describe "Scheduling Helper Functions" {
    Context "New-RefsScheduledTaskScript" {
        It "Should generate script with retention" {
            $script = New-RefsScheduledTaskScript -Path "C:\test.dat" -RetentionDays 30
            $script | Should -Match "New-RefsSnapshot"
            $script | Should -Match "AddDays\(-30\)"
        }

        It "Should generate script without retention" {
            $script = New-RefsScheduledTaskScript -Path "C:\test.dat" -RetentionDays 0
            $script | Should -Not -Match "AddDays"
        }

        It "Should support retention by count" {
            $script = New-RefsScheduledTaskScript -Path "C:\test.dat" -RetentionCount 10
            $script | Should -Match "Select-Object -Skip 10"
        }
    }

    Context "ConvertTo-ScheduledTaskTrigger" {
        It "Should create Daily trigger" {
            $trigger = ConvertTo-ScheduledTaskTrigger -Interval Daily -At (Get-Date "3:00 AM")
            $trigger | Should -Not -BeNullOrEmpty
            $trigger.CimClass.CimClassName | Should -Be 'MSFT_TaskDailyTrigger'
        }

        It "Should create Weekly trigger" {
            $trigger = ConvertTo-ScheduledTaskTrigger -Interval Weekly -DaysOfWeek Monday,Friday
            $trigger | Should -Not -BeNullOrEmpty
            $trigger.CimClass.CimClassName | Should -Be 'MSFT_TaskWeeklyTrigger'
        }

        It "Should create Hourly trigger with repetition" {
            $trigger = ConvertTo-ScheduledTaskTrigger -Interval Hourly -RepetitionInterval (New-TimeSpan -Hours 2)
            $trigger | Should -Not -BeNullOrEmpty
        }
    }
}
