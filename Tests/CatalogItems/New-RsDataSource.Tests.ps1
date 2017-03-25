# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "New-RsDataSource" {
    Context "Create RsDataSource with minimun parameters (Extension is SQL and Credential retierval is None)"{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSourceMinParameters' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        # Test if the DataSource can be created
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
        # Test if the data source has the specified name and path
        $dataSourceList =  Get-RsDataSource -Path $dataSourcePath 
        $dataSourceCount = $dataSourceList.Count
        It "Should be a new data source" {
            $dataSourceCount | Should Be 1
        }
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
        $dataSourceList =  Get-RsDataSource -Path $dataSourcePath 
        $dataSourceCount = $dataSourceList.Count
        It "Should be a new data source" {
            $dataSourceCount | Should Be 1
        }
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
        # Test if the data source has the specified name and path
        $dataSourceList =  Get-RsDataSource -Path $dataSourcePath 
        $dataSourceCount = $dataSourceList.Count
        It "Should be a new data source" {
            $dataSourceCount | Should Be 1
        }
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
        $dataSourceList =  Get-RsDataSource -Path $dataSourcePath 
        $dataSourceCount = $dataSourceList.Count
        It "Should be a new data source" {
            $dataSourceCount | Should Be 1
        }
    }
# hago lo del credential retrieval integrated acá?
     Context " Check it throw an exception if an unsupported extension is used with Integrated credential Retrieval "{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSurceExtensionExtension' + [guid]::NewGuid()
        $extension = 'SQL2'
        $credentialRetrieval = 'Integrated'
        $dataSourcePath = '/' + $dataSourceName
        # Test if the DataSource can be created wih an unsupported extension
        try{
            New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -errorvariable MyErr 
         }catch{}
         # Test the datasource wasn´t created
         try{
            Get-RsDataSource -Path $dataSourcePath -errorvariable MyErr2
         }catch{}
         # Test the datasource 
        It "Should not create a data source" {
         #   $dataSourceCount | Should Be 0
             { throw $MyErr  } | Should throw "Extension specified is not supported by the report server!"
             { throw $MyErr2 } | Should throw 'Exception calling "GetDataSourceContents"'
        }
    }
# esto si debería ser así?
    Context " Check when Store CredentialRetrieval is given, a credential is given " {
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutDataSurceExtensionExtension' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'STORE'
        $dataSourcePath = '/' + $dataSourceName
        # Test if the DataSource can be created
        try{
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -errorvariable MyErr 
        }catch{}
        It "Should be a new data source" {
            { throw $MyErr  } | Should throw "Username and password (-DatasourceCredentials) must be specified when CredentialRetrieval is Store!"
        }
    }

  #  Context "Create RsDataSource with Credentials Parametres and Min Parameters (extenxion SQL, CredentialRetrieval Prompt) " {
      
}