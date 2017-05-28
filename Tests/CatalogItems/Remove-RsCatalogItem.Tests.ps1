# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Remove-RsCatalogItem" {

    Context "Remove-RsCatalogItem with min parameters"{
        $folderName = 'SutRemoveRsCatalogItem_MinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localPath -RsFolder $folderPath
        
        It "Should remove a DataSource" {
            $rsDataSourcesList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSource'
            $rsDataSourcesList.Count | Should Be 1
            # Remove a DataSource
            $rsDataSourcePath = $folderPath + '/SutWriteRsFolderContent_DataSource' 
            Remove-RsCatalogItem -RsFolder $rsDataSourcePath
            $rsDataSourcesList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSource'
            $rsDataSourcesList.Count | Should Be 0
        }

        It "Should remove a Report" {
            $rsReportsList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $rsReportsList.Count | Should Be 1
            # Remove a report
            $rsReportPath = $folderPath + '/emptyReport' 
            Remove-RsCatalogItem -RsFolder $rsReportPath
            $rsReportsList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $rsReportsList.Count | Should Be 0
        }

        It "Should remove a DataSet" {
            $rsDataSetsList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
            $rsDataSetsList.Count | Should Be 1
            # Remove a report
            $rsDataSetPath = $folderPath + '/UnDataset' 
            Remove-RsCatalogItem -RsFolder $rsDataSetPath
            $rsDataSetsList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
            $rsDataSetsList.Count | Should Be 0
        }

        It "Should remove a RsFolder" {
            $folderList = Get-RsFolderContent -RsFolder /
            $folderCount = ($folderList | Where-Object name -eq $folderName).Count
            $folderPath = '/' + $folderName
            $folderCount | Should Be 1
            # Remove a RsFolder
            Remove-RsCatalogItem -RsFolder $folderPath
            $folderList = Get-RsFolderContent -RsFolder /
            $folderCount = ($folderList | Where-Object name -eq $folderName).Count
            $folderPath = '/' + $folderName
            $folderCount | Should Be 0
        }
    }

    Context "Remove-RsCatalogItem with Proxy parameter"{
        $folderName = 'SutRemove-RsCatalogItem_ProxyParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localPath -RsFolder $folderPath

        It "Should remove a Report with Proxy Parameter" {
            $rsReportsList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $rsReportsList.Count | Should Be 1
            # Remove a report
            $rsReportPath = $folderPath + '/emptyReport' 
            $proxy = New-RsWebServiceProxy
            Remove-RsCatalogItem -RsFolder $rsReportPath -Proxy $proxy
            $rsReportsList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $rsReportsList.Count | Should Be 0
        }

    }

    Context "Write-RsFolderContent with Proxy and ReportServerUri parameter"{
        $folderName = 'SutRemove-RsCatalogItem_ProxyReportServerUriParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localPath -RsFolder $folderPath

        It "Should remove a Report with Proxy Parameter" {
            $rsReportsList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $rsReportsList.Count | Should Be 1
            # Remove a report
            $rsReportPath = $folderPath + '/emptyReport' 
            $proxy = New-RsWebServiceProxy
            $reportServerUri = 'http://localhost/reportserver'
            Remove-RsCatalogItem -RsFolder $rsReportPath -Proxy $proxy -ReportServerUri $reporServerUri
            $rsReportsList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $rsReportsList.Count | Should Be 0
        }

    }

    Context "Remove-RsCatalogItem with ReportServerUri parameter"{
        $folderName = 'SutRemove-RsCatalogItem_ReportServerUrParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localPath -RsFolder $folderPath

        It "Should remove a Report with ReportServer Parameter" {
            $rsReportsList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $rsReportsList.Count | Should Be 1
            # Remove a report
            $rsReportPath = $folderPath + '/emptyReport' 
            $reportServerUri = 'http://localhost/reportserver'
            Remove-RsCatalogItem -RsFolder $rsReportPath -ReportServerUri $reportServerUri
            $rsReportsList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $rsReportsList.Count | Should Be 0
        }

    }
}