# Copyright (c) 2021 Microsoft Corporation. All Rights Reserved.
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
            
            $TestResponse = Test-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport -Verbose
            $TestResponse[0].ReportName | Should be "datasourcesReport"
            $TestResponse[0].DataSourceName | Should be "master"
            $TestResponse[0].IsSuccessful | Should be "True"
            $TestResponse[0].ErrorMessage | Should be $null
            $TestResponse[1].ReportName | Should be "datasourcesReport"
            $TestResponse[1].DataSourceName | Should be "model"
            $TestResponse[1].IsSuccessful | Should be "True"
            $TestResponse[1].ErrorMessage | Should be $null

        }

        It "tests data sources for power bi reports, and expects failure responses" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport -Verbose
            $datasources.GetType() | Should BeOfType System.Object
            $datasources.DataSourceSubType | Should Be "DataModel"
            $datasources.ConnectionString | Should Be "localhost;ReportServer"

            $TestResponse = Test-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport -Verbose
            $TestResponse.ReportName | Should be "SqlPowerBIReport"
            $TestResponse.IsSuccessful | Should be "False"
            $TestResponse.ErrorMessage | Should be "A user name wasn't specified"
        }

        It "tests data sources for power bi reports, and expects success responses" {
            $datasources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport -Verbose
            $datasources.GetType() | Should BeOfType System.Object
            $datasources.DataSourceSubType | Should Be "DataModel"
            $datasources.ConnectionString | Should Be "localhost;ReportServer"

            $dataSources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport -Verbose
            $dataSources[0].DataModelDataSource.AuthType = 'UsernamePassword'
            $dataSources[0].DataModelDataSource.Username = 'sa'
            $dataSources[0].DataModelDataSource.Secret = 'i<3ReportingServices'
            Set-RsRestItemDataSource -RsItem $sqlPowerBIReport -ReportPortalUri $reportPortalUri -DataSources $dataSources -RsItemType 'PowerBIReport'

            $TestResponse = Test-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport -Verbose
            $TestResponse.ReportName | Should be "SqlPowerBIReport"
            $TestResponse.IsSuccessful | Should be "True"
            $TestResponse.ErrorMessage | Should be $null

        }
    }

    Context "WebSession parameter" {
        $rsSession = $null

        BeforeEach {
            $rsSession = New-RsRestSession -ReportPortalUri $reportPortalUri
        }

        It "tests data sources for power bi reports, and expects failure responses" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $datasourcesReport -Verbose
            $datasources.Count | Should Be 2
            $datasources[0].DataSourceType | Should Be "SQL"
            $datasources[0].DataSourceSubType | Should BeNullOrEmpty 
            $datasources[0].ConnectionString | Should Be "Data Source=localhost;Initial Catalog=master"
            $datasources[1].DataSourceType | Should Be "SQL"
            $datasources[1].DataSourceSubType | Should BeNullOrEmpty
            $datasources[1].ConnectionString | Should Be "Data Source=localhost;Initial Catalog=model"
            
            $TestResponse = Test-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $datasourcesReport -Verbose
            $TestResponse[0].ReportName | Should be "datasourcesReport"
            $TestResponse[0].DataSourceName | Should be "master"
            $TestResponse[0].IsSuccessful | Should be "True"
            $TestResponse[0].ErrorMessage | Should be $null
            $TestResponse[1].ReportName | Should be "datasourcesReport"
            $TestResponse[1].DataSourceName | Should be "model"
            $TestResponse[1].IsSuccessful | Should be "True"
            $TestResponse[1].ErrorMessage | Should be $null
        }

        It "fetches data sources for power bi reports" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $sqlPowerBIReport -Verbose
            $datasources.GetType() | Should BeOfType System.Object
            $datasources.DataSourceSubType | Should Be "DataModel"
            $datasources.ConnectionString | Should Be "localhost;ReportServer"

            $TestResponse = Test-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport -Verbose
            $TestResponse.ReportName | Should be "SqlPowerBIReport"
            $TestResponse.IsSuccessful | Should be "False"
            $TestResponse.ErrorMessage | Should be "A user name wasn't specified"
        }

        It "tests data sources for power bi reports, and expects success responses" {
            $datasources = Get-RsRestItemDataSource -WebSession $rsSession -RsItem $sqlPowerBIReport -Verbose
            $datasources.GetType() | Should BeOfType System.Object
            $datasources.DataSourceSubType | Should Be "DataModel"
            $datasources.ConnectionString | Should Be "localhost;ReportServer"

            $dataSources = Get-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport -Verbose
            $dataSources[0].DataModelDataSource.AuthType = 'UsernamePassword'
            $dataSources[0].DataModelDataSource.Username = 'sa'
            $dataSources[0].DataModelDataSource.Secret = 'i<3ReportingServices'
            Set-RsRestItemDataSource -RsItem $sqlPowerBIReport -ReportPortalUri $reportPortalUri -DataSources $dataSources -RsItemType 'PowerBIReport'

            $TestResponse = Test-RsRestItemDataSource -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport -Verbose
            $TestResponse.ReportName | Should be "SqlPowerBIReport"
            $TestResponse.IsSuccessful | Should be "True"
            $TestResponse.ErrorMessage | Should be $null
        }
    }
}