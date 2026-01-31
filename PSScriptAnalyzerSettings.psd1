@{
    # PSScriptAnalyzer settings for ReFSSnapshots module

    # Severity levels to include
    Severity = @('Error', 'Warning', 'Information')

    # Include default rules
    IncludeDefaultRules = $true

    # Exclude specific rules if needed
    ExcludeRules = @(
        # Allow Write-Host in example scripts and scheduled task scripts
        # since they're meant for interactive use or logging
    )

    # Custom rule configurations
    Rules = @{
        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $true
            BlockComment = $true
            VSCodeSnippetCorrection = $false
            Placement = 'before'
        }

        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }

        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeForRedundantWhitespace = $false
            CheckSeparator = $true
            CheckParameter = $false
            IgnoreAssignmentOperatorInsideHashTable = $false
        }

        PSAlignAssignmentStatement = @{
            Enable = $true
            CheckHashtable = $true
        }

        PSUseCorrectCasing = @{
            Enable = $true
        }

        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace = @{
            Enable = $true
            NewLineAfter = $false
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore = $false
        }

        PSAvoidUsingCmdletAliases = @{
            Enable = $true
            Allowlist = @()
        }

        PSAvoidUsingPositionalParameters = @{
            Enable = $true
            CommandAllowList = @()
        }
    }
}
