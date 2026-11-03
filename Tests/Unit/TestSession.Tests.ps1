# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

. "$PSScriptRoot\..\Common\Get-RsTestSession.ps1"

Describe 'File-local REST fixture sessions (offline)' {
    BeforeEach {
        Mock New-RsRestSession { New-Object Microsoft.PowerShell.Commands.WebRequestSession }
    }

    It 'creates one session and reuses that exact object for setup, operations and cleanup' {
        $fixture = @{}
        $setup = Get-RsTestSession -Fixture $fixture -ReportPortalUri 'https://server/reports' -Credential $null
        $operation = Get-RsTestSession -Fixture $fixture -ReportPortalUri 'https://server/reports' -Credential $null
        $cleanup = Get-RsTestSession -Fixture $fixture -ReportPortalUri 'https://server/reports' -Credential $null
        [object]::ReferenceEquals($setup, $operation) | Should Be $true
        [object]::ReferenceEquals($setup, $cleanup) | Should Be $true
        Assert-MockCalled New-RsRestSession -Times 1 -Exactly -Scope It -ParameterFilter {
            $ReportPortalUri -eq 'https://server/reports' -and $RestApiVersion -eq 'v2.0' -and
                $null -eq $Credential -and $PSBoundParameters['ErrorAction'] -eq 'Stop'
        }
    }

    It 'does not share sessions between independently owned fixtures even on the same server' {
        $first = Get-RsTestSession -Fixture @{} -ReportPortalUri 'https://server/reports' -Credential $null
        $second = Get-RsTestSession -Fixture @{} -ReportPortalUri 'https://server/reports' -Credential $null
        [object]::ReferenceEquals($first, $second) | Should Be $false
        Assert-MockCalled New-RsRestSession -Times 2 -Exactly -Scope It
    }

    It 'rejects a changed server or API version rather than reusing or silently replacing a session' {
        $fixture = @{}
        $null = Get-RsTestSession -Fixture $fixture -ReportPortalUri 'https://server/reports' -Credential $null
        { Get-RsTestSession -Fixture $fixture -ReportPortalUri 'https://other/reports' -Credential $null } |
            Should Throw 'Use a separate fixture'
        { Get-RsTestSession -Fixture $fixture -ReportPortalUri 'https://server/reports' -RestApiVersion v1.0 -Credential $null } |
            Should Throw 'Use a separate fixture'
        Assert-MockCalled New-RsRestSession -Times 1 -Exactly -Scope It
    }

    It 'isolates explicit credentials including different objects for the same username' {
        $password = ConvertTo-SecureString 'offline-placeholder' -AsPlainText -Force
        $firstCredential = New-Object System.Management.Automation.PSCredential ('fixture-user', $password)
        $secondCredential = New-Object System.Management.Automation.PSCredential ('fixture-user', $password)
        $fixture = @{}
        $first = Get-RsTestSession -Fixture $fixture -ReportPortalUri 'https://server/reports' -Credential $firstCredential
        $again = Get-RsTestSession -Fixture $fixture -ReportPortalUri 'https://server/reports' -Credential $firstCredential
        [object]::ReferenceEquals($first, $again) | Should Be $true
        { Get-RsTestSession -Fixture $fixture -ReportPortalUri 'https://server/reports' -Credential $secondCredential } |
            Should Throw 'Use a separate fixture'
        { Get-RsTestSession -Fixture $fixture -ReportPortalUri 'https://server/reports' -Credential $null } |
            Should Throw 'Use a separate fixture'
        $second = Get-RsTestSession -Fixture @{} -ReportPortalUri 'https://server/reports' -Credential $secondCredential
        [object]::ReferenceEquals($first, $second) | Should Be $false
        Assert-MockCalled New-RsRestSession -Times 2 -Exactly -Scope It
    }

    It 'does not reuse a default-credential session for explicit authentication' {
        $fixture = @{}
        $null = Get-RsTestSession -Fixture $fixture -ReportPortalUri 'https://server/reports' -Credential $null
        $credential = New-Object System.Management.Automation.PSCredential (
            'fixture-user', (ConvertTo-SecureString 'offline-placeholder' -AsPlainText -Force))
        { Get-RsTestSession -Fixture $fixture -ReportPortalUri 'https://server/reports' -Credential $credential } |
            Should Throw 'Use a separate fixture'
        Assert-MockCalled New-RsRestSession -Times 1 -Exactly -Scope It
    }

    It 'allows separate fixtures for different servers and API versions' {
        $first = Get-RsTestSession -Fixture @{} -ReportPortalUri 'https://server/reports' -Credential $null
        $second = Get-RsTestSession -Fixture @{} -ReportPortalUri 'https://other/reports' -RestApiVersion v1.0 -Credential $null
        [object]::ReferenceEquals($first, $second) | Should Be $false
        Assert-MockCalled New-RsRestSession -Times 1 -Exactly -Scope It -ParameterFilter {
            $ReportPortalUri -eq 'https://other/reports' -and $RestApiVersion -eq 'v1.0'
        }
    }

    It 'propagates authentication failure without caching a partial or fallback session' {
        Mock New-RsRestSession { Write-Error 'Simulated authentication failure' }
        $fixture = @{}
        { Get-RsTestSession -Fixture $fixture -ReportPortalUri 'https://server/reports' -Credential $null } |
            Should Throw 'Simulated authentication failure'
        $fixture.Count | Should Be 0
        Assert-MockCalled New-RsRestSession -Times 1 -Exactly -Scope It
    }

    It 'rejects a missing session without caching success' {
        Mock New-RsRestSession {}
        $fixture = @{}
        { Get-RsTestSession -Fixture $fixture -ReportPortalUri 'https://server/reports' -Credential $null } |
            Should Throw 'returned no session'
        $fixture.Count | Should Be 0
    }
}
