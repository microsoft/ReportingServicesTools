# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

Function Set-FolderReportDataSource
{
    param (
        [string]
        $NewFolderPath
    )

    $tempProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

    # uploading emptyReport.rdl
    $localResourcesPath = (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
    $null = Write-RsCatalogItem -Path $localResourcesPath -RsFolder $NewFolderPath -Proxy $tempProxy
    $report = (Get-RsFolderContent -RsFolder $NewFolderPath -Proxy $tempProxy)| Where-Object TypeName -eq 'Report'

    # uploading UnDataset.rsd
    $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\UnDataset.rsd'
    $null = Write-RsCatalogItem -Path $localResourcesPath -RsFolder $NewFolderPath -Proxy $tempProxy
    $dataSet = (Get-RsFolderContent -RsFolder $NewFolderPath -Proxy $tempProxy) | Where-Object TypeName -eq 'DataSet'
    $DataSetPath = $NewFolderPath + '/UnDataSet'

    # creating a shared data source with Dummy credentials
    $newRSDSName = "DataSource"
    $newRSDSExtension = "SQL"
    $newRSDSConnectionString = "Initial Catalog=DB; Data Source=Instance"
    $newRSDSCredentialRetrieval = "Store"
    $Pass = ConvertTo-SecureString -String "123" -AsPlainText -Force
    $newRSDSCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "sql", $Pass
    $null = New-RsDataSource -RsFolder $NewFolderPath -Name $newRSDSName -Extension $newRSDSExtension -ConnectionString $newRSDSConnectionString -CredentialRetrieval $newRSDSCredentialRetrieval -DatasourceCredentials $newRSDSCredential -Proxy $tempProxy

    $DataSourcePath = "$NewFolderPath/$newRSDSName"

    # retrieving embedded dataset and datasources
    $RsDataSet = Get-RsItemReference -Path $report.Path -Proxy $tempProxy | Where-Object ReferenceType -eq 'DataSet'
    $RsDataSource = Get-RsItemReference -Path $report.Path -Proxy $tempProxy | Where-Object ReferenceType -eq 'DataSource'
    $RsDataSetSource = Get-RsItemReference -Path $DataSetPath -Proxy $tempProxy | Where-Object ReferenceType -eq 'DataSource'

    # Set data source and data set for all objects
    $null = Set-RsDataSourceReference -Path $DataSetPath -DataSourceName $RsDataSetSource.Name -DataSourcePath $DataSourcePath -Proxy $tempProxy
    $null = Set-RsDataSourceReference -Path $report.Path -DataSourceName $RsDataSource.Name -DataSourcePath $DataSourcePath -Proxy $tempProxy
    $null = Set-RsDataSetReference -Path $report.Path -DataSetName $RsDataSet.Name -DataSetPath $dataSet.Path -Proxy $tempProxy

    return $report
}

Describe "Update-RsSubscription" {
    $folderPath = ''
    $newReport = $null

    BeforeEach {
        $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName -ReportServerUri $reportServerUri
        $folderPath = '/' + $folderName

        # upload test reports and initialize data sources/data sets
        $newReport = Set-FolderReportDataSource($folderPath)

        # create a test subscription
        New-RsSubscription -ReportServerUri $reportServerUri -RsItem $newReport.Path -DeliveryMethod FileShare -Schedule (New-RsScheduleXml) -FileSharePath '\\unc\path' -Filename 'Report' -FileWriteMode Overwrite -RenderFormat PDF
    }

    AfterEach {
        Remove-RsCatalogItem -RsFolder $folderPath -ReportServerUri $reportServerUri -Confirm:$false
    }

    Context "Set-RsSubscription with Proxy parameter" {
        BeforeEach {
            Grant-RsSystemRole -Identity 'LOCAL' -RoleName 'System User' -ReportServerUri $reportServerUri
            Grant-RsCatalogItemRole -Identity 'LOCAL' -RoleName 'Browser' -Path $newReport.path -ReportServerUri $reportServerUri
        }

        AfterEach {
            Revoke-RsSystemAccess -Identity 'local' -ReportServerUri $reportServerUri
        }

        It "Updates subscription owner" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy | Set-RsSubscription -Owner "LOCAL" -Proxy $rsProxy

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
            $reportSubscriptions.Owner | Should be "\LOCAL"
        }

        It "Updates StartDateTime parameter" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy | Set-RsSubscription -StartDateTime "1/1/1999 6AM" -Proxy $rsProxy

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false

            [xml]$XMLMatch = $reportSubscriptions.MatchData
            $XMLMatch.ScheduleDefinition.StartDateTime.InnerText | Should be (Get-Date -Year 1999 -Month 1 -Day 1 -Hour 6 -Minute 0 -Second 0 -Millisecond 0 -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
        }

        It "Updates EndDate parameter" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy | Set-RsSubscription -EndDate 1/1/2999 -Proxy $rsProxy

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false

            [xml]$XMLMatch = $reportSubscriptions.MatchData
            $XMLMatch.ScheduleDefinition.EndDate.InnerText | Should be "2999-01-01"
        }

        It "Updates StartDateTime and EndDate parameter" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy | Set-RsSubscription -StartDateTime "1/1/2000 2PM" -EndDate 2/1/2999 -Proxy $rsProxy

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false

            [xml]$XMLMatch = $reportSubscriptions.MatchData
            $XMLMatch.ScheduleDefinition.StartDateTime.InnerText | Should be (Get-Date -Year 2000 -Month 1 -Day 1 -Hour 14 -Minute 0 -Second 0 -Millisecond 0 -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
            $XMLMatch.ScheduleDefinition.EndDate.InnerText | Should Be "2999-02-01"
        }
    }

    Context "Set-RsSubscription with ReportServerUri parameter" {
        BeforeEach {
            Grant-RsSystemRole -Identity 'LOCAL' -RoleName 'System User' -ReportServerUri $reportServerUri
            Grant-RsCatalogItemRole -Identity 'LOCAL' -RoleName 'Browser' -Path $newReport.path -ReportServerUri $reportServerUri
        }

        AfterEach {
            Revoke-RsSystemAccess -Identity 'local' -ReportServerUri $reportServerUri
        }

        It "Updates subscription owner" {
            Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri | Set-RsSubscription -Owner "LOCAL" -ReportServerUri $reportServerUri

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
            $reportSubscriptions.Owner | Should be "\LOCAL"
        }

        It "Updates StartDateTime parameter" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri | Set-RsSubscription -StartDateTime "1/1/1999 6AM" -ReportServerUri $reportServerUri

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false

            [xml]$XMLMatch = $reportSubscriptions.MatchData
            $XMLMatch.ScheduleDefinition.StartDateTime.InnerText | Should be (Get-Date -Year 1999 -Month 1 -Day 1 -Hour 6 -Minute 0 -Second 0 -Millisecond 0 -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
        }

        It "Updates EndDate parameter" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri | Set-RsSubscription -EndDate 1/1/2999 -ReportServerUri $reportServerUri

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false

            [xml]$XMLMatch = $reportSubscriptions.MatchData
            $XMLMatch.ScheduleDefinition.EndDate.InnerText | Should be "2999-01-01"
        }

        It "Updates StartDateTime and EndDate parameter" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri | Set-RsSubscription -StartDateTime "1/1/2000 2PM" -EndDate 2/1/2999 -ReportServerUri $reportServerUri

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false

            [xml]$XMLMatch = $reportSubscriptions.MatchData
            $XMLMatch.ScheduleDefinition.StartDateTime.InnerText | Should be (Get-Date -Year 2000 -Month 1 -Day 1 -Hour 14 -Minute 0 -Second 0 -Millisecond 0 -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
            $XMLMatch.ScheduleDefinition.EndDate.InnerText | Should Be "2999-02-01"
        }
    }
}
