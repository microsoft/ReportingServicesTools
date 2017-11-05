# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = 'http://localhost/reports'
$reportServerUri = 'http://localhost/reportserver'

Describe "Get-RsRestItemDataSources" {
    $rsFolderPath = ""

    BeforeEach {
        # Creating a new folder in RS
        $folderName = 'SUT_GetRsRestItemDataSources_' + [guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -RsFolder / -FolderName $folderName
        $rsFolderPath = '/' + $folderName

        # Uploading a report
        $sqlPowerBiReportPath = (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\SqlPowerBIReport.pbix'
        Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $sqlPowerBiReportPath -RsFolder $rsFolderPath
    }

    AfterEach {
        Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsFolder $rsFolderPath
    }

    Context "ReportPortalUri parameter" {
        It "Should fetch data sources" {
            $report = Get-RsRestItemDataSources -ReportPortalUri $reportPortalUri -RsItem "$rsFolderPath/SqlPowerBIReport" -Verbose
            $report.DataSources | Should Not BeNullOrEmpty
            $report.DataSources[0].ConnectionString | Should Be "localhost;ReportServer"
            $report.DataSources[0].DataModelDataSource | Should Not BeNullOrEmpty
            $report.DataSources[0].DataModelDataSource.Type | Should Be "Import"
            $report.DataSources[0].DataModelDataSource.Kind | Should Be "Sql"
            $report.DataSources[0].DataModelDataSource.AuthType | Should Be "Windows"
        }
    }

    Context "WebSession parameter" {
        $webSession = $null

        BeforeEach {
            $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri
        }

        It "Should fetch data sources" {
            $report = Get-RsRestItemDataSources -WebSession $webSession -RsItem "$rsFolderPath/SqlPowerBIReport" -Verbose
            $report.DataSources | Should Not BeNullOrEmpty
            $report.DataSources[0].ConnectionString | Should Be "localhost;ReportServer"
            $report.DataSources[0].DataModelDataSource | Should Not BeNullOrEmpty
            $report.DataSources[0].DataModelDataSource.Type | Should Be "Import"
            $report.DataSources[0].DataModelDataSource.Kind | Should Be "Sql"
            $report.DataSources[0].DataModelDataSource.AuthType | Should Be "Windows"
        }
    }
}
