# Copyright (c) 2017 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = if ($env:PesterPortalUrl -eq $null) { 'http://localhost/reports' } else { $env:PesterPortalUrl }
$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

function New-TestCredentials
{
    param(
        [string]
        $Username,

        [string]
        $Password
    )

    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    return New-Object System.Management.Automation.PSCredential ($Username, $securePassword)
}

function Verify-CredentialsInServer
{
    param(
        [Parameter(Mandatory = $True)]
        [object]
        $CredentialsInServer,

        [Parameter(Mandatory = $True)]
        [string]
        $Username,

        [switch]
        $WindowsCredentials,


        [switch]
        $ImpersonateUser
    )

    $CredentialsInServer | Should Not BeNullOrEmpty
    $CredentialsInServer.Username | Should Be $Username
    $CredentialsInServer.UseAsWindowsCredentials | Should Be $WindowsCredentials
    $CredentialsInServer.ImpersonateAuthenticatedUser | Should Be $ImpersonateUser
}

function Verify-CredentialsByUser
{
    param(
        [Parameter(Mandatory = $True)]
        [object]
        $CredentialsByUser,

        [string]
        $PromptMessage,

        [switch]
        $WindowsCredentials
    )
    Process
    {
        $CredentialsByUser | Should Not BeNullOrEmpty
        $CredentialsByUser.DisplayText | Should Be $PromptMessage
        $CredentialsByUser.UseAsWindowsCredentials | Should Be $WindowsCredentials
    }
}

Describe "Set-RsRestItemDataSource" {
    $session = $null
    $rsFolderPath = ""

    BeforeAll {
        $localPath = (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
    }

    BeforeEach {
        $session = New-RsRestSession -ReportPortalUri $reportPortalUri

        # creating a test folder
        $folderName = 'SUT_GetRsRestItemDataSource_' + [guid]::NewGuid()
        New-RsRestFolder -WebSession $session -RsFolder / -FolderName $folderName
        $rsFolderPath = '/' + $folderName
    }

    AfterEach {
        # deleting test folder
        Remove-RsRestFolder -WebSession $session -RsFolder $rsFolderPath -Confirm:$false
    }

    Context "ReportPortalUri parameter - Paginated Reports" {
        $datasourcesReport = ""

        BeforeEach {
            # uploading datasourceReport.rdl
            Write-RsRestCatalogItem -WebSession $session -Path "$localPath\datasources\datasourcesReport.rdl" -RsFolder $rsFolderPath
            $datasourcesReport =  "$rsFolderPath/datasourcesReport"
        }

        It "Updates datasource connection string" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport

            $datasources[0].ConnectionString = "This is a test connection string"
            $datasources[0].IsConnectionStringOverridden = $true
            Set-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport
            $fetchedDataSources[0].ConnectionString | Should Be "This is a test connection string"
            $fetchedDataSources[0].IsConnectionStringOverridden | Should Be True
        }

        It "Updates datasource credential retrieval to integrated" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Integrated'
            $datasources[0].CredentialsInServer = New-RsRestCredentialsInServerObject -Credential (New-TestCredentials -Username 'dummyUser' -Password 'dummyPassword')
            Set-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Integrated"
        }

        It "Updates datasource credential retrieval to store with SQL creds and NO impersonation" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Store'
            $datasources[0].CredentialsInServer = New-RsRestCredentialsInServerObject -Credential (New-TestCredentials -Username 'dummyUser' -Password 'dummyPassword')
            Set-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Store"
            Verify-CredentialsInServer -CredentialsInServer $fetchedDataSources[0].CredentialsInServer -Username "dummyUser"
        }

        It "Updates datasource credential retrieval to store with Windows creds and NO impersonation" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Store'
            $datasources[0].CredentialsInServer = New-RsRestCredentialsInServerObject -Credential (New-TestCredentials -Username 'dummyUser' -Password 'dummyPassword') -WindowsCredentials
            Set-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Store"
            Verify-CredentialsInServer -CredentialsInServer $fetchedDataSources[0].CredentialsInServer -Username "dummyUser" -WindowsCredentials
        }

        It "Updates datasource credential retrieval to store with SQL creds and impersonation" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Store'
            $datasources[0].CredentialsInServer = New-RsRestCredentialsInServerObject -Credential (New-TestCredentials -Username 'dummyUser' -Password 'dummyPassword') -ImpersonateUser
            Set-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Store"
            Verify-CredentialsInServer -CredentialsInServer $fetchedDataSources[0].CredentialsInServer -Username "dummyUser" -ImpersonateUser
        }

        It "Updates datasource credential retrieval to store with Windows creds and impersonation" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Store'
            $datasources[0].CredentialsInServer = New-RsRestCredentialsInServerObject -Credential (New-TestCredentials -Username 'dummyUser' -Password 'dummyPassword') -WindowsCredentials -ImpersonateUser
            Set-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Store"
            Verify-CredentialsInServer -CredentialsInServer $fetchedDataSources[0].CredentialsInServer -Username "dummyUser" -WindowsCredentials -ImpersonateUser
        }

        It "Updates datasource credential retrieval to prompt with default parameters" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Prompt'
            $datasources[0].CredentialsByUser = New-RsRestCredentialsByUserObject
            Set-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Prompt"
            Verify-CredentialsByUser -CredentialsByUser $fetchedDataSources[0].CredentialsByUser
        }

        It "Updates datasource credential retrieval to prompt with prompt message" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Prompt'
            $datasources[0].CredentialsByUser = New-RsRestCredentialsByUserObject -PromptMessage "This is a prompt message"
            Set-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Prompt"
            Verify-CredentialsByUser -CredentialsByUser $fetchedDataSources[0].CredentialsByUser -PromptMessage "This is a prompt message"
        }

        It "Updates datasource credential retrieval to prompt with prompt message and Windows credentials" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Prompt'
            $datasources[0].CredentialsByUser = New-RsRestCredentialsByUserObject -PromptMessage "This is a prompt message" -WindowsCredentials
            Set-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Prompt"
            Verify-CredentialsByUser -CredentialsByUser $fetchedDataSources[0].CredentialsByUser -PromptMessage "This is a prompt message" -WindowsCredentials
        }

        It "Updates datasource credential retrieval to none" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'None'
            $datasources[0].CredentialsInServer = New-RsRestCredentialsInServerObject -Credential (New-TestCredentials -Username 'dummyUser' -Password 'dummyPassword')
            Set-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "None"
        }
    }

    Context "ReportPortalUri parameter - Power BI Reports" {
        $sqlPowerBIReport = ""

        BeforeEach {
            # uploading SqlPowerBIReport.pbix
            Write-RsRestCatalogItem -WebSession $session -Path "$localPath\SqlPowerBIReport.pbix" -RsFolder $rsFolderPath
            $sqlPowerBIReport = "$rsFolderPath/SqlPowerBIReport"
        }

        It "Updates datasource AuthType to Windows" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport

            $datasources.DataModelDataSource.AuthType = 'Windows'
            $datasources.DataModelDataSource.Username = 'domain\dummyUser'
            $datasources.DataModelDataSource.Secret  = 'dummyUserPassword'
            Set-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport -RsItemType PowerBIReport -Datasources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport
            $fetchedDataSources.DataModelDataSource.AuthType | Should Be 'Windows'
            $fetchedDataSources.DataModelDataSource.Username | Should Be 'domain\dummyUser'
        }

        It "Updates datasource AuthType to UsernamePassword" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport

            $datasources.DataModelDataSource.AuthType = 'UsernamePassword'
            $datasources.DataModelDataSource.Username = 'sqlSA'
            $datasources.DataModelDataSource.Secret  = 'sqlSAPassword'
            Set-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport -RsItemType PowerBIReport -Datasources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport
            $fetchedDataSources.DataModelDataSource.AuthType | Should Be 'UsernamePassword'
            $fetchedDataSources.DataModelDataSource.Username | Should Be 'sqlSA'
        }
    }

    Context "WebSession parameter - Paginated Reports" {
        $datasourcesReport = ""
        $rsSession = $null

        BeforeEach {
            # uploading datasourceReport.rdl
            Write-RsRestCatalogItem -WebSession $session -Path "$localPath\datasources\datasourcesReport.rdl" -RsFolder $rsFolderPath
            $datasourcesReport =  "$rsFolderPath/datasourcesReport"

            $rsSession = New-RsRestSession -ReportPortalUri $reportPortalUri
        }

        It "Updates datasource connection string" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport

            $datasources[0].ConnectionString = "This is a test connection string"
            $datasources[0].IsConnectionStringOverridden = $true
            Set-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport
            $fetchedDataSources[0].ConnectionString | Should Be "This is a test connection string"
            $fetchedDataSources[0].IsConnectionStringOverridden | Should Be True
        }

        It "Updates datasource credential retrieval to integrated" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Integrated'
            $datasources[0].CredentialsInServer = New-RsRestCredentialsInServerObject -Credential (New-TestCredentials -Username 'dummyUser' -Password 'dummyPassword')
            Set-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Integrated"
        }

        It "Updates datasource credential retrieval to store with SQL creds and NO impersonation" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Store'
            $datasources[0].CredentialsInServer = New-RsRestCredentialsInServerObject -Credential (New-TestCredentials -Username 'dummyUser' -Password 'dummyPassword')
            Set-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Store"
            Verify-CredentialsInServer -CredentialsInServer $fetchedDataSources[0].CredentialsInServer -Username "dummyUser"
        }

        It "Updates datasource credential retrieval to store with Windows creds and NO impersonation" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Store'
            $datasources[0].CredentialsInServer = New-RsRestCredentialsInServerObject -Credential (New-TestCredentials -Username 'dummyUser' -Password 'dummyPassword') -WindowsCredentials
            Set-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Store"
            Verify-CredentialsInServer -CredentialsInServer $fetchedDataSources[0].CredentialsInServer -Username "dummyUser" -WindowsCredentials
        }

        It "Updates datasource credential retrieval to store with SQL creds and impersonation" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Store'
            $datasources[0].CredentialsInServer = New-RsRestCredentialsInServerObject -Credential (New-TestCredentials -Username 'dummyUser' -Password 'dummyPassword') -ImpersonateUser
            Set-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Store"
            Verify-CredentialsInServer -CredentialsInServer $fetchedDataSources[0].CredentialsInServer -Username "dummyUser" -ImpersonateUser
        }

        It "Updates datasource credential retrieval to store with Windows creds and impersonation" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Store'
            $datasources[0].CredentialsInServer = New-RsRestCredentialsInServerObject -Credential (New-TestCredentials -Username 'dummyUser' -Password 'dummyPassword') -WindowsCredentials -ImpersonateUser
            Set-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Store"
            Verify-CredentialsInServer -CredentialsInServer $fetchedDataSources[0].CredentialsInServer -Username "dummyUser" -WindowsCredentials -ImpersonateUser
        }

        It "Updates datasource credential retrieval to prompt with default parameters" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Prompt'
            $datasources[0].CredentialsByUser = New-RsRestCredentialsByUserObject
            Set-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Prompt"
            Verify-CredentialsByUser -CredentialsByUser $fetchedDataSources[0].CredentialsByUser
        }

        It "Updates datasource credential retrieval to prompt with prompt message" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Prompt'
            $datasources[0].CredentialsByUser = New-RsRestCredentialsByUserObject -PromptMessage "This is a prompt message"
            Set-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Prompt"
            Verify-CredentialsByUser -CredentialsByUser $fetchedDataSources[0].CredentialsByUser -PromptMessage "This is a prompt message"
        }

        It "Updates datasource credential retrieval to prompt with prompt message and Windows credentials" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'Prompt'
            $datasources[0].CredentialsByUser = New-RsRestCredentialsByUserObject -PromptMessage "This is a prompt message" -WindowsCredentials
            Set-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "Prompt"
            Verify-CredentialsByUser -CredentialsByUser $fetchedDataSources[0].CredentialsByUser -PromptMessage "This is a prompt message" -WindowsCredentials
        }

        It "Updates datasource credential retrieval to none" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport

            $datasources[0].CredentialRetrieval = 'None'
            $datasources[0].CredentialsInServer = New-RsRestCredentialsInServerObject -Credential (New-TestCredentials -Username 'dummyUser' -Password 'dummyPassword')
            Set-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport -RsItemType Report -DataSources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport
            $fetchedDataSources[0].CredentialRetrieval | Should Be "None"
        }
    }

    Context "ReportPortalUri parameter - Power BI Reports" {
        $sqlPowerBIReport = ""

        BeforeEach {
            # uploading SqlPowerBIReport.pbix
            Write-RsRestCatalogItem -WebSession $session -Path "$localPath\SqlPowerBIReport.pbix" -RsFolder $rsFolderPath
            $sqlPowerBIReport = "$rsFolderPath/SqlPowerBIReport"
        }

        It "Updates datasource AuthType to Windows" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $sqlPowerBIReport

            $datasources.DataModelDataSource.AuthType = 'Windows'
            $datasources.DataModelDataSource.Username = 'domain\dummyUser'
            $datasources.DataModelDataSource.Secret  = 'dummyUserPassword'
            Set-RsRestItemDataSource -WebSession $rsSession -RsItem $sqlPowerBIReport -RsItemType PowerBIReport -Datasources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $sqlPowerBIReport
            $fetchedDataSources.DataModelDataSource.AuthType | Should Be 'Windows'
            $fetchedDataSources.DataModelDataSource.Username | Should Be 'domain\dummyUser'
        }

        It "Updates datasource AuthType to UsernamePassword" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $sqlPowerBIReport

            $datasources.DataModelDataSource.AuthType = 'UsernamePassword'
            $datasources.DataModelDataSource.Username = 'sqlSA'
            $datasources.DataModelDataSource.Secret  = 'sqlSAPassword'
            Set-RsRestItemDataSource -WebSession $rsSession -RsItem $sqlPowerBIReport -RsItemType PowerBIReport -Datasources $datasources -Verbose

            $fetchedDataSources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $sqlPowerBIReport
            $fetchedDataSources.DataModelDataSource.AuthType | Should Be 'UsernamePassword'
            $fetchedDataSources.DataModelDataSource.Username | Should Be 'sqlSA'
        }
    }
}