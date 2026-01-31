# Contributing to ReFSSnapshots

Thank you for your interest in contributing to ReFSSnapshots! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

This project has adopted a Code of Conduct that we expect all contributors to adhere to. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue on GitHub with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- PowerShell version (`$PSVersionTable`)
- Windows version and ReFS volume information
- Any error messages or screenshots

### Suggesting Enhancements

Feature requests are welcome! Please create an issue with:
- A clear description of the feature
- Use cases and examples
- Any potential implementation ideas

### Pull Requests

1. **Fork the repository** and create a new branch from `main`
   ```powershell
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following our coding standards (see below)

3. **Write or update tests** for your changes
   - All new functions must have Pester tests
   - Existing tests must pass

4. **Update documentation**
   - Add comment-based help to new functions
   - Update README.md if needed
   - Update WhatsNew.md with your changes

5. **Run quality checks locally**
   ```powershell
   # Install required modules
   Install-Module -Name Pester -MinimumVersion 5.0.0 -Force
   Install-Module -Name PSScriptAnalyzer -Force

   # Run PSScriptAnalyzer
   Invoke-ScriptAnalyzer -Path . -Recurse -Settings PSScriptAnalyzerSettings.psd1

   # Run tests
   Invoke-Pester -Path .\Tests
   ```

6. **Commit your changes** with clear, descriptive commit messages
   ```
   Add feature: snapshot comparison with detailed metrics

   - Implemented byte-level delta calculation
   - Added new properties to RefsSnapshotDelta type
   - Updated tests for new functionality
   ```

7. **Push to your fork** and submit a pull request

## Development Setup

### Prerequisites

- Windows 10+ or Windows Server 2019+
- PowerShell 5.1 or later (PowerShell 7+ recommended)
- ReFS-formatted volume for testing
- Git for version control

### Local Setup

1. Clone your fork:
   ```powershell
   git clone https://github.com/YOUR-USERNAME/ReFSSnapshots.git
   cd ReFSSnapshots
   ```

2. Install dependencies:
   ```powershell
   Install-Module -Name Pester -MinimumVersion 5.0.0 -Force
   Install-Module -Name PSScriptAnalyzer -Force
   ```

3. Import the module for testing:
   ```powershell
   Import-Module .\ReFSSnapshots.psd1 -Force
   ```

### Testing Requirements

- **ReFS Volume**: You need a ReFS-formatted volume for integration testing
  ```powershell
  # Check for ReFS volumes
  Get-Volume | Where-Object FileSystemType -eq 'ReFS'
  ```

- **Test Files**: Create test files on your ReFS volume for manual testing
  ```powershell
  # Example test file setup
  $testFile = "R:\test-snapshot.dat"
  Set-Content -Path $testFile -Value "Initial content"
  ```

## Coding Standards

### PowerShell Style Guide

We follow the [PowerShell Practice and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style):

- **Indentation**: 4 spaces (no tabs)
- **Line Length**: Prefer lines under 115 characters
- **Naming**:
  - Functions: `Verb-Noun` format (e.g., `New-RefsSnapshot`)
  - Variables: `$camelCase` or `$PascalCase`
  - Parameters: `PascalCase`
- **Braces**: Opening brace on same line
  ```powershell
  if ($condition) {
      # code
  }
  ```

### Comment-Based Help

All public functions must include complete comment-based help:

```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
        Brief description (one line)

    .DESCRIPTION
        Detailed description of what the function does

    .PARAMETER ParameterName
        Description of the parameter

    .EXAMPLE
        Verb-Noun -ParameterName "value"
        Description of what this example does

    .OUTPUTS
        TypeName
        Description of output
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ParameterName
    )

    # Implementation
}
```

### Error Handling

- Use `[CmdletBinding()]` and proper parameter validation
- Use `Write-Error` for errors, not `throw` (unless terminating)
- Use `Write-Verbose` for detailed operation info
- Use `Write-Warning` for non-critical issues
- Provide clear, actionable error messages

### Testing Standards

- Write Pester tests for all new functions
- Use descriptive test names: `It "Should create snapshot with valid name"`
- Test both success and failure scenarios
- Mock external dependencies when appropriate
- Aim for high code coverage on new code

## Pull Request Process

1. **CI must pass**: All automated checks must pass
   - PSScriptAnalyzer (no errors)
   - Pester tests (all passing)
   - Module manifest validation

2. **Code review**: At least one maintainer must review and approve

3. **Documentation**: All changes must be documented

4. **Changelog**: Update WhatsNew.md with your changes

5. **Merge**: Once approved, a maintainer will merge your PR

## Questions?

If you have questions about contributing, feel free to:
- Open an issue for discussion
- Reach out to the maintainers
- Check existing issues and pull requests for similar topics

## License

By contributing, you agree that your contributions will be licensed under the same [MIT License](LICENSE) that covers this project.

Thank you for contributing to ReFSSnapshots!
