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
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath -Recurse ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.TypeName | Should Be 'Report'
        }

        It "Should upload a local RsDataSoutce in Report Server" {
            $uploadedDataSource = (Get-RsFolderContent -RsFolder $folderPath -Recurse ) | Where-Object TypeName -eq 'DataSource'
            $uploadedDataSource.TypeName | Should Be 'DataSource'
        }

        It "Should upload a local DataSet in Report Server" {
            $uploadedDataSet = (Get-RsFolderContent -RsFolder $folderPath -Recurse ) | Where-Object TypeName -eq 'DataSet'
            $uploadedDataSet.TypeName | Should Be 'DataSet'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath
    }

    Context "Write-RsFolderContent with ReportServerUri parameter"{
        $folderName = 'SutWriteRsFolderContentReportServerUri' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\" -Verbose).FullName  + '\Tests\CatalogItems\testResources'
        $reportServerUri = 'http://localhost/reportserver'
        Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath -ReportServerUri $reportServerUri
        $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath -Recurse ) | Where-Object TypeName -eq 'Report'
        It "Should upload a local report in Report Server with ReportServerUri Parameter" {
            $uploadedReport.TypeName | Should Be 'Report'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath
    }

    Context "Write-RsFolderContent with Proxy Parameter"{
        $folderName = 'SutWriteRsFolderContentProxy' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\" -Verbose).FullName  + '\Tests\CatalogItems\testResources'
        $proxy = New-RsWebServiceProxy 
        Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath -Proxy $proxy
        $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath -Recurse ) | Where-Object TypeName -eq 'Report'
        It "Should upload a local report in Report Server with Proxy Parameter" {
            $uploadedReport.TypeName | Should Be 'Report'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath
    }

    Context "Write-RsFolderContent with Proxy and ReportServerUri"{
        $folderName = 'SutWriteRsFolderContentAll' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\" -Verbose).FullName  + '\Tests\CatalogItems\testResources'
        $proxy = New-RsWebServiceProxy 
        $reportServerUri = 'http://localhost/reportserver'
        Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath -Proxy $proxy -ReportServerUri $reportServerUri
        $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath -Recurse ) | Where-Object TypeName -eq 'Report'
        It "Should upload a local report in Report Server with ReportServerUri and Proxy Parameters" {
            $uploadedReport.TypeName | Should Be 'Report'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath
    }

     Context "Write-RsFolderContent with Recurse Parameter"{
        $folderName = 'SutWriteRsFolderContentRecurse' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\" -Verbose).FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath -Recurse
        $uploadedReports = (Get-RsFolderContent -RsFolder $folderPath -Recurse ) | Where-Object TypeName -eq 'Report'
        It "Should upload a report that is in a folder and a second report in a subfolder" {
            $uploadedReports.Count | Should Be 2
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath
    }
}