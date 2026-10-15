# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Import-Module "$PSScriptRoot\..\..\ReportingServicesTools\ReportingServicesTools.psd1" -Force

InModuleScope ReportingServicesTools {
    # The unit tests do not require SQL Server or a report server installation.
    function Invoke-Sqlcmd
    {
        param ($ServerInstance, $Query, $QueryTimeout, $Username, $Password, $Encrypt,
            [switch]$TrustServerCertificate, $HostNameInCertificate)
    }

    foreach ($commandName in @('Set-RsDatabase', 'Set-RsDatabaseCredentials'))
    {
        Describe "$commandName catalog connection options" {
            BeforeEach {
                $script:methodParameters = @{}
                $script:methodParameters | Add-Member NoteProperty Properties @{
                    Encrypt = $true
                    EncryptMode = $true
                    MultiSubnetFailover = $true
                    TrustServerCertificate = $true
                }
                $script:wmi = [pscustomobject]@{
                    DatabaseName = 'ReportServer'
                    DatabaseServerName = 'SqlListener'
                    DatabaseEncrypt = 'True'
                    DatabaseEncryptMode = 'Strict'
                    DatabaseTrustServerCertificate = $false
                    WindowsServiceIdentityActual = 'DOMAIN\ReportService'
                    Calls = @()
                    Result = 0
                }
                $script:wmi | Add-Member ScriptMethod GetMethodParameters {
                    param ($name)
                    if ($name -ne 'SetDatabaseConnection') { throw 'Unexpected method' }
                    return $script:methodParameters
                }
                $script:wmi | Add-Member ScriptMethod GenerateDatabaseCreationScript {
                    param ($name, $locale, $sharePoint)
                    return @{ HRESULT = 0; Script = 'create database' }
                }
                $script:wmi | Add-Member ScriptMethod GenerateDatabaseRightsScript {
                    param ($user, $name, $remote, $windows)
                    return @{ HRESULT = 0; Script = 'grant rights' }
                }
                $script:wmi | Add-Member ScriptMethod SetDatabaseConnection {
                    $this.Calls += @{ Kind = 'Legacy'; Arguments = $args }
                    return @{ HRESULT = $this.Result }
                }
                $script:wmi | Add-Member ScriptMethod InvokeMethod {
                    param ($name, $parameters, $options)
                    $this.Calls += @{ Kind = 'Named'; Name = $name; Parameters = $parameters }
                    return @{ HRESULT = $this.Result }
                }

                Mock New-RsConfigurationSettingObjectHelper { $script:wmi }
                Mock Get-InstalledModule { $null }
                Mock Invoke-Sqlcmd {}

                $script:arguments = @{
                    DatabaseCredentialType = 'ServiceAccount'
                    Confirm = $false
                }
                if ($commandName -eq 'Set-RsDatabase')
                {
                    $script:arguments['DatabaseServerName'] = 'SqlListener'
                    $script:arguments['Name'] = 'ReportServer'
                }
            }

            It 'Retains the legacy call when runtime options are omitted' {
                & $commandName @script:arguments
                $script:wmi.Calls.Count | Should Be 1
                $script:wmi.Calls[0].Kind | Should Be 'Legacy'
                $script:wmi.Calls[0].Arguments.Count | Should Be 5
                $script:methodParameters.Count | Should Be 0
            }

            It 'Sets Mandatory runtime encryption without requiring SQLServer v22' {
                & $commandName @script:arguments -DatabaseEncryptMode Mandatory
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters['EncryptMode'] | Should Be 'True'
                $script:methodParameters.ContainsKey('MultiSubnetFailover') | Should Be $false
                $script:methodParameters.ContainsKey('TrustServerCertificate') | Should Be $false
                $script:wmi.Calls[0].Kind | Should Be 'Named'
                $script:wmi.Calls[0].Name | Should Be 'SetDatabaseConnection'
                $script:methodParameters['Server'] | Should Be 'SqlListener'
                $script:methodParameters['DatabaseName'] | Should Be 'ReportServer'
                $script:methodParameters['CredentialsType'] | Should Be 2
                $script:methodParameters['UserName'] | Should Be 'DOMAIN\ReportService'
                $script:methodParameters['Password'] | Should Be ''
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It -ParameterFilter {
                    $PSBoundParameters.ContainsKey('Encrypt') -or $PSBoundParameters.ContainsKey('TrustServerCertificate')
                }
            }

            It 'Sets Optional runtime encryption explicitly' {
                & $commandName @script:arguments -DatabaseEncryptMode Optional
                $script:methodParameters['Encrypt'] | Should Be $false
                $script:methodParameters['EncryptMode'] | Should Be 'False'
            }

            It 'Sets Strict runtime encryption and enables multi-subnet failover' {
                & $commandName @script:arguments -DatabaseEncryptMode Strict -DatabaseMultiSubnetFailover
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters['EncryptMode'] | Should Be 'Strict'
                $script:methodParameters['MultiSubnetFailover'] | Should Be $true
            }

            It 'Enables runtime certificate trust without changing setup trust' {
                & $commandName @script:arguments -DatabaseTrustServerCertificate $true
                $script:methodParameters['TrustServerCertificate'] | Should Be $true
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters['EncryptMode'] | Should Be 'Strict'
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It -ParameterFilter {
                    $PSBoundParameters.ContainsKey('TrustServerCertificate')
                }
            }

            It 'Clears runtime certificate trust explicitly' {
                $script:wmi.DatabaseTrustServerCertificate = $true
                & $commandName @script:arguments -DatabaseTrustServerCertificate $false
                $script:methodParameters.ContainsKey('TrustServerCertificate') | Should Be $true
                $script:methodParameters['TrustServerCertificate'] | Should Be $false
            }

            It 'Sets Mandatory encryption, failover, and certificate trust together' {
                & $commandName @script:arguments -DatabaseEncryptMode Mandatory -DatabaseMultiSubnetFailover -DatabaseTrustServerCertificate $true
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters['EncryptMode'] | Should Be 'True'
                $script:methodParameters['MultiSubnetFailover'] | Should Be $true
                $script:methodParameters['TrustServerCertificate'] | Should Be $true
            }

            It 'Preserves Optional encryption when only certificate trust changes' {
                $script:wmi.DatabaseEncrypt = 'False'
                $script:wmi.DatabaseEncryptMode = 'Optional'
                & $commandName @script:arguments -DatabaseTrustServerCertificate $true
                $script:methodParameters['Encrypt'] | Should Be $false
                $script:methodParameters['EncryptMode'] | Should Be 'Optional'
                $script:methodParameters['TrustServerCertificate'] | Should Be $true
            }

            It 'Leaves unbound optional WMI inputs null rather than sending false' {
                $script:methodParameters['MultiSubnetFailover'] = $null
                $script:methodParameters['TrustServerCertificate'] = $null
                & $commandName @script:arguments -DatabaseEncryptMode Mandatory
                ($null -eq $script:methodParameters['MultiSubnetFailover']) | Should Be $true
                ($null -eq $script:methodParameters['TrustServerCertificate']) | Should Be $true
            }

            It 'Preserves runtime certificate trust when other runtime options change' {
                $script:wmi.DatabaseTrustServerCertificate = $true
                & $commandName @script:arguments -DatabaseMultiSubnetFailover
                $script:methodParameters.ContainsKey('TrustServerCertificate') | Should Be $false
                $script:wmi.DatabaseTrustServerCertificate | Should Be $true
            }

            It 'Disables failover explicitly and preserves Strict encryption' {
                & $commandName @script:arguments -DatabaseMultiSubnetFailover:$false
                $script:methodParameters.ContainsKey('MultiSubnetFailover') | Should Be $true
                $script:methodParameters['MultiSubnetFailover'] | Should Be $false
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters['EncryptMode'] | Should Be 'Strict'
            }

            It 'Preserves Optional encryption when only failover changes' {
                $script:wmi.DatabaseEncrypt = 'False'
                $script:wmi.DatabaseEncryptMode = 'Optional'
                & $commandName @script:arguments -DatabaseMultiSubnetFailover
                $script:methodParameters['Encrypt'] | Should Be $false
                $script:methodParameters['EncryptMode'] | Should Be 'Optional'
            }

            It 'Supports Mandatory on providers with only the boolean Encrypt input' {
                $script:methodParameters.Properties.Remove('EncryptMode')
                & $commandName @script:arguments -DatabaseEncryptMode Mandatory
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters.ContainsKey('EncryptMode') | Should Be $false
            }

            It 'Supports Optional on providers with only the boolean Encrypt input' {
                $script:methodParameters.Properties.Remove('EncryptMode')
                & $commandName @script:arguments -DatabaseEncryptMode Optional
                $script:methodParameters['Encrypt'] | Should Be $false
            }

            It 'Rejects Strict on older providers before executing SQL' {
                $script:methodParameters.Properties.Remove('EncryptMode')
                { & $commandName @script:arguments -DatabaseEncryptMode Strict } | Should Throw 'does not support DatabaseEncryptMode Strict'
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It
                $script:wmi.Calls.Count | Should Be 0
            }

            It 'Rejects runtime encryption on providers without Encrypt before executing SQL' {
                $script:methodParameters.Properties.Remove('Encrypt')
                { & $commandName @script:arguments -DatabaseEncryptMode Mandatory } | Should Throw 'does not support runtime database encryption'
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It
            }

            It 'Rejects unsupported failover even when explicitly disabled' {
                $script:methodParameters.Properties.Remove('MultiSubnetFailover')
                { & $commandName @script:arguments -DatabaseMultiSubnetFailover:$false } | Should Throw 'does not support DatabaseMultiSubnetFailover'
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It
                $script:wmi.Calls.Count | Should Be 0
            }

            It 'Rejects runtime trust on providers without TrustServerCertificate before executing SQL' {
                $script:methodParameters.Properties.Remove('TrustServerCertificate')
                { & $commandName @script:arguments -DatabaseTrustServerCertificate $false } | Should Throw 'does not support DatabaseTrustServerCertificate'
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It
                $script:wmi.Calls.Count | Should Be 0
            }

            It 'Rejects enabling runtime trust on providers without TrustServerCertificate' {
                $script:methodParameters.Properties.Remove('TrustServerCertificate')
                { & $commandName @script:arguments -DatabaseTrustServerCertificate $true } | Should Throw 'does not support DatabaseTrustServerCertificate'
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It
                $script:wmi.Calls.Count | Should Be 0
            }

            It 'Supports encryption on older providers when runtime certificate trust is omitted' {
                $script:methodParameters.Properties.Remove('TrustServerCertificate')
                & $commandName @script:arguments -DatabaseEncryptMode Mandatory
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters.ContainsKey('TrustServerCertificate') | Should Be $false
                $script:wmi.Calls[0].Kind | Should Be 'Named'
            }

            It 'Rejects invalid encryption modes before contacting the server' {
                { & $commandName @script:arguments -DatabaseEncryptMode Invalid } | Should Throw
                Assert-MockCalled New-RsConfigurationSettingObjectHelper -Times 0 -Scope It
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It
            }

            It 'Does not contact WMI or SQL for WhatIf' {
                & $commandName @script:arguments -DatabaseEncryptMode Mandatory -DatabaseMultiSubnetFailover -WhatIf
                Assert-MockCalled New-RsConfigurationSettingObjectHelper -Times 0 -Scope It
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It
                $script:wmi.Calls.Count | Should Be 0
            }

            It 'Does not contact WMI or SQL for certificate-trust-only WhatIf' {
                & $commandName @script:arguments -DatabaseTrustServerCertificate $true -WhatIf
                Assert-MockCalled New-RsConfigurationSettingObjectHelper -Times 0 -Scope It
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It
                $script:wmi.Calls.Count | Should Be 0
            }

            It 'Propagates WMI HRESULT failures' {
                $script:wmi.Result = -1
                { & $commandName @script:arguments -DatabaseEncryptMode Mandatory } | Should Throw 'Errorcode: -1'
            }

            It 'Passes SQL runtime credentials only to WMI' {
                $password = ConvertTo-SecureString 'unit-test-password' -AsPlainText -Force
                $script:arguments['DatabaseCredentialType'] = 'SQL'
                $script:arguments['DatabaseCredential'] = New-Object System.Management.Automation.PSCredential('runtimeUser', $password)
                & $commandName @script:arguments -DatabaseEncryptMode Mandatory
                $script:methodParameters['CredentialsType'] | Should Be 1
                $script:methodParameters['UserName'] | Should Be 'runtimeUser'
                $script:methodParameters['Password'] | Should Be 'unit-test-password'
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It -ParameterFilter { $Username -eq 'runtimeUser' }
            }

            It 'Does not treat setup certificate trust as a runtime option' {
                { & $commandName @script:arguments -TrustServerCertificate } | Should Throw 'Consider installing SQLServer module version 22'
                $script:methodParameters.Count | Should Be 0
                $script:wmi.Calls.Count | Should Be 0
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It
            }

            It 'Propagates setup SQL failures without updating runtime configuration' {
                Mock Invoke-Sqlcmd { throw 'SQL setup failed' }
                { & $commandName @script:arguments -DatabaseEncryptMode Mandatory } | Should Throw 'SQL setup failed'
                $script:wmi.Calls.Count | Should Be 0
            }

            It 'Uses runtime options when configuring an existing database' {
                if ($commandName -eq 'Set-RsDatabase')
                {
                    $script:arguments['IsExistingDatabase'] = $true
                }
                & $commandName @script:arguments -DatabaseEncryptMode Mandatory
                Assert-MockCalled Invoke-Sqlcmd -Times 1 -Exactly -Scope It -ParameterFilter { $Query -eq 'grant rights' }
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It -ParameterFilter { $Query -eq 'create database' }
                $script:wmi.Calls[0].Kind | Should Be 'Named'
            }
        }
    }

    Describe 'Database option WMI connection parameter filtering' {
        It 'Forwards only connection parameters to the WMI object factory' {
            Mock New-RsConfigurationSettingObject {}
            $parameters = @{
                ComputerName = 'ReportHost'
                ReportServerInstance = 'PBIRS'
                ReportServerVersion = 'PowerBIReportServer'
                DatabaseEncryptMode = 'Mandatory'
                DatabaseMultiSubnetFailover = $false
                DatabaseTrustServerCertificate = $true
                TrustServerCertificate = $true
            }
            New-RsConfigurationSettingObjectHelper -BoundParameters $parameters
            Assert-MockCalled New-RsConfigurationSettingObject -Times 1 -Exactly -Scope It -ParameterFilter {
                $ComputerName -eq 'ReportHost' -and $ReportServerInstance -eq 'PBIRS' -and
                -not $PSBoundParameters.ContainsKey('DatabaseEncryptMode') -and
                -not $PSBoundParameters.ContainsKey('DatabaseMultiSubnetFailover') -and
                -not $PSBoundParameters.ContainsKey('DatabaseTrustServerCertificate') -and
                -not $PSBoundParameters.ContainsKey('TrustServerCertificate')
            }
        }
    }
}
