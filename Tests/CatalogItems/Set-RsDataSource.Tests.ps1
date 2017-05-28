# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Set-RsDataSource" {
        Context "Get-RsItemReference with min parameters"{
            $folderName = 'SutSetRsDataSetReferenceMinParameters' + [guid]::NewGuid()
            New-RsFolder -Path / -FolderName $folderName
            $folderPath = '/' + $folderName
            $localDataSourcePath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\SutWriteRsFolderContent_DataSource.rsds'
            Write-RsCatalogItem -Path $localDataSourcePath -RsFolder $folderPath
            $dataSourcePath =  $folderPath + '/SutWriteRsFolderContent_DataSource'
            $proxy = New-RsWebServiceProxy
            $namespace = $proxy.GetType().Namespace
            $datasourceDataType = "$namespace.DataSourceDefinition"
            

            $datasource = New-Object $datasourceDataType  
            $datasource.Extension = 'SQL'
            $datasource.CredentialRetrieval = 'None'
            $datasource.ConnectString =  'Data Source=localhost;Initial Catalog=ReportServer'

            Set-RsDataSource -Path $dataSourcePath -DataSourceDefinition $datasource
        }
         It "Should set a RsDataSource" {
           
        }
        Remove-RsCatalogItem -RsFolder $folderPath

}
