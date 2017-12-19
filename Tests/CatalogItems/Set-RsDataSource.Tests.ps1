# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Function Get-ExistingDataExtension
{
        $proxy = New-RsWebServiceProxy
        return $proxy.ListExtensions("Data")[0].Name
}

Describe "Set-RsDataSource" {
        $dataSourceName = $null
        $extension = $null
        $credentialRetrieval = $null
        $dataSourcePath = $null

        BeforeEach {
                $dataSourceName = 'SutSetDataSource_MinParameter' + [guid]::NewGuid()
                $extension = Get-ExistingDataExtension
                $credentialRetrieval = 'None'
                $dataSourcePath = '/' + $dataSourceName
                New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
                $dataSourcePath =  '/' + $dataSourceName
        }

        AfterEach {
                Remove-RsCatalogItem -RsFolder $dataSourcePath -Confirm:$false
        }

        It "Should set a RsDataSource with min parameters" {
                $rsDataSource = Get-RsDataSource -Path $dataSourcePath 

                # DataSource definition
                $proxy = New-RsWebServiceProxy
                $namespace = $proxy.GetType().Namespace
                $datasourceDataType = "$namespace.DataSourceDefinition"
                $datasource = New-Object $datasourceDataType  
                $datasource.Extension = Get-ExistingDataExtension
                $datasource.CredentialRetrieval = 'Prompt'
                $datasource.ConnectString =  'Data Source=localhost;Initial Catalog=ReportServer'
                Set-RsDataSource -Path $dataSourcePath -DataSourceDefinition $datasource

                $setRsDataSource = Get-RsDataSource -Path $dataSourcePath
                $rsDataSource.CredentialRetrieval | Should Not Be $setRsDataSource.CredentialRetrieval
        }

        It "Should set a RsDataSource with proxy Parameter" {
                $rsDataSource = Get-RsDataSource -Path $dataSourcePath 

                # DataSource definition
                $proxy = New-RsWebServiceProxy
                $namespace = $proxy.GetType().Namespace
                $datasourceDataType = "$namespace.DataSourceDefinition"
                $datasource = New-Object $datasourceDataType  
                $datasource.Extension = Get-ExistingDataExtension
                $datasource.CredentialRetrieval = 'Prompt'
                $datasource.ConnectString =  'Data Source=localhost;Initial Catalog=ReportServer'
                Set-RsDataSource -Path $dataSourcePath -DataSourceDefinition $datasource -Proxy $proxy
                
                $setRsDataSource = Get-RsDataSource -Path $dataSourcePath
                $rsDataSource.CredentialRetrieval | Should Not Be $setRsDataSource.CredentialRetrieval
        }

        It "Should set a RsDataSource with ReportServerUri parameter" {
                $rsDataSource = Get-RsDataSource -Path $dataSourcePath 
                $reportServerUri = 'http://localhost/reportserver'

                # DataSource definition
                $proxy = New-RsWebServiceProxy
                $namespace = $proxy.GetType().Namespace
                $datasourceDataType = "$namespace.DataSourceDefinition"
                $datasource = New-Object $datasourceDataType  
                $datasource.Extension = Get-ExistingDataExtension
                $datasource.CredentialRetrieval = 'Prompt'
                $datasource.ConnectString =  'Data Source=localhost;Initial Catalog=ReportServer'
                Set-RsDataSource -Path $dataSourcePath -DataSourceDefinition $datasource -ReportServerUri $reportServerUri

                $setRsDataSource = Get-RsDataSource -Path $dataSourcePath
                $rsDataSource.CredentialRetrieval | Should Not Be $setRsDataSource.CredentialRetrieval
        }

        It "Should set a RsDataSource with Proxy and ReportServerUri parameter" {
                $rsDataSource = Get-RsDataSource -Path $dataSourcePath 
                $reportServerUri = 'http://localhost/reportserver'

                # DataSource definition
                $proxy = New-RsWebServiceProxy
                $namespace = $proxy.GetType().Namespace
                $datasourceDataType = "$namespace.DataSourceDefinition"
                $datasource = New-Object $datasourceDataType  
                $datasource.Extension = Get-ExistingDataExtension
                $datasource.CredentialRetrieval = 'Prompt'
                $datasource.ConnectString =  'Data Source=localhost;Initial Catalog=ReportServer'
                Set-RsDataSource -Path $dataSourcePath -DataSourceDefinition $datasource -Proxy $proxy -ReportServerUri $reportServerUri

                $setRsDataSource = Get-RsDataSource -Path $dataSourcePath
                $rsDataSource.CredentialRetrieval | Should Not Be $setRsDataSource.CredentialRetrieval
        }

        It "Should set description of data source" {
                # updating description
                $originalDataSource = Get-RsDataSource -Path $dataSourcePath 
                $description = 'This is a description'
                Set-RsDataSource -Path $dataSourcePath -DataSourceDefinition $originalDataSource -Description $description

                # verifying property got created
                $proxy = New-RsWebServiceProxy
                $descriptionProperty = $proxy.GetProperties($dataSourcePath, $null) | Where { $_.Name -eq 'Description' }
                $descriptionProperty | Should Not BeNullOrEmpty
                $descriptionProperty.Value | Should be $description
        }
}
