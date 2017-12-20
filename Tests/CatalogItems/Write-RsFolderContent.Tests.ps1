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
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsFolderContent with ReportServerUri parameter"{
        $folderName = 'SutWriteRsFolderContentReportServerUri' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\" -Verbose).FullName  + '\Tests\CatalogItems\testResources'
        $reportServerUri = 'http://localhost/reportserver'
        Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath -ReportServerUri $reportServerUri
        $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
        It "Should upload a local report in Report Server with ReportServerUri Parameter" {
            $uploadedReport.Name | Should Be 'emptyReport'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsFolderContent with Proxy Parameter"{
        $folderName = 'SutWriteRsFolderContentProxy' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\" -Verbose).FullName  + '\Tests\CatalogItems\testResources'
        $proxy = New-RsWebServiceProxy 
        Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath -Proxy $proxy
        $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
        It "Should upload a local report in Report Server with Proxy Parameter" {
            $uploadedReport.Name | Should Be 'emptyReport'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsFolderContent with Proxy and ReportServerUri"{
        $folderName = 'SutWriteRsFolderContentAll' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\" -Verbose).FullName  + '\Tests\CatalogItems\testResources'
        $proxy = New-RsWebServiceProxy 
        $reportServerUri = 'http://localhost/reportserver'
        Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath -Proxy $proxy -ReportServerUri $reportServerUri
        $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
        It "Should upload a local report in Report Server with ReportServerUri and Proxy Parameters" {
            $uploadedReport.Name | Should Be 'emptyReport'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

     Context "Write-RsFolderContent with Recurse Parameter"{
        $folderName = 'SutWriteRsFolderContentRecurse' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\" -Verbose).FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath -Recurse
       It "Should upload a local subFolder with Recurse Parameter" {
            $uploadedFolders = (Get-RsFolderContent -RsFolder $folderPath -Recurse ) | Where-Object TypeName -eq 'Folder' | Sort-Object -Property Name -Descending
            $uploadedFolders.Count | Should Be 2
            $uploadedFolders[0].Name | Should Be 'testResources2'
            $uploadedFolders[1].Name | Should Be 'datasources'
        }

       It "Should upload a report that is in a folder and a second report that is in a subfolder" {
            $uploadedReports = (Get-RsFolderContent -RsFolder $folderPath -Recurse ) | Where-Object TypeName -eq 'Report'
            $uploadedReports.Count | Should Be 4
        }

         It "Should upload a local RsDataSource in Report Server" {
            $uploadedDataSource = (Get-RsFolderContent -RsFolder $folderPath -Recurse ) | Where-Object TypeName -eq 'DataSource'
            $uploadedDataSource.Name | Should Be 'SutWriteRsFolderContent_DataSource'
        }

        It "Should upload a local DataSet in Report Server" {
            $uploadedDataSet = (Get-RsFolderContent -RsFolder $folderPath -Recurse ) | Where-Object TypeName -eq 'DataSet'
            $uploadedDataSet.Name | Should Be 'UnDataset'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }
}