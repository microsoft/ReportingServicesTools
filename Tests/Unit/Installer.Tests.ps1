# Offline only: all installer downloads and module imports are mocked.
$installer = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'Install.ps1'

Describe 'Installer safety (offline)' {
    BeforeAll {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $script:realMove = Get-Command Move-Item -CommandType Cmdlet
        $script:realJoin = Get-Command Join-Path -CommandType Cmdlet
        $script:realGetItem = Get-Command Get-Item -CommandType Cmdlet

        function New-FixtureModule([string]$Directory, [string]$Marker = 'new', [string]$Guid = '9d139310-ce45-41ce-8e8b-d76335aa1789') {
            $null = New-Item -Path $Directory -ItemType Directory -Force
            Set-Content -LiteralPath (Join-Path $Directory 'ReportingServicesTools.psd1') -Value @"
@{
    RootModule = 'ReportingServicesTools.psm1'
    ModuleVersion = '1.0'
    GUID = '$Guid'
}
"@
            Set-Content -LiteralPath (Join-Path $Directory 'ReportingServicesTools.psm1') -Value "# $Marker"
            Set-Content -LiteralPath (Join-Path $Directory 'marker.txt') -Value $Marker
        }

        function New-FixtureArchive([string]$Root = 'ReportingServicesTools-feature-with-slash') {
            $source = Join-Path $script:case 'source'
            New-FixtureModule (Join-Path (Join-Path $source $Root) 'ReportingServicesTools')
            $script:archive = Join-Path $script:case 'fixture.zip'
            [IO.Compression.ZipFile]::CreateFromDirectory($source, $script:archive)
        }

        function Assert-NoInstallerStaging {
            @(Get-ChildItem -LiteralPath $script:case -Recurse -Force |
                Where-Object { $_.Name -like '.rst-install-*' }).Count | Should -Be 0
        }
    }

    BeforeEach {
        $script:case = Join-Path $TestDrive ([guid]::NewGuid().ToString('N').Substring(0, 6))
        $null = New-Item -Path $script:case -ItemType Directory
        $script:destination = Join-Path $script:case 'installation'
        $script:defaultContainer = Join-Path $script:case 'user-modules'
        $script:oldTls = [Net.ServicePointManager]::SecurityProtocol
        $script:archive = $null
        Mock Invoke-WebRequest {
            Copy-Item -LiteralPath $archive -Destination $OutFile -ErrorAction Stop
        }
        Mock Import-Module {}
        Mock Remove-Module {}
        Mock Get-Module { @() }
        Mock Get-Command {}
        Mock Move-Item {
            & $realMove -LiteralPath $LiteralPath -Destination $Destination -ErrorAction Stop
        }
        Mock Get-Item { & $realGetItem -LiteralPath $LiteralPath -Force -ErrorAction Stop }
        # Redirect only the current-user module container; never access the real profile.
        Mock Join-Path {
            if ($ChildPath -eq 'WindowsPowerShell\Modules') { return $defaultContainer }
            & $realJoin -Path $Path -ChildPath $ChildPath
        }
    }

    AfterEach {
        [Net.ServicePointManager]::SecurityProtocol | Should -Be $script:oldTls
    }

    It 'defaults to the current-user module container rather than the script directory' {
        New-FixtureArchive
        $null = & $installer
        Test-Path -LiteralPath (Join-Path $script:defaultContainer 'ReportingServicesTools\marker.txt') | Should -BeTrue
        Assert-MockCalled Import-Module -Times 1 -Exactly -Scope It -ParameterFilter {
            $Global -and $Name -eq (Join-Path $script:defaultContainer 'ReportingServicesTools\ReportingServicesTools.psd1')
        }
        Assert-NoInstallerStaging
    }

    It 'preserves sibling modules in the default container' {
        New-FixtureArchive
        $null = New-Item -Path (Join-Path $script:defaultContainer 'OtherModule') -ItemType Directory -Force
        $null = & $installer
        Test-Path -LiteralPath (Join-Path $script:defaultContainer 'OtherModule') | Should -BeTrue
        Assert-NoInstallerStaging
    }

    It 'supports the downloaded-script entry point without exposing helper functions' {
        New-FixtureArchive
        $null = Invoke-Expression ([IO.File]::ReadAllText($installer))
        Test-Path -LiteralPath (Join-Path $script:defaultContainer 'ReportingServicesTools\marker.txt') | Should -BeTrue
        Test-Path Function:\Read-InstallerManifest | Should -BeFalse
        Test-Path Function:\Assert-InstallerDirectory | Should -BeFalse
        Assert-NoInstallerStaging
    }

    It 'installs synchronously into a fresh explicit container with a slash-containing ref' {
        New-FixtureArchive
        $null = & $installer -Path $script:destination -Version 'feature/safe-install'
        Get-Content -LiteralPath (Join-Path $script:destination 'ReportingServicesTools\marker.txt') | Should -Be 'new'
        Assert-MockCalled Invoke-WebRequest -Times 1 -Exactly -Scope It -ParameterFilter {
            $UseBasicParsing -and $Uri -like '*/feature/safe-install.zip'
        }
        Assert-NoInstallerStaging
    }

    It 'replaces an identified existing module and removes the backup after success' {
        New-FixtureArchive
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old'
        $null = & $installer -Path $script:destination
        Get-Content -LiteralPath (Join-Path $script:destination 'ReportingServicesTools\marker.txt') | Should -Be 'new'
        Assert-NoInstallerStaging
    }

    It 'rejects the checkout before downloading or deleting anything' {
        $checkout = Join-Path $script:case 'checkout'
        $null = New-Item -Path (Join-Path $checkout '.git') -ItemType Directory -Force
        { & $installer -Path $checkout } | Should -Throw 'Unsafe'
        Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It
        Test-Path -LiteralPath (Join-Path $checkout '.git') | Should -BeTrue
    }

    It 'rejects a directory inside a checkout' {
        $checkout = Join-Path $script:case 'checkout'
        $null = New-Item -Path (Join-Path $checkout '.git') -ItemType Directory -Force
        { & $installer -Path (Join-Path $checkout 'child') } | Should -Throw 'Unsafe'
        Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It
    }

    It 'rejects an extracted repository without git metadata' {
        $null = New-Item -Path $script:destination -ItemType Directory
        Set-Content -LiteralPath (Join-Path $script:destination 'Install.ps1') -Value '# checkout'
        { & $installer -Path (Join-Path $script:destination 'nested') } | Should -Throw 'Unsafe'
        Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It
    }

    It 'rejects a reparse-point ancestor before downloading' {
        $null = New-Item -Path $script:destination -ItemType Directory
        Mock Get-Item {
            if ($LiteralPath -eq $destination) {
                return [pscustomobject]@{ PSIsContainer = $true; Attributes = [IO.FileAttributes]::ReparsePoint }
            }
            & $realGetItem -LiteralPath $LiteralPath -Force -ErrorAction Stop
        }
        { & $installer -Path (Join-Path $script:destination 'nested') } | Should -Throw 'Unsafe'
        Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It
    }

    It 'rejects a reparse point inside an existing module without following it' {
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old'
        $script:linkedModulePath = Join-Path $script:destination 'ReportingServicesTools'
        Mock Get-ChildItem {
            [pscustomobject]@{
                FullName = 'linked-content'
                PSIsContainer = $true
                Attributes = [IO.FileAttributes]::ReparsePoint
            }
        } -ParameterFilter { $LiteralPath -eq $linkedModulePath }
        { & $installer -Path $script:destination } | Should -Throw 'symbolic link or junction'
        Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It
        Assert-MockCalled Get-ChildItem -Times 0 -Exactly -Scope It -ParameterFilter { $LiteralPath -eq 'linked-content' }
    }

    It 'rejects broad directories without touching them' {
        foreach ($unsafe in @([IO.Path]::GetPathRoot($TestDrive), $env:USERPROFILE, $env:SystemRoot, [Environment]::GetFolderPath('MyDocuments'))) {
            { & $installer -Path $unsafe } | Should -Throw 'Unsafe'
        }
        Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It
    }

    It 'rejects unrelated content in an explicit container' {
        $null = New-Item -Path $script:destination -ItemType Directory
        Set-Content -LiteralPath (Join-Path $script:destination 'keep.txt') -Value 'keep'
        { & $installer -Path $script:destination } | Should -Throw 'must be empty'
        Get-Content -LiteralPath (Join-Path $script:destination 'keep.txt') | Should -Be 'keep'
        Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It
    }

    It 'rejects an unowned module directory' {
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old' '00000000-0000-0000-0000-000000000000'
        { & $installer -Path $script:destination } | Should -Throw 'Not a ReportingServicesTools'
        Get-Content -LiteralPath (Join-Path $script:destination 'ReportingServicesTools\marker.txt') | Should -Be 'old'
        Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It
    }

    It 'preserves the old installation after a failed download and restores TLS' {
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old'
        Mock Invoke-WebRequest { throw 'offline download failure' }
        { & $installer -Path $script:destination } | Should -Throw 'offline download failure'
        Get-Content -LiteralPath (Join-Path $script:destination 'ReportingServicesTools\marker.txt') | Should -Be 'old'
        Assert-MockCalled Import-Module -Times 0 -Exactly -Scope It
        Assert-NoInstallerStaging
    }

    It 'does not treat a matching GUID as ownership of unrelated module files' {
        New-FixtureArchive
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old'
        $unowned = Join-Path $script:destination 'ReportingServicesTools\personal.txt'
        Set-Content -LiteralPath $unowned -Value 'keep'
        { & $installer -Path $script:destination } | Should -Throw 'content absent from the archive'
        Get-Content -LiteralPath $unowned | Should -Be 'keep'
        Get-Content -LiteralPath (Join-Path $script:destination 'ReportingServicesTools\marker.txt') | Should -Be 'old'
        Assert-MockCalled Move-Item -Times 0 -Exactly -Scope It
        Assert-NoInstallerStaging
    }

    It 'removes its newly created empty container after download failure' {
        Mock Invoke-WebRequest { throw 'offline download failure' }
        { & $installer -Path $script:destination } | Should -Throw 'offline download failure'
        Test-Path -LiteralPath $script:destination | Should -BeFalse
        Assert-NoInstallerStaging
    }

    It 'preserves the old installation after a corrupt archive' {
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old'
        $script:archive = Join-Path $script:case 'corrupt.zip'
        Set-Content -LiteralPath $script:archive -Value 'not a zip'
        { & $installer -Path $script:destination } | Should -Throw
        Get-Content -LiteralPath (Join-Path $script:destination 'ReportingServicesTools\marker.txt') | Should -Be 'old'
        Assert-NoInstallerStaging
    }

    It 'preserves the old installation after invalid downloaded module identity' {
        New-FixtureArchive
        Remove-Item -LiteralPath $script:archive
        $manifest = Join-Path $script:case 'source\ReportingServicesTools-feature-with-slash\ReportingServicesTools\ReportingServicesTools.psd1'
        (Get-Content -LiteralPath $manifest) -replace '9d139310-ce45-41ce-8e8b-d76335aa1789', '00000000-0000-0000-0000-000000000000' |
            Set-Content -LiteralPath $manifest
        [IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $script:case 'source'), $script:archive)
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old'
        { & $installer -Path $script:destination } | Should -Throw 'Not a ReportingServicesTools'
        Get-Content -LiteralPath (Join-Path $script:destination 'ReportingServicesTools\marker.txt') | Should -Be 'old'
        Assert-NoInstallerStaging
    }

    It 'does not execute a downloaded manifest expression' {
        New-FixtureArchive
        Remove-Item -LiteralPath $script:archive
        Set-Content -LiteralPath (Join-Path $script:case 'source\ReportingServicesTools-feature-with-slash\ReportingServicesTools\ReportingServicesTools.psd1') -Value '@{ GUID = $(throw "manifest executed") }'
        [IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $script:case 'source'), $script:archive)
        { & $installer -Path $script:destination } | Should -Throw 'safe'
        Assert-MockCalled Import-Module -Times 0 -Exactly -Scope It
        Assert-NoInstallerStaging
    }

    It 'rejects a manifest pipeline instead of accepting only its first expression' {
        New-FixtureArchive
        Remove-Item -LiteralPath $script:archive
        $manifest = Join-Path $script:case 'source\ReportingServicesTools-feature-with-slash\ReportingServicesTools\ReportingServicesTools.psd1'
        Add-Content -LiteralPath $manifest -Value '| Write-Output'
        [IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $script:case 'source'), $script:archive)
        { & $installer -Path $script:destination } | Should -Throw 'Invalid module manifest'
        Assert-MockCalled Import-Module -Times 0 -Exactly -Scope It
        Assert-NoInstallerStaging
    }

    It 'rejects archives with multiple roots' {
        New-FixtureArchive
        Remove-Item -LiteralPath $script:archive
        Set-Content -LiteralPath (Join-Path $script:case 'source\unexpected.txt') -Value 'unexpected'
        [IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $script:case 'source'), $script:archive)
        { & $installer -Path $script:destination } | Should -Throw 'exactly one'
        Assert-NoInstallerStaging
    }

    It 'rejects archive path traversal before extraction' {
        $script:archive = Join-Path $script:case 'traversal.zip'
        $zip = [IO.Compression.ZipFile]::Open($script:archive, [IO.Compression.ZipArchiveMode]::Create)
        try { $null = $zip.CreateEntry('../escape.txt') } finally { $zip.Dispose() }
        { & $installer -Path $script:destination } | Should -Throw 'Unsafe archive entry'
        Test-Path -LiteralPath (Join-Path $script:case 'escape.txt') | Should -BeFalse
        Assert-NoInstallerStaging
    }

    It 'rejects Windows archive path aliases and invalid roots before extraction' {
        foreach ($entry in @('/root/file', 'root/../escape', 'root\..\escape', 'root./file', 'root /file', 'root//file', 'root/C:/file', 'CON/file')) {
            $script:archive = Join-Path $script:case ([guid]::NewGuid().ToString('N') + '.zip')
            $zip = [IO.Compression.ZipFile]::Open($script:archive, [IO.Compression.ZipArchiveMode]::Create)
            try { $null = $zip.CreateEntry($entry) } finally { $zip.Dispose() }
            { & $installer -Path $script:destination } | Should -Throw 'Unsafe archive entry'
            Assert-NoInstallerStaging
        }
    }

    It 'rejects an empty archive' {
        $script:archive = Join-Path $script:case 'empty.zip'
        $zip = [IO.Compression.ZipFile]::Open($script:archive, [IO.Compression.ZipArchiveMode]::Create)
        $zip.Dispose()
        { & $installer -Path $script:destination } | Should -Throw 'exactly one'
        Assert-NoInstallerStaging
    }

    It 'rolls back when moving the new module fails' {
        New-FixtureArchive
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old'
        Mock Move-Item {
            if ($LiteralPath -like '*\expanded\*') { throw 'replacement move failed' }
            & $realMove -LiteralPath $LiteralPath -Destination $Destination -ErrorAction Stop
        }
        { & $installer -Path $script:destination } | Should -Throw 'replacement move failed'
        Get-Content -LiteralPath (Join-Path $script:destination 'ReportingServicesTools\marker.txt') | Should -Be 'old'
        Assert-NoInstallerStaging
    }

    It 'preserves the old module if moving it to backup fails' {
        New-FixtureArchive
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old'
        Mock Move-Item { throw 'backup move failed' }
        { & $installer -Path $script:destination } | Should -Throw 'backup move failed'
        Get-Content -LiteralPath (Join-Path $script:destination 'ReportingServicesTools\marker.txt') | Should -Be 'old'
        Assert-NoInstallerStaging
    }

    It 'rolls back a move that completes before reporting failure' {
        New-FixtureArchive
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old'
        Mock Move-Item {
            & $realMove -LiteralPath $LiteralPath -Destination $Destination -ErrorAction Stop
            if ($LiteralPath -like '*\expanded\*') { throw 'late move failure' }
        }
        { & $installer -Path $script:destination } | Should -Throw 'late move failure'
        Get-Content -LiteralPath (Join-Path $script:destination 'ReportingServicesTools\marker.txt') | Should -Be 'old'
        Assert-NoInstallerStaging
    }

    It 'restores a backup move that completes before reporting failure' {
        New-FixtureArchive
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old'
        Mock Move-Item {
            & $realMove -LiteralPath $LiteralPath -Destination $Destination -ErrorAction Stop
            if ($Destination -like '*\previous') { throw 'late backup failure' }
        }
        { & $installer -Path $script:destination } | Should -Throw 'late backup failure'
        Get-Content -LiteralPath (Join-Path $script:destination 'ReportingServicesTools\marker.txt') | Should -Be 'old'
        Assert-NoInstallerStaging
    }

    It 'revalidates the installed manifest before importing and rolls back failure' {
        New-FixtureArchive
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old'
        Mock Move-Item {
            & $realMove -LiteralPath $LiteralPath -Destination $Destination -ErrorAction Stop
            if ($LiteralPath -like '*\expanded\*') {
                Set-Content -LiteralPath (Join-Path $Destination 'ReportingServicesTools.psd1') -Value '@{ GUID = "invalid" }'
            }
        }
        { & $installer -Path $script:destination } | Should -Throw 'Not a ReportingServicesTools'
        Get-Content -LiteralPath (Join-Path $script:destination 'ReportingServicesTools\marker.txt') | Should -Be 'old'
        Assert-MockCalled Import-Module -Times 0 -Exactly -Scope It
        Assert-NoInstallerStaging
    }

    It 'retains the backup and reports its location when rollback fails' {
        New-FixtureArchive
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old'
        Mock Move-Item {
            if ($LiteralPath -like '*\expanded\*') { throw 'replacement failed' }
            if ($LiteralPath -like '*\previous') { throw 'restore failed' }
            & $realMove -LiteralPath $LiteralPath -Destination $Destination -ErrorAction Stop
        }
        { & $installer -Path $script:destination } | Should -Throw 'Recovery files retained'
        $stages = @(Get-ChildItem -LiteralPath $script:destination -Force |
            Where-Object { $_.Name -like '.rst-install-*' })
        $stages.Count | Should -Be 1
        Get-Content -LiteralPath (Join-Path $stages[0].FullName 'previous\marker.txt') | Should -Be 'old'
    }

    It 'rolls back an import failure and reloads a previously loaded module' {
        New-FixtureArchive
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old'
        Mock Get-Module { [pscustomobject]@{ Name = 'ReportingServicesTools' } }
        Mock Import-Module {
            if ((Get-Content -LiteralPath (Join-Path $destination 'ReportingServicesTools\marker.txt')) -eq 'new') {
                throw 'new import failed'
            }
        }
        { & $installer -Path $script:destination } | Should -Throw 'new import failed'
        Get-Content -LiteralPath (Join-Path $script:destination 'ReportingServicesTools\marker.txt') | Should -Be 'old'
        Assert-MockCalled Import-Module -Times 2 -Exactly -Scope It
        Assert-NoInstallerStaging
    }

    It 'cleans up a fresh installation when its import fails' {
        New-FixtureArchive
        Mock Import-Module { throw 'fresh import failed' }
        { & $installer -Path $script:destination } | Should -Throw 'fresh import failed'
        Test-Path -LiteralPath $script:destination | Should -BeFalse
        Assert-NoInstallerStaging
    }

    It 'reloads the original loaded module path after rollback' {
        New-FixtureArchive
        New-FixtureModule (Join-Path $script:destination 'ReportingServicesTools') 'old'
        $script:originalPath = Join-Path $script:case 'elsewhere\ReportingServicesTools.psd1'
        Mock Get-Module { [pscustomobject]@{ Name = 'ReportingServicesTools'; Path = $originalPath } }
        Mock Import-Module {
            if ($Name -ne $originalPath) { throw 'new import failed' }
        }
        { & $installer -Path $script:destination } | Should -Throw 'new import failed'
        Assert-MockCalled Import-Module -Times 1 -Exactly -Scope It -ParameterFilter { $Global -and $Name -eq $originalPath }
        Get-Content -LiteralPath (Join-Path $script:destination 'ReportingServicesTools\marker.txt') | Should -Be 'old'
        Assert-NoInstallerStaging
    }
}
