# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Function Get-ExistingDataExtension
{
        $proxy = New-RsWebServiceProxy
        return $proxy.ListExtensions("Data")[0].Name
}

Describe "Set-RsDataSource" {
        Context "Set-RsDataSource with min parameters"{
                $dataSourceName = 'SutSetDataSourceProxyParameter' + [guid]::NewGuid()
                $extension = Get-ExistingDataExtension
                $credentialRetrieval = 'None'
                $dataSourcePath = '/' + $dataSourceName
                New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
                $dataSourcePath =  '/' + $dataSourceName
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
        
                It "Should set a RsDataSource with min parameters" {
                 $setRsDataSource = Get-RsDataSource -Path $dataSourcePath
                 $rsDataSource.CredentialRetrieval | Should Not Be $setRsDataSource.CredentialRetrieval
                }
                Remove-RsCatalogItem -RsFolder $dataSourcePath
        }

        

        Context "Set-RsDataSource with Proxy parameter"{
                $dataSourceName = 'SutSetDataSourceProxyParameter' + [guid]::NewGuid()
                $extension = Get-ExistingDataExtension
                $credentialRetrieval = 'None'
                $dataSourcePath = '/' + $dataSourceName
                New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval 
                $dataSourcePath =  '/' + $dataSourceName
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
        
                It "Should set a RsDataSource with proxy Parameter" {
                 $setRsDataSource = Get-RsDataSource -Path $dataSourcePath
                 $rsDataSource.CredentialRetrieval | Should Not Be $setRsDataSource.CredentialRetrieval
                }
                Remove-RsCatalogItem -RsFolder $dataSourcePath
        }

        Context "Set-RsDataSource with ReportServerUri parameter"{
                $dataSourceName = 'SutSetDataSourceReportServerUriParameter' + [guid]::NewGuid()
                $extension = Get-ExistingDataExtension
                $credentialRetrieval = 'None'
                $dataSourcePath = '/' + $dataSourceName
                New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
                $dataSourcePath =  '/' + $dataSourceName
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
        
                It "Should set a RsDataSource with reportServerUri parameter" {
                 $setRsDataSource = Get-RsDataSource -Path $dataSourcePath
                 $rsDataSource.CredentialRetrieval | Should Not Be $setRsDataSource.CredentialRetrieval
                }
                Remove-RsCatalogItem -RsFolder $dataSourcePath
        }

        Context "Set-RsDataSource with ReportServerUri and Proxy parameter"{
                $dataSourceName = 'SutSetDataSourceReportServerUriProxyParameter' + [guid]::NewGuid()
                $extension = Get-ExistingDataExtension
                $credentialRetrieval = 'None'
                $dataSourcePath = '/' + $dataSourceName
                New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval 
                $dataSourcePath =  '/' + $dataSourceName
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
        
                It "Should set a RsDataSource with proxy and ReportServerUri parameter" {
                 $setRsDataSource = Get-RsDataSource -Path $dataSourcePath
                 $rsDataSource.CredentialRetrieval | Should Not Be $setRsDataSource.CredentialRetrieval
                }
                Remove-RsCatalogItem -RsFolder $dataSourcePath
        }
}
