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

Describe "New-RsDataSource" {
    Context "Create RsDataSource with minimun parameters (Extension is SQL and Credential retierval is None)"{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSourceMinParameters' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        # Test if the DataSource can be created
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }

    Context "Create RsDataSource with ReportServerUri parameter "{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSourceReportServerUriParameter' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        $reportServerUri = 'http://localhost/reportserver'
        $dataSourcePath = '/' + $dataSourceName
        # Test if the DataSource can be created
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -ReportServerUri $reportServerUri
        # Test if the data source has the specified name and path
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }

    Context "Create RsDataSource with Proxy parameter "{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSourceProxyParameter' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        $proxy = New-RsWebServiceProxy 
        $dataSourcePath = '/' + $dataSourceName
        # Test if the DataSource can be created
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -Proxy $proxy
        # Test if the data source has the specified name and path
        $dataSourceList =  Get-RsDataSource -Path $dataSourcePath 
        $dataSourceCount = $dataSourceList.Count
        It "Should be a new data source" {
            $dataSourceCount | Should Be 1
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }

    Context "Create DataSource with connection string parameter "{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSourceConnectionStringParameter' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        # existe una base de datos que sea remota que se pueda usar ?  tocaria crear una base de datos
        $connectionString =  'Data Source=localhost;Initial Catalog=ReportServer'
        $dataSourcePath = '/' + $dataSourceName
        # Test if the DataSource can be created
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -ConnectionString $connectionString
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }

    Context "Create RsDataSource with Proxy and ReportServerUri parameters "{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSourceAllParameters' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        $proxy = New-RsWebServiceProxy 
        $dataSourcePath = '/' + $dataSourceName
        $reportServerUri = 'http://localhost/reportserver'
        # Test if the DataSource can be created
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -Proxy $proxy -ReportServerUri $reportServerUri
        # Test if the data source has the specified name and path
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }
# hago lo del credential retrieval integrated acá?
     Context "Unsupported Data Source Extension validation"{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSurceExtensionException' + [guid]::NewGuid()
        $extension = 'SQL2'
        $credentialRetrieval = 'Integrated'
        $dataSourcePath = '/' + $dataSourceName
        It "Should throw an exception when datasource is failed to be create" {
             { New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval } | Should throw 
             { Get-RsDataSource -Path $dataSourcePath } | Should throw
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }

    Context "STORE credential validation" {
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSurceStoreException' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'STORE'
        $dataSourcePath = '/' + $dataSourceName
        It "Should throw an exception when Store credential retrieval are given without providing credential" {
            { New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval } | Should throw 
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }

    Context "Create Data Source with PSCredentials" {
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSurceCredentials' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        # Creation of credentials
        $password ='MyPassword'
        $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $credentials = Create-PSCredential -User $user -Password $password
        # Test if the DataSource is created
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -DataSourceCredential $credentials
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }

    # This test is not available for now because the data source is never disabled 
    # Context "Create RsDataSource in a Disabled mode and minimun parameters (Extension is SQL and Credential retierval is None)"{
    #     # Declare datasource name, extension, credential retrieval, and data source path.
    #     $dataSourceName = 'SutDataSourceDisabled' + [guid]::NewGuid()
    #     $extension = 'SQL'
    #     $credentialRetrieval = 'None'
    #     $dataSourcePath = '/' + $dataSourceName
    #     $disabled = $true
    #     # Test if the DataSource can be created
    #     New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -Disabled $disabled
    #     # Test if the data source has the specified name and path
    #     $dataSource =  Get-RsDataSource -Path $dataSourcePath 
    #     $dataSourceEnabled = $dataSourceList.Enabled 
    #     It "Should be a new data source" {
    #         $dataSourceCount | Should Be 1
    #     }
    #     # Removing folders used for testing
    #     # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    # }

    Context "Create RsDataSource and overwrite it"{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSourceOverwrite' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'Integrated'
        $dataSourcePath = '/' + $dataSourceName
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
        It "Should overwrite a datasource" {
            { New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -Overwrite } | Should not throw
            { New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval } | Should throw
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }

    Context "Create RsDataSource with ImpersonateUser Parameter"{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSurceImpersonateUser' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -ImpersonateUser
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }

#there might be a problem
    Context "Create RsDataSource with Windows Credentials Parameter"{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSurceWindowsCredentials' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        # Test if the DataSource is created
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -WindowsCredentials
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }

    Context "Create RsDataSource with prompt Credentials Retrieval"{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSurcePrompt' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'Prompt'
        $dataSourcePath = '/' + $dataSourceName
        $prompt = "Please enter your username and password"
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -Prompt $prompt
        # Test if the data source has the specified name and path
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }
}