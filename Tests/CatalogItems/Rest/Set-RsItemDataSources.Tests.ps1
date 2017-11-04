# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = 'http://localhost/reports'

Describe "Set-RsItemDataSources" {
    $rsFolderPath = ""

    BeforeEach {
        # creating a folder in RS
        $folderName = 'SUT_SetRsRestItemDataSources_' + [guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -Path / -FolderName $folderName
        $rsFolderPath = '/' + $folderName

        # Uploading a report
        $sqlPowerBiReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\SqlPowerBIReport.pbix'
        Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $sqlPowerBiReportPath -RsFolder $rsFolderPath
    }

    Context "ReportPortalUri parameter" {
        It "Should update data sources" {
            $report = Get-RsRestItemDataSources -ReportPortalUri $reportPortalUri -RsItem "$rsFolderPath/SqlPowerBIReport"
            $report.DataSources[0].DataModelDataSource.Username = "test"
            $report.DataSources[0].DataModelDataSource.Secret = "whatever"
            Set-RsRestItemDataSources -ReportPortalUri $reportPortalUri -RsItem $report -Verbose

            $report = Get-RsRestItemDataSources -ReportPortalUri $reportPortalUri -RsItem "$rsFolderPath/SqlPowerBIReport"
            $report.DataSources | Should Not BeNullOrEmpty
            $report.DataSources[0].ConnectionString | Should Be "localhost;ReportServer"
            $report.DataSources[0].DataModelDataSource | Should Not BeNullOrEmpty
            $report.DataSources[0].DataModelDataSource.Type | Should Be "Import"
            $report.DataSources[0].DataModelDataSource.Kind | Should Be "Sql"
            $report.DataSources[0].DataModelDataSource.AuthType | Should Be "Windows"
            $report.DataSources[0].DataModelDataSource.Username | Should Be "test"
            $report.DataSources[0].DataModelDataSource.Secret | Should BeNullOrEmpty
        }

        It "Should fail on invalid auth type" {
            $report = Get-RsRestItemDataSources -ReportPortalUri $reportPortalUri -RsItem "$rsFolderPath/SqlPowerBIReport"
            $report.DataSources[0].DataModelDataSource.AuthType = "invalid"
            $report.DataSources[0].DataModelDataSource.Username = "test"
            $report.DataSources[0].DataModelDataSource.Secret = "whatever"
            { Set-RsRestItemDataSources -ReportPortalUri $reportPortalUri -RsItem $report -Verbose } | Should Throw
        }
    }

    Context "WebSession parameter" {
        $webSession = $null

        BeforeEach {
            $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri
        }

        It "Should update data sources" {
            $report = Get-RsRestItemDataSources -WebSession $webSession -RsItem "$rsFolderPath/SqlPowerBIReport"
            $report.DataSources[0].DataModelDataSource.Username = "test"
            $report.DataSources[0].DataModelDataSource.Secret = "whatever"
            Set-RsRestItemDataSources -WebSession $webSession -RsItem $report -Verbose

            $report = Get-RsRestItemDataSources -WebSession $webSession -RsItem "$rsFolderPath/SqlPowerBIReport"
            $report.DataSources | Should Not BeNullOrEmpty
            $report.DataSources[0].ConnectionString | Should Be "localhost;ReportServer"
            $report.DataSources[0].DataModelDataSource | Should Not BeNullOrEmpty
            $report.DataSources[0].DataModelDataSource.Type | Should Be "Import"
            $report.DataSources[0].DataModelDataSource.Kind | Should Be "Sql"
            $report.DataSources[0].DataModelDataSource.AuthType | Should Be "Windows"
            $report.DataSources[0].DataModelDataSource.Username | Should Be "test"
            $report.DataSources[0].DataModelDataSource.Secret | Should BeNullOrEmpty
        }

        It "Should fail on invalid auth type" {
            $report = Get-RsRestItemDataSources -WebSession $webSession -RsItem "$rsFolderPath/SqlPowerBIReport"
            $report.DataSources[0].DataModelDataSource.AuthType = "invalid"
            $report.DataSources[0].DataModelDataSource.Username = "test"
            $report.DataSources[0].DataModelDataSource.Secret = "whatever"
            { Set-RsRestItemDataSources -WebSession $webSession -RsItem $report -Verbose } | Should Throw
        }
    }
}
