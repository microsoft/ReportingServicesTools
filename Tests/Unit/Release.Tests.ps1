$repository = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$releaseScript = Join-Path $repository 'build/Invoke-Release.ps1'

Describe 'Tagged release safety (offline)' {
    # Pester 4 does not retain functions declared in BeforeAll for BeforeEach.
    function Invoke-FixtureGit {
        param ([string[]]$Arguments)
        $output = & git -C $script:checkout @Arguments 2>&1
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
        foreach ($name in @('APPVEYOR_REPO_TAG', 'APPVEYOR_REPO_TAG_NAME', 'APPVEYOR_REPO_COMMIT', 'galleryPublishingKey')) {
            $script:savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
        }
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
            $Path -eq $script:modulePath -and $NuGetApiKey -eq 'offline-test-key' -and $ErrorAction -eq 'Stop'
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

    It 'rejects invalid package metadata before publishing' {
        Set-Content -LiteralPath $script:manifestPath -Value "@{ RootModule = 'missing.psm1'; ModuleVersion = '1.2.3.4' }"
        $env:APPVEYOR_REPO_COMMIT = Save-FixtureCommit
        $null = Invoke-FixtureGit -Arguments @('tag', '-f', '1.2.3.4')
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw
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
        { & $releaseScript -Phase Publish -RepositoryPath $script:checkout } | Should -Throw 'Simulated Gallery rejection'
        Assert-MockCalled Publish-Module -Times 1 -Exactly -Scope It -ParameterFilter { $ErrorAction -eq 'Stop' }
        (Invoke-FixtureGit -Arguments @('rev-parse', 'HEAD')) | Should -Be $env:APPVEYOR_REPO_COMMIT
        @(Invoke-FixtureGit -Arguments @('status', '--porcelain')).Count | Should -Be 0
    }

    It 'wires validation before tests and publishes only in the deployment stage' {
        $configuration = Get-Content -LiteralPath (Join-Path $repository 'appveyor.yml') -Raw
        $configuration | Should -Match '(?m)^before_test:\r?\n- ps: \.\\build\\Invoke-Release\.ps1 -Phase Validate\r?\n'
        $configuration | Should -Match '(?m)^deploy_script:\r?\n- ps: \.\\build\\Invoke-Release\.ps1 -Phase Publish\s*\z'
        $configuration.IndexOf('before_test:') | Should -BeLessThan $configuration.IndexOf('test_script:')
        $configuration.IndexOf('test_script:') | Should -BeLessThan $configuration.IndexOf('deploy_script:')
        $configuration | Should -Not -Match 'git checkout|git commit|git push|Publish-Module|Set-Content'
    }
}
