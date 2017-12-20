# Copyright (c) 2017 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

Describe "Get-RsItemDataSource" { 
    $rsFolderPath = ''
    $datasourcesReportPath = ''
    $noDatasourcesReportPath = ''

    BeforeEach {
        # create new folder in RS
        $folderName = 'SUT_OutRsRestCatalogItem_' + [guid]::NewGuid()
        New-RsFolder -ReportServerUri $reportServerUri -RsFolder / -FolderName $folderName
        $rsFolderPath = '/' + $folderName

        $localResourcesPath = (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\datasources'
        
        # upload datasourcesReport to new folder in RS
        Write-RsCatalogItem -ReportServerUri $reportServerUri -Path "$localResourcesPath\datasourcesReport.rdl" -RsFolder $rsFolderPath
        $datasourcesReportPath = "$rsFolderPath/datasourcesReport"

        # upload noDatasourcesReport to new folder in RS
        Write-RsCatalogItem -ReportServerUri $reportServerUri -Path "$localResourcesPath\noDatasourcesReport.rdl" -RsFolder $rsFolderPath
        $noDatasourcesReportPath = "$rsFolderPath/noDatasourcesReport"
    }

    AfterEach {
        Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsItem $datasourcesReportPath -Confirm:$false
        Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsItem $noDatasourcesReportPath -Confirm:$false
        Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsItem $rsFolderPath -Confirm:$false
    }

    Context "Fetches data sources with explicit ReportServerUri parameter"{
        It "Should get 0 data sources if Report doesn't have any" {
            $dataSource = Get-RsItemDataSource -Path $noDatasourcesReportPath -ReportServerUri $reportServerUri
            $dataSource.Count | Should Be 0
        }

        It "Should get correct number of data sources if report doesn't have any" {
            $dataSource = Get-RsItemDataSource -Path $datasourcesReportPath -ReportServerUri $reportServerUri
            $dataSource.Count | Should Be 2
        }
    }

    Context "Fetches data sources with Proxy parameter"{
        $proxy = New-RsWebServiceProxy -ReportServerUri $reportserverUri

        It "Should get 0 data sources if Report doesn't have any" {
            $dataSource = Get-RsItemDataSource -Path $noDatasourcesReportPath -Proxy $proxy
            $dataSource.Count | Should Be 0
        }

        It "Should get correct number of data sources if report doesn't have any" {
            $dataSource = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSource.Count | Should Be 2
        }
    }
}