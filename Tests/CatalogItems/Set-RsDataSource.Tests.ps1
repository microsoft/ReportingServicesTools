# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Function Get-ExistingDataExtension
{
        $proxy = New-RsWebServiceProxy
        return $proxy.ListExtensions("Data")[0].Name
}

Describe "Set-RsDataSource" {
        Context "Get-RsItemReference with min parameters"{
            $folderName = 'SutSetRsDataSetReferenceMinParameters' + [guid]::NewGuid()
            New-RsFolder -Path / -FolderName $folderName
            $folderPath = '/' + $folderName
            $localDataSourcePath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\SutWriteRsFolderContent_DataSource.rsds'
            Write-RsCatalogItem -Path $localDataSourcePath -RsFolder $folderPath
            $dataSourcePath =  $folderPath + '/SutWriteRsFolderContent_DataSource'
            # DataSource definition
            $proxy = New-RsWebServiceProxy
            $namespace = $proxy.GetType().Namespace
            $datasourceDataType = "$namespace.DataSourceDefinition"
            $datasource = New-Object $datasourceDataType  
            $datasource.Extension = Get-ExistingDataExtension
            $datasource.CredentialRetrieval = 'None'
            $datasource.ConnectString =  'Data Source=localhost;Initial Catalog=ReportServer'

            Set-RsDataSource -Path $dataSourcePath -DataSourceDefinition $datasource
        }
         It "Should set a RsDataSource" {
           
        }
        Remove-RsCatalogItem -RsFolder $folderPath

        Context "Get-RsItemReference with Proxy parameter"{
        }

        Context "Get-RsItemReference with ReportServerUri parameter"{
        }

        Context "Get-RsItemReference with ReportServerUri and Proxy parameter"{
        }


}
