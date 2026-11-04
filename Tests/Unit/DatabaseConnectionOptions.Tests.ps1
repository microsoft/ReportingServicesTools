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

    function Get-RsTestWmiMethodParameters
    {
        # Read local Windows metadata only; never invoke the method or a Report Server setter.
        $processClass = New-Object System.Management.ManagementClass('Win32_Process')
        try
        {
            return $processClass.GetMethodParameters('Create')
        }
        finally
        {
            $processClass.Dispose()
        }
    }

    if (-not ('RsTestFailingPropertyCollection' -as [type]))
    {
        Add-Type -TypeDefinition @'
public class RsTestFailingPropertyCollection
{
    private readonly string failingName;
    private readonly System.Exception error;
    public RsTestFailingPropertyCollection(string failingName, System.Exception error)
    {
        this.failingName = failingName;
        this.error = error;
    }
    public object this[string name]
    {
        get
        {
            if (name == failingName) { throw error; }
            return name;
        }
    }
}
'@
    }

    if (-not ('RsTestWmiPropertyCollectionProxy' -as [type]))
    {
        Add-Type -ReferencedAssemblies System.Management -TypeDefinition @'
public class RsTestWmiPropertyCollectionProxy
{
    private readonly System.Management.PropertyDataCollection inner;
    public RsTestWmiPropertyCollectionProxy(System.Management.PropertyDataCollection inner)
    {
        this.inner = inner;
    }
    public object this[string name]
    {
        get
        {
            if (name == "Encrypt" || name == "EncryptMode") { return name; }
            return inner[name];
        }
    }
}
'@
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

            It 'Preserves Strict encryption when runtime options are omitted' {
                & $commandName @script:arguments
                $script:wmi.Calls.Count | Should Be 1
                $script:wmi.Calls[0].Kind | Should Be 'Named'
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters['EncryptMode'] | Should Be 'Strict'
                $script:methodParameters.ContainsKey('MultiSubnetFailover') | Should Be $false
                $script:methodParameters.ContainsKey('TrustServerCertificate') | Should Be $false
            }

            It 'Preserves Mandatory encryption when runtime options are omitted' {
                $script:wmi.DatabaseEncryptMode = 'Mandatory'
                & $commandName @script:arguments
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters['EncryptMode'] | Should Be 'Mandatory'
            }

            It 'Preserves Optional encryption when runtime options are omitted' {
                $script:wmi.DatabaseEncrypt = 'False'
                $script:wmi.DatabaseEncryptMode = 'Optional'
                & $commandName @script:arguments
                $script:methodParameters['Encrypt'] | Should Be $false
                $script:methodParameters['EncryptMode'] | Should Be 'Optional'
            }

            It 'Preserves boolean encryption on Encrypt-only providers when runtime options are omitted' {
                $script:methodParameters.Properties.Remove('EncryptMode')
                $script:wmi.DatabaseEncrypt = '-1'
                $script:wmi.DatabaseEncryptMode = $null
                & $commandName @script:arguments
                $script:wmi.Calls[0].Kind | Should Be 'Named'
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters.ContainsKey('EncryptMode') | Should Be $false
            }

            It 'Does not resend an unrecognized stored encryption mode' {
                $script:wmi.DatabaseEncryptMode = 'Unexpected'
                & $commandName @script:arguments
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters.ContainsKey('EncryptMode') | Should Be $false
            }

            It 'Retains the legacy call on providers without Encrypt when runtime options are omitted' {
                $script:methodParameters.Properties.Remove('Encrypt')
                & $commandName @script:arguments
                $script:wmi.Calls.Count | Should Be 1
                $script:wmi.Calls[0].Kind | Should Be 'Legacy'
                $script:wmi.Calls[0].Arguments.Count | Should Be 5
                $script:methodParameters.Count | Should Be 0
            }

            It 'Retains the five-argument legacy call when real WMI metadata has no Encrypt' {
                $metadata = Get-RsTestWmiMethodParameters
                try
                {
                    $lookupError = $null
                    try
                    {
                        $null = $metadata.Properties.get_Item('Encrypt')
                    }
                    catch
                    {
                        $lookupError = $_.Exception
                    }
                    ($lookupError -is [System.Management.Automation.MethodInvocationException]) | Should Be $true
                    ($lookupError.InnerException -is [System.Management.ManagementException]) | Should Be $true
                    $lookupError.InnerException.ErrorCode | Should Be ([System.Management.ManagementStatus]::NotFound)
                    $script:methodParameters = $metadata
                    & $commandName @script:arguments
                    $script:wmi.Calls.Count | Should Be 1
                    $script:wmi.Calls[0].Kind | Should Be 'Legacy'
                    $script:wmi.Calls[0].Arguments.Count | Should Be 5
                }
                finally
                {
                    $metadata.Dispose()
                }
            }

            It 'Rejects runtime options for real WMI metadata without Encrypt before SQL or setters' -TestCases @(
                @{ Options = @{ DatabaseEncryptMode = 'Mandatory' } }
                @{ Options = @{ DatabaseMultiSubnetFailover = $false } }
                @{ Options = @{ DatabaseTrustServerCertificate = $false } }
            ) {
                param ($Options)
                $metadata = Get-RsTestWmiMethodParameters
                try
                {
                    $script:methodParameters = $metadata
                    { & $commandName @script:arguments @Options } | Should Throw 'does not support runtime database encryption'
                    Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It
                    $script:wmi.Calls.Count | Should Be 0
                }
                finally
                {
                    $metadata.Dispose()
                }
            }

            It 'Treats real WMI NotFound as an unsupported input before SQL or setters' {
                $metadata = Get-RsTestWmiMethodParameters
                try
                {
                    $properties = [RsTestWmiPropertyCollectionProxy]::new($metadata.Properties)
                    $script:methodParameters.Properties = $properties
                    Test-RsWmiMethodParameter -Parameters $script:methodParameters -Name 'Encrypt' | Should Be $true
                    Test-RsWmiMethodParameter -Parameters $script:methodParameters -Name 'EncryptMode' | Should Be $true
                    $lookupError = $null
                    try
                    {
                        $null = $properties.get_Item('TrustServerCertificate')
                    }
                    catch
                    {
                        $lookupError = $_.Exception
                    }
                    ($lookupError -is [System.Management.Automation.MethodInvocationException]) | Should Be $true
                    ($lookupError.InnerException -is [System.Management.ManagementException]) | Should Be $true
                    $lookupError.InnerException.ErrorCode | Should Be ([System.Management.ManagementStatus]::NotFound)
                    { & $commandName @script:arguments -DatabaseTrustServerCertificate $true } | Should Throw 'does not support DatabaseTrustServerCertificate'
                    Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It
                    $script:wmi.Calls.Count | Should Be 0
                }
                finally
                {
                    $metadata.Dispose()
                }
            }

            It 'Propagates unexpected <Name> lookup failures before SQL or either setter' -TestCases @(
                @{ Name = 'Encrypt'; Options = @{} }
                @{ Name = 'Encrypt'; Options = @{ DatabaseEncryptMode = 'Mandatory' } }
                @{ Name = 'EncryptMode'; Options = @{} }
                @{ Name = 'EncryptMode'; Options = @{ DatabaseEncryptMode = 'Mandatory' } }
                @{ Name = 'MultiSubnetFailover'; Options = @{ DatabaseMultiSubnetFailover = $false } }
                @{ Name = 'TrustServerCertificate'; Options = @{ DatabaseTrustServerCertificate = $false } }
            ) {
                param ($Name, $Options)
                $lookupError = New-Object System.InvalidOperationException('Unexpected metadata lookup failure')
                $script:methodParameters.Properties = [RsTestFailingPropertyCollection]::new($Name, $lookupError)
                $caught = $null
                try
                {
                    & $commandName @script:arguments @Options
                }
                catch
                {
                    $caught = $_.Exception
                }
                $caught | Should Not BeNullOrEmpty
                while ($caught -is [System.Management.Automation.MethodInvocationException])
                {
                    $caught = $caught.InnerException
                }
                [object]::ReferenceEquals($caught, $lookupError) | Should Be $true
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It
                $script:wmi.Calls.Count | Should Be 0
            }

            It 'Does not mistake a ManagementException message for NotFound' {
                $lookupError = New-Object System.Management.ManagementException('Not found')
                $lookupError.ErrorCode | Should Be ([System.Management.ManagementStatus]::Failed)
                $script:methodParameters.Properties = [RsTestFailingPropertyCollection]::new('Encrypt', $lookupError)
                { & $commandName @script:arguments } | Should Throw 'Not found'
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It
                $script:wmi.Calls.Count | Should Be 0
            }

            It 'Propagates disposed WMI property collection failures before SQL or setters' {
                $metadata = Get-RsTestWmiMethodParameters
                try
                {
                    $script:methodParameters.Properties = $metadata.Properties
                }
                finally
                {
                    $metadata.Dispose()
                }
                { & $commandName @script:arguments } | Should Throw
                Assert-MockCalled Invoke-Sqlcmd -Times 0 -Scope It
                $script:wmi.Calls.Count | Should Be 0
            }

            It 'Maps DatabaseEncryptMode True to Mandatory' {
                & $commandName @script:arguments -DatabaseEncryptMode True
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters['EncryptMode'] | Should Be 'True'
            }

            It 'Maps DatabaseEncryptMode False to Optional' {
                & $commandName @script:arguments -DatabaseEncryptMode False
                $script:methodParameters['Encrypt'] | Should Be $false
                $script:methodParameters['EncryptMode'] | Should Be 'False'
            }

            It 'Maps True to boolean Encrypt on Encrypt-only providers' {
                $script:methodParameters.Properties.Remove('EncryptMode')
                & $commandName @script:arguments -DatabaseEncryptMode True
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters.ContainsKey('EncryptMode') | Should Be $false
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

            It 'Preserves WMI minus-one true when only failover changes on an older provider' {
                $script:methodParameters.Properties.Remove('EncryptMode')
                $script:wmi.DatabaseEncrypt = '-1'
                $script:wmi.DatabaseEncryptMode = $null
                & $commandName @script:arguments -DatabaseMultiSubnetFailover:$false
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters['MultiSubnetFailover'] | Should Be $false
            }

            It 'Preserves WMI zero false when only failover changes on an older provider' {
                $script:methodParameters.Properties.Remove('EncryptMode')
                $script:wmi.DatabaseEncrypt = '0'
                $script:wmi.DatabaseEncryptMode = $null
                & $commandName @script:arguments -DatabaseMultiSubnetFailover
                $script:methodParameters['Encrypt'] | Should Be $false
            }

            It 'Preserves WMI minus-one true when only runtime certificate trust changes' {
                $script:wmi.DatabaseEncrypt = '-1'
                $script:wmi.DatabaseEncryptMode = 'True'
                & $commandName @script:arguments -DatabaseTrustServerCertificate $true
                $script:methodParameters['Encrypt'] | Should Be $true
                $script:methodParameters['EncryptMode'] | Should Be 'True'
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
                $script:methodParameters.ContainsKey('TrustServerCertificate') | Should Be $false
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
