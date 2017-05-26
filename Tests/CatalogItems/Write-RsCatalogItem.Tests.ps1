# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Write-RsFolderContent" {

    Context "Write-RsFolderContent with min parameters"{
        $folderName = 'SutWriteRsFolderContentMinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath
        
        It "Should upload a local report in Report Server" {
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
        }

        It "Should upload a local RsDataSource in Report Server" {
            $uploadedDataSource = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSource'
            $uploadedDataSource.Name | Should Be 'SutWriteRsFolderContent_DataSource'
        }

        It "Should upload a local DataSet in Report Server" {
            $uploadedDataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
            $uploadedDataSet.Name | Should Be 'UnDataset'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath
    }
}