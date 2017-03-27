# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Function Create-PSCredential () 
{
param(
        [Parameter(Mandatory = $True)]
        [string]$User,
        [Parameter(Mandatory = $True)]
        [string]$Password
    )
       $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
       $ps_credential = New-Object System.Management.Automation.PSCredential ($User, $securePassword)
       Return $ps_redential 
}

Function Get-ExistingExtension () 
{
        $proxy = New-RsWebServiceProxy
        return $proxy.ListExtensions("Data")[0].Name
}

Describe "New-RsDataSource" {
    Context "Create RsDataSource with minimun parameters"{
        # Declare datasource Name, Extension, CredentialRetrieval, and DataSource path.
        $dataSourceName = 'SutDataSourceMinParameters' + [guid]::NewGuid()
        $extension = Get-ExistingExtension
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $dataSourcePath
    }

    Context "Create RsDataSource with ReportServerUri parameter"{
        # Declare datasource Name, Extension, CredentialRetrieval, ReportServerUri and DataSource path.
        $dataSourceName = 'SutDataSourceReportServerUriParameter' + [guid]::NewGuid()
        $extension = Get-ExistingExtension
        $credentialRetrieval = 'None'
        $reportServerUri = 'http://localhost/reportserver'
        $dataSourcePath = '/' + $dataSourceName
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -ReportServerUri $reportServerUri
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $dataSourcePath
    }

    Context "Create RsDataSource with Proxy parameter"{
        # Declare datasource Name, Extension, CredentialRetrieval, Proxy and DataSource path.
        $dataSourceName = 'SutDataSourceProxyParameter' + [guid]::NewGuid()
        $extension = Get-ExistingExtension
        $credentialRetrieval = 'None'
        $proxy = New-RsWebServiceProxy 
        $dataSourcePath = '/' + $dataSourceName
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -Proxy $proxy
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $dataSourcePath
    }

    Context "Create RsDataSource with connection string parameter"{
        # Declare datasource Name, Extension, CredentialRetrieval, Connection String and DataSource path.
        $dataSourceName = 'SutDataSourceConnectionStringParameter' + [guid]::NewGuid()
        $extension = Get-ExistingExtension
        $credentialRetrieval = 'None'
        $connectionString =  'Data Source=localhost;Initial Catalog=ReportServer'
        $dataSourcePath = '/' + $dataSourceName
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -ConnectionString $connectionString
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $dataSourcePath
    }

    Context "Create RsDataSource with Proxy and ReportServerUri parameters"{
        # Declare datasource Name, Extension, CredentialRetrieval, and DataSource path.
        $dataSourceName = 'SutDataSourceProxyAndReportServerUriParameters' + [guid]::NewGuid()
        $extension = Get-ExistingExtension
        $credentialRetrieval = 'None'
        $proxy = New-RsWebServiceProxy 
        $dataSourcePath = '/' + $dataSourceName
        $reportServerUri = 'http://localhost/reportserver'
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -Proxy $proxy -ReportServerUri $reportServerUri
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $dataSourcePath
    }

     Context "Unsupported RsDataSource Extension validation"{
        # Declare datasource Name, Extension, CredentialRetrieval, and DataSource path.
        $dataSourceName = 'SutDataSurceExtensionException' + [guid]::NewGuid()
        $extension = 'InvalidExtension'
        $credentialRetrieval = 'Integrated'
        $dataSourcePath = '/' + $dataSourceName
        It "Should throw an exception when datasource is failed to be create" {
             { New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval } | Should throw 
             { Get-RsDataSource -Path $dataSourcePath } | Should throw
        }
    }

    Context "STORE credential validation" {
        # Declare datasource Name, Extension, CredentialRetrieval, and DataSource path.
        $dataSourceName = 'SutDataSurceStoreException' + [guid]::NewGuid()
        $extension = Get-ExistingExtension
        $credentialRetrieval = 'STORE'
        $dataSourcePath = '/' + $dataSourceName
        It "Should throw an exception when Store credential retrieval are given without providing credential" {
            { New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval } | Should throw 
            { Get-RsDataSource -Path $dataSourcePath } | Should throw
        }
    }

    Context "Create RsDataSource with Data Source Credentials" {
        # Declare datasource Name, Extension, CredentialRetrieval, and DataSource path.
        $dataSourceName = 'SutDataSurceCredentials' + [guid]::NewGuid()
        $extension = Get-ExistingExtension
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        # Creation of PSCredentials
        $password ='MyPassword'
        $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $dataSourceCredentials = Create-PSCredential -User $user -Password $password
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -DataSourceCredential $dataSourceCredentials
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $dataSourcePath
    }

    Context "Create RsDataSource with ImpersonateUser Parameter"{
        # Declare datasource Name, Extension, CredentialRetrieval, and DataSource path.
        $dataSourceName = 'SutDataSurceImpersonateUser' + [guid]::NewGuid()
        $extension = Get-ExistingExtension
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -ImpersonateUser
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $dataSourcePath
    }

    Context "Create RsDataSource with Windows Credentials Parameter"{
        # Declare datasource Name, Extension, CredentialRetrieval, and DataSource path.
        $dataSourceName = 'SutDataSurceWindowsCredentials' + [guid]::NewGuid()
        $extension = Get-ExistingExtension
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        # Test if the DataSource is created
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -WindowsCredentials
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $dataSourcePath
    }

    Context "Create RsDataSource with Prompt Credentials Retrieval"{
        # Declare datasource Name, Extension, CredentialRetrieval (Prompt), and DataSource path.
        $dataSourceName = 'SutDataSurcePrompt' + [guid]::NewGuid()
        $extension = Get-ExistingExtension
        $credentialRetrieval = 'Prompt'
        $dataSourcePath = '/' + $dataSourceName
        $prompt = "Please enter your username and password"
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -Prompt $prompt
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $dataSourcePath
    }
}