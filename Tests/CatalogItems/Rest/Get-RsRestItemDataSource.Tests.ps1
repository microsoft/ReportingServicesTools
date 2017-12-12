# Copyright (c) 2017 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = if ($env:PesterPortalUrl -eq $null) { 'http://localhost/reports' } else { $env:PesterPortalUrl }
$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

Describe "Get-RsRestItemDataSource" {
    $session = $null
    $rsFolderPath = ""
    $datasourcesReport = ""
    $sqlPowerBIReport = ""

    BeforeEach {
        $session = New-RsRestSession -ReportPortalUri $reportPortalUri

        # creating test folder
        $folderName = 'SUT_GetRsRestItemDataSource_' + [guid]::NewGuid()
        New-RsRestFolder -WebSession $session -RsFolder / -FolderName $folderName
        $rsFolderPath = '/' + $folderName

        # uploading test artifacts: datasourcesReport.rdl and SqlPowerBIReport.pbix
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsRestCatalogItem -WebSession $session -Path "$localPath\datasources\datasourcesReport.rdl" -RsFolder $rsFolderPath
        $datasourcesReport =  "$rsFolderPath/datasourcesReport"

        Write-RsRestCatalogItem -WebSession $session -Path "$localPath\SqlPowerBIReport.pbix" -RsFolder $rsFolderPath
        $sqlPowerBIReport = "$rsFolderPath/SqlPowerBIReport"
    }

    AfterEach {
        # deleting test folder
        Remove-RsRestFolder -WebSession $session -RsFolder $rsFolderPath -Confirm:$false
    }

    Context "ReportPortalUri parameter" {
        It "fetches data sources for paginated reports" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport -Verbose
            $datasources.Count | Should Be 2
            $datasources[0].DataSourceType | Should Be "SQL"
            $datasources[0].DataSourceSubType | Should BeNullOrEmpty 
            $datasources[0].ConnectionString | Should Be "Data Source=localhost;Initial Catalog=master"
            $datasources[1].DataSourceType | Should Be "SQL"
            $datasources[1].DataSourceSubType | Should BeNullOrEmpty
            $datasources[1].ConnectionString | Should Be "Data Source=localhost;Initial Catalog=model"
        }

        It "fetches data sources for power bi reports" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport -Verbose
            $datasources.GetType() | Should BeOfType System.Object
            $datasources.DataSourceSubType | Should Be "DataModel"
            $datasources.ConnectionString | Should Be "localhost;ReportServer"
        }
    }

    Context "WebSession parameter" {
        $rsSession = $null

        BeforeEach {
            $rsSession = New-RsRestSession -ReportPortalUri $reportPortalUri
        }

        It "fetches data sources for paginated reports" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport -Verbose
            $datasources.Count | Should Be 2
            $datasources[0].DataSourceType | Should Be "SQL"
            $datasources[0].DataSourceSubType | Should BeNullOrEmpty 
            $datasources[0].ConnectionString | Should Be "Data Source=localhost;Initial Catalog=master"
            $datasources[1].DataSourceType | Should Be "SQL"
            $datasources[1].DataSourceSubType | Should BeNullOrEmpty
            $datasources[1].ConnectionString | Should Be "Data Source=localhost;Initial Catalog=model"
        }

        It "fetches data sources for power bi reports" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $sqlPowerBIReport -Verbose
            $datasources.GetType() | Should BeOfType System.Object
            $datasources.DataSourceSubType | Should Be "DataModel"
            $datasources.ConnectionString | Should Be "localhost;ReportServer"
        }
    }
}