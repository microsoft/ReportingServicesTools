# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = 'http://macbookpro/reports_pbi'

Describe "Get-RsItemDataSources" {
    # Uploading a report
    $folderName = 'SUT_GetRsRestItemDataSources_' + [guid]::NewGuid()
    New-RsRestFolder -ReportPortalUri $reportPortalUri -Path / -FolderName $folderName
    $folderPath = '/' + $folderName
    $sqlPowerBiReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\SqlPowerBIReport.pbix'
    Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $sqlPowerBiReportPath -RsFolder $folderPath

    Context "ReportPortalUri parameter" {
        It "Should fetch data sources" {
            $report = Get-RsRestItemDataSources -ReportPortalUri $reportPortalUri -RsItem "$folderPath/SqlPowerBIReport" -Verbose
            $report.DataSources | Should Not BeNullOrEmpty
            $report.DataSources[0].ConnectionString | Should Be "localhost;ReportServer"
            $report.DataSources[0].DataModelDataSource | Should Not BeNullOrEmpty
            $report.DataSources[0].DataModelDataSource.Type | Should Be "Import"
            $report.DataSources[0].DataModelDataSource.Kind | Should Be "Sql"
            $report.DataSources[0].DataModelDataSource.AuthType | Should Be "Windows"
        }
    }

    Context "WebSession parameter" {
        $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri

        It "Should fetch data sources" {
            $report = Get-RsRestItemDataSources -WebSession $webSession -RsItem "$folderPath/SqlPowerBIReport" -Verbose
            $report.DataSources | Should Not BeNullOrEmpty
            $report.DataSources[0].ConnectionString | Should Be "localhost;ReportServer"
            $report.DataSources[0].DataModelDataSource | Should Not BeNullOrEmpty
            $report.DataSources[0].DataModelDataSource.Type | Should Be "Import"
            $report.DataSources[0].DataModelDataSource.Kind | Should Be "Sql"
            $report.DataSources[0].DataModelDataSource.AuthType | Should Be "Windows"
        }
    }
}
