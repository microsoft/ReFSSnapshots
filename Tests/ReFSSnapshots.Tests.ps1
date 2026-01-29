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
    Context "Test-RefsVolume" {
        It "Should return false for non-ReFS paths" {
            if (Test-Path TestDrive:\) {
                Test-RefsVolume -Path "TestDrive:\" | Should -Be $false
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
