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
            Remove-RsCatalogItem -RsFolder $rsDataSourcePath -Confirm:$false
            $rsDataSourcesList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSource'
            $rsDataSourcesList.Count | Should Be 0
        }

        It "Should remove a Report" {
            $rsReportsList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $rsReportsList.Count | Should Be 1
            # Remove a report
            $rsReportPath = $folderPath + '/emptyReport' 
            Remove-RsCatalogItem -RsFolder $rsReportPath -Confirm:$false
            $rsReportsList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $rsReportsList.Count | Should Be 0
        }

        It "Should remove a DataSet" {
            $rsDataSetsList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
            $rsDataSetsList.Count | Should Be 1
            # Remove a report
            $rsDataSetPath = $folderPath + '/UnDataset' 
            Remove-RsCatalogItem -RsFolder $rsDataSetPath -Confirm:$false
            $rsDataSetsList = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
            $rsDataSetsList.Count | Should Be 0
        }

        It "Should remove a RsFolder" {
            $folderList = Get-RsFolderContent -RsFolder '/'
            $folder = $folderList | Where-Object name -eq $folderName
            $folderPath = '/' + $folderName
            $folder.count | Should Be 1
            # Remove a RsFolder
            Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
            $folderList = Get-RsFolderContent -RsFolder '/'
            $folder = $folderList | Where-Object name -eq $folderName
            $folder.count | Should Be 0
        }
    }

    Context "Remove-RsCatalogItem with Proxy parameter"{
        $folderName = 'SutRemoveRsCatalogItem_ProxyParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $proxy = New-RsWebServiceProxy
        It "Should remove a RsFolder with Proxy parameter" {
            $folderList = Get-RsFolderContent -RsFolder '/' 
            $folder = $folderList | Where-Object name -eq $folderName
            $folder.count | Should Be 1
            # Remove a RsFolder
            Remove-RsCatalogItem -Path $folderPath -Proxy $proxy -Confirm:$false
            $folderList = Get-RsFolderContent -RsFolder '/'
            $folder = $folderList | Where-Object name -eq $folderName
            $folder.count | Should Be 0 
        }
    }

    Context "Remove-RsCatalogItem with Proxy and ReportServerUri parameter"{
        $folderName = 'SutRemoveRsCatalogItem_ProxyReportServerUriParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $proxy = New-RsWebServiceProxy
        $reportServerUri = 'http://localhost/reportserver'
        It "Should remove a RsFolder with Proxy and ReportServerUri parameter" {
            $folderList = Get-RsFolderContent -RsFolder '/' 
            $folder = $folderList | Where-Object name -eq $folderName
            $folder.count | Should Be 1
            # Remove a RsFolder
            Remove-RsCatalogItem -Path $folderPath -Proxy $proxy -ReportServerUri $reporServerUri -Confirm:$false
            $folderList = Get-RsFolderContent -RsFolder '/'
            $folder = $folderList | Where-Object name -eq $folderName
            $folder.count | Should Be 0 
        }
    }

    Context "Remove-RsCatalogItem with ReportServerUri parameter"{
        $folderName = 'SutRemoveRsCatalogItem_ReportServerUriParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $reportServerUri = 'http://localhost/reportserver'
        It "Should remove a RsFolder with ReportServerUri parameter" {
            $folderList = Get-RsFolderContent -RsFolder '/'
            $folder = $folderList | Where-Object name -eq $folderName
            $folder.count | Should Be 1
            # Remove a RsFolder
            Remove-RsCatalogItem -ReportServerUri $reportServerUri -Path $folderPath -Confirm:$false
            $folderList = Get-RsFolderContent -RsFolder '/'
            $folder = $folderList | Where-Object name -eq $folderName
            $folder.count | Should Be 0 
        }
    }

    Context "Remove-RsCatalogItem with pipping " {
        $folderName = 'SutRemoveRsCatalogItem_pipping' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        It "Should remove a RsFolder" {
            $folderList = Get-RsFolderContent -RsFolder '/'
            $folder = $folderList | Where-Object name -eq $folderName
            $folder.count | Should Be 1
            # Remove a RsFolder
            $folder | Remove-RsCatalogItem -Confirm:$false
            $folderList = Get-RsFolderContent -RsFolder '/'
            $folder = $folderList | Where-Object name -eq $folderName
            $folder.count | Should Be 0 
        }
    }
}