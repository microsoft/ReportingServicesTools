# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Get-RsDataSource" {
    Context "Get RsDataSource with ReportServerUri parameters "{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutGetDataSourceReportServerUri' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        $reportServerUri = 'http://localhost/reportserver'
        # Create a DataSource
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval 
        # Test if the data source has the specified name and path
        $dataSourceList =  Get-RsDataSource -Path $dataSourcePath -ReportServerUri $reportServerUri
        $dataSourceCount = $dataSourceList.Count
        It "Should get a data source" {
            $dataSourceCount | Should Be 1
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }

    Context "Get RsDataSource with Proxy parameters "{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutGetDataSourceProxy' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        # Declare Proxy
        $proxy = New-RsWebServiceProxy 
        # Create a DataSource
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval 
        # Test if the data source has the specified name and path
        $dataSource =  Get-RsDataSource -Path $dataSourcePath -Proxy $proxy
        It "Should get a data source" {
            $dataSource.Name | Should Be $dataSourceName
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }

    Context "Get RsDataSource with Proxy y ReportServerUri parameters "{
        # Declare datasource name, extension, credential retrieval, and data source path.
        $dataSourceName = 'SutGetDataSourceProxy' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        # Declare Proxy
        $proxy = New-RsWebServiceProxy 
        # Create a DataSource
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -ReportServerUri $reportServerUri
        # Test if the data source has the specified name and path
        $dataSource =  Get-RsDataSource -Path $dataSourcePath -Proxy $proxy
        It "Should get a data source" {
            $dataSource.Name | Should Be $dataSourceName
        }
        # Removing folders used for testing
        # Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $dataSourcePath
    }
}