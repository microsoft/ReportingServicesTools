$repository = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$releaseScript = Join-Path $repository 'build/Invoke-Release.ps1'
$assertScript = Join-Path $repository 'build/Assert-PesterResult.ps1'

Describe 'Tagged release safety (offline)' {
    # Pester 4 does not retain functions declared in BeforeAll for BeforeEach.
    function Invoke-FixtureGit {
        param ([string[]]$Arguments)
        $output = & git -c core.autocrlf=false -c core.safecrlf=false -C $script:checkout @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Fixture git failed: $output" }
        $output
    }

    function Save-FixtureCommit {
        $null = Invoke-FixtureGit -Arguments @('add', '--all')
        $null = Invoke-FixtureGit -Arguments @('-c', 'user.name=Release Test', '-c', 'user.email=release@example.invalid', 'commit', '--quiet', '-m', 'Fixture')
        Invoke-FixtureGit -Arguments @('rev-parse', 'HEAD')
    }

    BeforeEach {
        $script:releaseSetupComplete = $false
        $script:savedEnvironment = @{}
        foreach ($name in @('APPVEYOR_REPO_TAG', 'APPVEYOR_REPO_TAG_NAME', 'APPVEYOR_REPO_COMMIT', 'APPVEYOR_JOB_ID', 'galleryPublishingKey', 'RST_RELEASE_TEST_REPARSE_PATH')) {
            $script:savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
        }
        $env:RST_RELEASE_TEST_REPARSE_PATH = $null
        $env:APPVEYOR_JOB_ID = 'offline-release-job'
        $script:checkout = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:modulePath = Join-Path $script:checkout 'ReportingServicesTools'
        $null = New-Item -Path $script:modulePath -ItemType Directory -Force
        $script:manifestPath = Join-Path $script:modulePath 'ReportingServicesTools.psd1'
        Set-Content -LiteralPath $script:manifestPath -Value "@{ RootModule = 'ReportingServicesTools.psm1'; ModuleVersion = '1.2.3.4'; GUID = '9d139310-ce45-41ce-8e8b-d76335aa1789' }"
        Set-Content -LiteralPath (Join-Path $script:modulePath 'ReportingServicesTools.psm1') -Value '# Fixture module'
        Set-Content -LiteralPath (Join-Path $script:checkout '.gitignore') -Value '*.ignored'
        $null = Invoke-FixtureGit -Arguments @('init', '--quiet')
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '1.2.3.4')
        $env:APPVEYOR_REPO_TAG = 'true'
        $env:APPVEYOR_REPO_TAG_NAME = '1.2.3.4'
        $env:galleryPublishingKey = 'offline-test-key'
        Mock Publish-Module { throw 'Unexpected publish: the default mock must never publish.' }
        Mock Find-Module { throw 'Gallery lookup is forbidden in release regression tests.' }
        Mock Invoke-WebRequest { throw 'Network access is forbidden in release regression tests.' }
        Mock Invoke-RestMethod { throw 'Network access is forbidden in release regression tests.' }
        $script:releaseSetupComplete = $true
    }

    AfterEach {
        try {
            if ($script:releaseSetupComplete) {
                Assert-MockCalled Find-Module -Times 0 -Exactly -Scope It
                Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It
                Assert-MockCalled Invoke-RestMethod -Times 0 -Exactly -Scope It
            }
        }
        finally {
            foreach ($name in $script:savedEnvironment.Keys) {
                [Environment]::SetEnvironmentVariable($name, $script:savedEnvironment[$name])
            }
        }
    }

    It 'validates before tests without publishing or mutating the tagged source' {
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
        (Invoke-FixtureGit -Arguments @('rev-parse', 'HEAD')) | Should -Be $env:APPVEYOR_REPO_COMMIT
        @(Invoke-FixtureGit -Arguments @('status', '--porcelain')).Count | Should -Be 0
        (Import-PowerShellDataFile $script:manifestPath).ModuleVersion | Should -Be '1.2.3.4'
    }

    It 'publishes only the validated package with terminating errors and no source mutation' {
        Mock Publish-Module {}
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        & $releaseScript -Phase Publish -RepositoryPath $script:checkout
        Assert-MockCalled Publish-Module -Times 1 -Exactly -Scope It -ParameterFilter {
            $Path -eq $script:modulePath -and $NuGetApiKey -eq 'offline-test-key' -and
                $PSBoundParameters.ContainsKey('ErrorAction') -and
                $PSBoundParameters['ErrorAction'] -eq [System.Management.Automation.ActionPreference]::Stop
        }
        (Invoke-FixtureGit -Arguments @('rev-parse', 'HEAD')) | Should -Be $env:APPVEYOR_REPO_COMMIT
        @(Invoke-FixtureGit -Arguments @('status', '--porcelain')).Count | Should -Be 0
    }

    It 'skips both phases for non-tag builds, without requiring release metadata or a checkout' {
        $env:APPVEYOR_REPO_TAG = 'false'
        $env:APPVEYOR_REPO_TAG_NAME = ''
        $env:APPVEYOR_REPO_COMMIT = ''
        & $releaseScript -Phase Validate -RepositoryPath (Join-Path $TestDrive 'missing')
        & $releaseScript -Phase Publish -RepositoryPath (Join-Path $TestDrive 'missing')
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects a missing or whitespace job ID and clears stale test inventory: <JobId>' -TestCases @(
        @{ JobId = $null }, @{ JobId = '' }, @{ JobId = '   ' }
    ) {
        param ($JobId)
        $inventoryPath = Join-Path (Join-Path $script:checkout '.git') 'rst-tested-package.json'
        Set-Content -LiteralPath $inventoryPath -Value 'stale inventory'
        $env:APPVEYOR_JOB_ID = $JobId
        { & $releaseScript -Phase Validate -RepositoryPath $script:checkout } | Should -Throw 'APPVEYOR_JOB_ID must be set'
        Test-Path -LiteralPath $inventoryPath | Should -BeFalse
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'APPVEYOR_JOB_ID must be set'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects invalid tag <Tag> before publishing' -TestCases @(
        @{ Tag = '' }, @{ Tag = 'v1.2.3.4' }, @{ Tag = '1.2' },
        @{ Tag = '01.2.3' }, @{ Tag = '0.06.3' }, @{ Tag = '1.2.3-beta' }, @{ Tag = '1.2.3.4.5' },
        @{ Tag = '999999999999.2.3' }, @{ Tag = "1.2.3`n" }
    ) {
        param ($Tag)
        $env:APPVEYOR_REPO_TAG_NAME = $Tag
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'Invalid release tag'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'explains that legacy zero-padded tags are intentionally invalid' {
        $env:APPVEYOR_REPO_TAG_NAME = '0.06.3'
        { & $releaseScript -Phase Validate -RepositoryPath $script:checkout } | Should -Throw 'without leading zeroes'
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'Legacy zero-padded tags such as 0.06.3 are not supported for releases.'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects absent or abbreviated tested commit <Commit>' -TestCases @(
        @{ Commit = '' }, @{ Commit = '123abcd' }, @{ Commit = 'not-a-commit' }
    ) {
        param ($Commit)
        $env:APPVEYOR_REPO_COMMIT = $Commit
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'full tested commit SHA'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects a checkout other than the tested commit' {
        $env:APPVEYOR_REPO_COMMIT = '0123456789012345678901234567890123456789'
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'checkout mismatch'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects a tag pointing at another commit' {
        Set-Content -LiteralPath (Join-Path $script:checkout 'new-source.txt') -Value 'Another commit'
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'not the tested checkout'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects a checkout switch after pre-test validation' {
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        Set-Content -LiteralPath (Join-Path $script:checkout 'other-source.txt') -Value 'Not the tested commit'
        $null = Save-FixtureCommit
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'checkout mismatch'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'fails explicitly on a missing local tag rather than fetching or switching branches' {
        $null = Invoke-FixtureGit -Arguments @('tag', '-d', '1.2.3.4')
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'Release git'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'fails explicitly when the checkout is not a git repository' {
        { & $releaseScript -Phase Publish -RepositoryPath $TestDrive } | Should -Throw 'Release git'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'supports annotated tags on a detached tested checkout' {
        $null = Invoke-FixtureGit -Arguments @('tag', '-d', '1.2.3.4')
        $null = Invoke-FixtureGit -Arguments @('-c', 'user.name=Release Test', '-c', 'user.email=release@example.invalid', 'tag', '-a', '1.2.3.4', '-m', 'Release')
        $null = Invoke-FixtureGit -Arguments @('checkout', '--quiet', '--detach', $env:APPVEYOR_REPO_COMMIT)
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'supports three-component release versions' {
        Set-Content -LiteralPath $script:manifestPath -Value "@{ RootModule = 'ReportingServicesTools.psm1'; ModuleVersion = '1.2.3'; GUID = '9d139310-ce45-41ce-8e8b-d76335aa1789' }"
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '1.2.3')
        $env:APPVEYOR_REPO_TAG_NAME = '1.2.3'
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'fails before tests when the committed version lags the tag, with actionable instructions' {
        $env:APPVEYOR_REPO_TAG_NAME = '1.2.3.5'
        $null = Invoke-FixtureGit -Arguments @('tag', '1.2.3.5')
        { & $releaseScript -Phase Validate -RepositoryPath $script:checkout } | Should -Throw 'commit that ModuleVersion'
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'commit that ModuleVersion'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
        (Import-PowerShellDataFile $script:manifestPath).ModuleVersion | Should -Be '1.2.3.4'
    }

    It 'rejects a missing RootModule file before publishing' {
        Set-Content -LiteralPath $script:manifestPath -Value "@{ RootModule = 'missing.psm1'; ModuleVersion = '1.2.3.4' }"
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        { & $releaseScript -Phase Validate -RepositoryPath $script:checkout } | Should -Throw 'Release RootModule file is missing'
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'Release RootModule file is missing'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects an absent or empty RootModule: <Entry>' -TestCases @(
        @{ Entry = '' }, @{ Entry = "RootModule = '';" }, @{ Entry = "RootModule = '   ';" }
    ) {
        param ($Entry)
        Set-Content -LiteralPath $script:manifestPath -Value "@{ $Entry ModuleVersion = '1.2.3.4' }"
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'Release RootModule must name an existing file'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects RootModule traversal outside the package: <Root>' -TestCases @(
        @{ Root = '../outside.psm1' },
        @{ Root = '..\outside.psm1' },
        @{ Root = '../ReportingServicesTools-other/outside.psm1' },
        @{ Root = 'nested/../../outside.psm1' }
    ) {
        param ($Root)
        $outsideDirectory = Join-Path $script:checkout 'ReportingServicesTools-other'
        $null = New-Item -Path $outsideDirectory -ItemType Directory
        Set-Content -LiteralPath (Join-Path $outsideDirectory 'outside.psm1') -Value '# Outside package'
        Set-Content -LiteralPath (Join-Path $script:checkout 'outside.psm1') -Value '# Outside package'
        Set-Content -LiteralPath $script:manifestPath -Value "@{ RootModule = '$Root'; ModuleVersion = '1.2.3.4' }"
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'resolves outside the module package'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects absolute RootModule paths even if they name an existing package file' {
        $absoluteRoot = Join-Path $script:modulePath 'ReportingServicesTools.psm1'
        Set-Content -LiteralPath $script:manifestPath -Value "@{ RootModule = '$absoluteRoot'; ModuleVersion = '1.2.3.4' }"
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'must be a relative file path'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects a directory as RootModule' {
        $null = New-Item -Path (Join-Path $script:modulePath 'nested') -ItemType Directory
        Set-Content -LiteralPath (Join-Path $script:modulePath 'nested/marker.txt') -Value '# Tracked directory'
        Set-Content -LiteralPath $script:manifestPath -Value "@{ RootModule = 'nested'; ModuleVersion = '1.2.3.4' }"
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'must be a file, not a directory'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'accepts a regular RootModule in a package subdirectory' {
        $null = New-Item -Path (Join-Path $script:modulePath 'nested') -ItemType Directory
        Set-Content -LiteralPath (Join-Path $script:modulePath 'nested/root.psm1') -Value '# Valid nested root'
        Set-Content -LiteralPath $script:manifestPath -Value "@{ RootModule = 'nested/root.psm1'; ModuleVersion = '1.2.3.4'; GUID = '9d139310-ce45-41ce-8e8b-d76335aa1789' }"
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects a RootModule path with a reparse point at <Component>' -TestCases @(
        @{ Component = 'nested' }, @{ Component = 'nested/root.psm1' }
    ) {
        param ($Component)
        $null = New-Item -Path (Join-Path $script:modulePath 'nested') -ItemType Directory
        Set-Content -LiteralPath (Join-Path $script:modulePath 'nested/root.psm1') -Value '# Fixture'
        Set-Content -LiteralPath $script:manifestPath -Value "@{ RootModule = 'nested/root.psm1'; ModuleVersion = '1.2.3.4' }"
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        $env:RST_RELEASE_TEST_REPARSE_PATH = [IO.Path]::GetFullPath((Join-Path $script:modulePath $Component))
        Mock Get-Item { [pscustomobject]@{ Attributes = [IO.FileAttributes]::ReparsePoint } } -ParameterFilter {
            $LiteralPath -eq $env:RST_RELEASE_TEST_REPARSE_PATH
        }
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'symbolic link or junction'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects a non-RootModule package reparse point at <Component>' -TestCases @(
        @{ Component = 'nested' }, @{ Component = 'extra.psm1' }
    ) {
        param ($Component)
        $nested = Join-Path $script:modulePath 'nested'
        $null = New-Item -Path $nested -ItemType Directory
        Set-Content -LiteralPath (Join-Path $nested 'marker.txt') -Value '# Directory content'
        Set-Content -LiteralPath (Join-Path $script:modulePath 'extra.psm1') -Value '# Extra module'
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        $env:RST_RELEASE_TEST_REPARSE_PATH = [IO.Path]::GetFullPath((Join-Path $script:modulePath $Component))
        Mock Get-ChildItem {
            $isDirectory = Test-Path -LiteralPath $env:RST_RELEASE_TEST_REPARSE_PATH -PathType Container
            [pscustomobject]@{
                Name = [IO.Path]::GetFileName($env:RST_RELEASE_TEST_REPARSE_PATH)
                FullName = $env:RST_RELEASE_TEST_REPARSE_PATH
                PSIsContainer = $isDirectory
                Attributes = [IO.FileAttributes]::ReparsePoint
            }
        } -ParameterFilter {
            -not [string]::IsNullOrWhiteSpace($env:RST_RELEASE_TEST_REPARSE_PATH) -and
                [string]::Equals(
                    $LiteralPath,
                    [IO.Path]::GetDirectoryName($env:RST_RELEASE_TEST_REPARSE_PATH),
                    [StringComparison]::OrdinalIgnoreCase
                )
        }
        { & $releaseScript -Phase Validate -RepositoryPath $script:checkout } | Should -Throw 'Release package contains a symbolic link or junction'
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'Release package contains a symbolic link or junction'
        Assert-MockCalled Get-ChildItem -Times 2 -Exactly -Scope It -ParameterFilter {
            -not [string]::IsNullOrWhiteSpace($env:RST_RELEASE_TEST_REPARSE_PATH) -and
                [string]::Equals(
                    $LiteralPath,
                    [IO.Path]::GetDirectoryName($env:RST_RELEASE_TEST_REPARSE_PATH),
                    [StringComparison]::OrdinalIgnoreCase
                )
        }
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'does not block a normal RootModule after reparse mock tests' {
        [string]::IsNullOrEmpty($env:RST_RELEASE_TEST_REPARSE_PATH) | Should -BeTrue
        $null = New-Item -Path (Join-Path $script:modulePath 'nested') -ItemType Directory
        Set-Content -LiteralPath (Join-Path $script:modulePath 'nested/root.psm1') -Value '# Regular root'
        Set-Content -LiteralPath $script:manifestPath -Value "@{ RootModule = 'nested/root.psm1'; ModuleVersion = '1.2.3.4'; GUID = '9d139310-ce45-41ce-8e8b-d76335aa1789' }"
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects hidden package <Kind> before tests because PowerShellGet omits it' -TestCases @(
        @{ Kind = 'file' }, @{ Kind = 'directory' }
    ) {
        param ($Kind)
        if ($Kind -eq 'directory') {
            $hiddenPath = Join-Path $script:modulePath 'hidden-content'
            $null = New-Item -Path $hiddenPath -ItemType Directory
            Set-Content -LiteralPath (Join-Path $hiddenPath 'content.txt') -Value '# Hidden directory content'
            [IO.File]::SetAttributes($hiddenPath, [IO.File]::GetAttributes($hiddenPath) -bor [IO.FileAttributes]::Hidden)
        }
        else {
            $hiddenPath = Join-Path $script:modulePath 'hidden-content.txt'
            Set-Content -LiteralPath $hiddenPath -Value '# Hidden file content'
            [IO.File]::SetAttributes($hiddenPath, [IO.File]::GetAttributes($hiddenPath) -bor [IO.FileAttributes]::Hidden)
        }
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        { & $releaseScript -Phase Validate -RepositoryPath $script:checkout } | Should -Throw 'Hidden files and directories are not supported because PowerShellGet omits them'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects a hidden module package root before tests' {
        $attributes = [IO.File]::GetAttributes($script:modulePath)
        try {
            [IO.File]::SetAttributes($script:modulePath, $attributes -bor [IO.FileAttributes]::Hidden)
            { & $releaseScript -Phase Validate -RepositoryPath $script:checkout } | Should -Throw 'Hidden files and directories are not supported because PowerShellGet omits them'
        }
        finally {
            [IO.File]::SetAttributes($script:modulePath, $attributes)
        }
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects a package file made hidden after pre-test validation before publishing' {
        $file = Join-Path $script:modulePath 'ordinary-content.txt'
        Set-Content -LiteralPath $file -Value '# Regular package file'
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        [IO.File]::SetAttributes($file, [IO.File]::GetAttributes($file) -bor [IO.FileAttributes]::Hidden)
        @(Invoke-FixtureGit -Arguments @('status', '--porcelain', '--untracked-files=no')).Count | Should -Be 0
        @(Invoke-FixtureGit -Arguments @('status', '--porcelain', '--untracked-files=all', '--ignored', '--', 'ReportingServicesTools')).Count | Should -Be 0
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'Hidden files and directories are not supported because PowerShellGet omits them'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'allows a system-only package file through the byte inventory' {
        $file = Join-Path $script:modulePath 'system-content.txt'
        Set-Content -LiteralPath $file -Value '# System attribute alone does not hide this file'
        [IO.File]::SetAttributes($file, [IO.File]::GetAttributes($file) -bor [IO.FileAttributes]::System)
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects invalid manifest metadata even with a valid RootModule file' {
        Set-Content -LiteralPath $script:manifestPath -Value "@{ RootModule = 'ReportingServicesTools.psm1'; ModuleVersion = '1.2.3.4'; GUID = 'not-a-guid' }"
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'GUID'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects prerelease package metadata' {
        Set-Content -LiteralPath $script:manifestPath -Value "@{ ModuleVersion = '1.2.3.4'; PrivateData = @{ PSData = @{ Prerelease = 'beta' } } }"
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'Prerelease metadata'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects a tracked source change made after pre-test validation' {
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        Add-Content -LiteralPath (Join-Path $script:modulePath 'ReportingServicesTools.psm1') -Value '# Changed after tests'
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'source differs'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects a version rewrite after tests rather than publishing the stamped manifest' {
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        Set-Content -LiteralPath $script:manifestPath -Value "@{ ModuleVersion = '1.2.3.5' }"
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'source differs'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects staged changes outside the package as well' {
        Set-Content -LiteralPath (Join-Path $script:checkout 'test.ps1') -Value '# Untested'
        $null = Invoke-FixtureGit -Arguments @('add', 'test.ps1')
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'source differs'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects extra package files including <FileName>' -TestCases @(
        @{ FileName = 'extra.ps1' }, @{ FileName = 'extra.ignored' }
    ) {
        param ($FileName)
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        Set-Content -LiteralPath (Join-Path $script:modulePath $FileName) -Value '# Not in the tested tag'
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'source differs'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'allows generated test results outside the package' {
        Set-Content -LiteralPath (Join-Path $script:checkout 'TestsResults.xml') -Value '<testsuite />'
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'rejects a missing publishing key without attempting a publish' {
        $env:galleryPublishingKey = ''
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'galleryPublishingKey is required'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'propagates a non-terminating publish failure as a terminating error, without committing or retrying' {
        Mock Publish-Module { Write-Error 'Simulated Gallery rejection' }
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'Simulated Gallery rejection'
        Assert-MockCalled Publish-Module -Times 1 -Exactly -Scope It -ParameterFilter {
            $PSBoundParameters.ContainsKey('ErrorAction') -and
                $PSBoundParameters['ErrorAction'] -eq [System.Management.Automation.ActionPreference]::Stop
        }
        (Invoke-FixtureGit -Arguments @('rev-parse', 'HEAD')) | Should -Be $env:APPVEYOR_REPO_COMMIT
        @(Invoke-FixtureGit -Arguments @('status', '--porcelain')).Count | Should -Be 0
    }

    It 'requires a pre-test byte inventory before publishing' {
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'Pre-test release byte inventory is missing'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'binds the byte inventory to the current build job' {
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        $env:APPVEYOR_JOB_ID = 'another-release-job'
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'differ from the pre-test inventory'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'invalidates an earlier inventory if a new pre-test validation fails' {
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        $root = Join-Path $script:modulePath 'ReportingServicesTools.psm1'
        $original = [IO.File]::ReadAllBytes($root)
        Add-Content -LiteralPath $root -Value '# Dirty source'
        { & $releaseScript -Phase Validate -RepositoryPath $script:checkout } | Should -Throw 'source differs'
        [IO.File]::WriteAllBytes($root, $original)
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'Pre-test release byte inventory is missing'
        Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
    }

    It 'checks raw package bytes even when Git normalizes line endings: <Change>' -TestCases @(
        @{ Change = $false }, @{ Change = $true }
    ) {
        param ($Change)
        $rawFile = Join-Path $script:modulePath 'raw.txt'
        [IO.File]::WriteAllText($rawFile, "line1`r`nline2`n")
        # Normalize only this disposable fixture's text file, never the real checkout.
        Set-Content -LiteralPath (Join-Path $script:checkout '.gitattributes') -Value 'ReportingServicesTools/raw.txt text'
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        $null = Invoke-FixtureGit -Arguments @('config', '--local', 'core.autocrlf', 'true')
        $null = Invoke-FixtureGit -Arguments @('config', '--local', 'core.safecrlf', 'false')
        $beforeHash = (Get-FileHash -LiteralPath $rawFile -Algorithm SHA256).Hash
        & $releaseScript -Phase Validate -RepositoryPath $script:checkout
        if ($Change) {
            [IO.File]::WriteAllText($rawFile, "line1`nline2`r`n")
            (Get-FileHash -LiteralPath $rawFile -Algorithm SHA256).Hash | Should -Not -Be $beforeHash
        }
        # Use precisely the production Git checks, without the fixture helper's -c overrides.
        $tracked = @(& git -C $script:checkout status --porcelain --untracked-files=no)
        $LASTEXITCODE | Should -Be 0
        $package = @(& git -C $script:checkout status --porcelain --untracked-files=all --ignored -- ReportingServicesTools)
        $LASTEXITCODE | Should -Be 0
        $tracked.Count | Should -Be 0
        $package.Count | Should -Be 0
        if ($Change) {
            { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'differ from the pre-test inventory'
            Assert-MockCalled Publish-Module -Times 0 -Exactly -Scope It
        }
        else {
            Mock Publish-Module {}
            & $releaseScript -Phase Publish -RepositoryPath $script:checkout
            Assert-MockCalled Publish-Module -Times 1 -Exactly -Scope It
        }
    }

    It 'wires validation before tests and publishes only in the deployment stage' {
        $configuration = Get-Content -LiteralPath (Join-Path $repository 'appveyor.yml') -Raw
        $configuration | Should -Match '(?m)^before_test:\r?\n- ps: \.\\build\\Invoke-Release\.ps1 -Phase Validate\r?\n'
        $configuration | Should -Match '(?m)^deploy_script:\r?\n- ps: \.\\build\\Invoke-Release\.ps1 -Phase Publish\s*\z'
        $configuration.IndexOf('before_test:') | Should -BeLessThan $configuration.IndexOf('test_script:')
        $configuration.IndexOf('test_script:') | Should -BeLessThan $configuration.IndexOf('deploy_script:')
        $configuration | Should -Not -Match 'git checkout|git commit|git push|Publish-Module|Set-Content'
    }

    It 'requires real passing results from the focused and broader test suites' {
        $configuration = Get-Content -LiteralPath (Join-Path $repository 'appveyor.yml') -Raw
        $focused = [regex]::Escape("& .\build\Assert-PesterResult.ps1 -Result `$releaseTests -Name 'Release safety tests' -RequireAllPassed")
        $broader = [regex]::Escape("& .\build\Assert-PesterResult.ps1 -Result `$suiteResults.ToArray() -Name 'Pester suite'")
        $configuration | Should -Match $focused
        $configuration | Should -Match ($broader + '\r?\n')
        $configuration | Should -Not -Match ($broader + ' -RequireAllPassed')
        $configuration | Should -Match 'if \(\$null -eq \$resultsIT\) \{ throw'
        $configuration | Should -Not -Match 'releaseTests\.FailedCount'
        $configuration.IndexOf('-Name ''Release safety tests''') | Should -BeLessThan $configuration.IndexOf('Invoke-ScriptAnalyzer')
    }
}

Describe 'Pester result gate (offline)' {
    function New-PesterResult {
        param ([int]$Passed = 0, [int]$Failed = 0, [int]$Skipped = 0, [int]$Pending = 0, [int]$Inconclusive = 0)
        [pscustomobject]@{
            TotalCount        = $Passed + $Failed + $Skipped + $Pending + $Inconclusive
            PassedCount       = $Passed
            FailedCount       = $Failed
            SkippedCount      = $Skipped
            PendingCount      = $Pending
            InconclusiveCount = $Inconclusive
        }
    }

    It 'accepts a nonempty focused suite where every test passed' {
        { & $assertScript -Result (New-PesterResult -Passed 3) -Name 'Focused' -RequireAllPassed } | Should -Not -Throw
    }

    It 'rejects a focused suite that discovered no tests' {
        { & $assertScript -Result (New-PesterResult) -Name 'Focused' -RequireAllPassed } | Should -Throw 'Focused ran no tests'
    }

    It 'rejects a focused suite whose only test was <Kind>' -TestCases @(
        @{ Kind = 'skipped'; Result = (New-PesterResult -Skipped 1) }
        @{ Kind = 'pending'; Result = (New-PesterResult -Pending 1) }
        @{ Kind = 'inconclusive'; Result = (New-PesterResult -Inconclusive 1) }
    ) {
        param ($Kind, $Result)
        { & $assertScript -Result $Result -Name 'Focused' -RequireAllPassed } | Should -Throw 'Focused did not pass any tests'
    }

    It 'rejects a focused suite with passing and <Kind> tests' -TestCases @(
        @{ Kind = 'skipped'; Result = (New-PesterResult -Passed 2 -Skipped 1) }
        @{ Kind = 'pending'; Result = (New-PesterResult -Passed 2 -Pending 1) }
        @{ Kind = 'inconclusive'; Result = (New-PesterResult -Passed 2 -Inconclusive 1) }
    ) {
        param ($Kind, $Result)
        { & $assertScript -Result $Result -Name 'Focused' -RequireAllPassed } | Should -Throw 'Focused must pass every test'
    }

    It 'rejects a focused suite whose counts do not add up to all passed' {
        $result = New-PesterResult -Passed 2
        $result.TotalCount = 3
        { & $assertScript -Result $result -Name 'Focused' -RequireAllPassed } | Should -Throw 'Focused must pass every test'
    }

    It 'rejects failing results for <Mode>' -TestCases @(
        @{ Mode = 'the focused suite'; Strict = $true }
        @{ Mode = 'the broader suite'; Strict = $false }
    ) {
        param ($Mode, $Strict)
        { & $assertScript -Result (New-PesterResult -Passed 5 -Failed 1) -Name 'Suite' -RequireAllPassed:$Strict } | Should -Throw 'Suite found 1 failed tests'
    }

    It 'rejects a missing or incomplete result' {
        { & $assertScript -Result $null -Name 'Suite' } | Should -Throw 'did not return a Pester result'
        { & $assertScript -Result @() -Name 'Suite' } | Should -Throw 'did not return a Pester result'
        { & $assertScript -Result ([pscustomobject]@{ TotalCount = 1; PassedCount = 1 }) -Name 'Suite' } | Should -Throw 'without FailedCount'
    }

    It 'allows legitimate skips in the broader suite when tests passed' {
        $results = @((New-PesterResult -Passed 4 -Skipped 2), (New-PesterResult -Skipped 3 -Pending 1))
        { & $assertScript -Result $results -Name 'Suite' } | Should -Not -Throw
    }

    It 'rejects a broader suite that ran no tests or passed none' {
        { & $assertScript -Result @((New-PesterResult), (New-PesterResult)) -Name 'Suite' } | Should -Throw 'Suite ran no tests'
        { & $assertScript -Result @((New-PesterResult -Skipped 2), (New-PesterResult -Pending 1)) -Name 'Suite' } | Should -Throw 'Suite did not pass any tests'
    }

    It 'aggregates failures across broader suite files' {
        $results = @((New-PesterResult -Passed 4), (New-PesterResult -Failed 2 -Skipped 1))
        { & $assertScript -Result $results -Name 'Suite' } | Should -Throw 'Suite found 2 failed tests'
    }
}
