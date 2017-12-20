# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Write-RsCatalogItem" {
    
    Context "Write-RsCatalogItem with min parameters"{
        $folderName = 'SutWriteRsCatalogItem_MinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        
        It "Should upload a local report in Report Server" {
            $localReportPath = $localPath + '\emptyReport.rdl' 
            Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
        }

        It "Should upload a local RsDataSource in Report Server" {
            $localDataSourcePath = $localPath + '\SutWriteRsFolderContent_DataSource.rsds' 
            Write-RsCatalogItem -Path $localDataSourcePath -RsFolder $folderPath
            $uploadedDataSource = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSource'
            $uploadedDataSource.Name | Should Be 'SutWriteRsFolderContent_DataSource'
        }

        It "Should upload a local DataSet in Report Server" {
            $localDataSetPath = $localPath + '\UnDataset.rsd' 
            Write-RsCatalogItem -Path $localDataSetPath -RsFolder $folderPath
            $uploadedDataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
            $uploadedDataSet.Name | Should Be 'UnDataset'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsCatalogItem with Proxy parameter"{
        $folderName = 'SutWriteRsCatalogItem_ProxyParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $proxy = New-RsWebServiceProxy 
        $localReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl' 
        Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Proxy $proxy
        
        It "Should upload a local Report in ReportServer with Proxy Parameter" {
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsCatalogItem with Proxy and ReportServerUri parameter"{
        $folderName = 'SutWriteRsCatalogItem_ReporServerUrioProxyParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $proxy = New-RsWebServiceProxy 
        $reportServerUri = 'http://localhost/reportserver'
        $localReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl' 
        Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Proxy $proxy -ReportServerUri $reportServerUri
        
        It "Should upload a local Report in ReportServer with Proxy and ReportServerUri Parameter" {
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

     Context "Write-RsCatalogItem with ReportServerUri parameter"{
        $folderName = 'SutWriteRsCatalogItem_ReportServerUriParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $reportServerUri = 'http://localhost/reportserver'
        $localReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl' 
        Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -ReportServerUri $reportServerUri
        
        It "Should upload a local Report in ReportServer with ReportServerUri Parameter" {
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsCatalogItem with Overwrite parameter"{
        $folderName = 'SutWriteCatalogItem_OverwriteParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl' 
        Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath 
        $localDataSourcePath =  (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\SutWriteRsFolderContent_DataSource.rsds' 
        
        It "Should upload a local Report in ReportServer with Overwrite Parameter" {
            { Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath } | Should Throw
            { Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Overwrite } | Should Not Throw
            $overwrittenReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $overwrittenReport.Name | Should Be 'emptyReport'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }
}