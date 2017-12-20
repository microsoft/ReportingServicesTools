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

Describe "Remove-RsSubscription" {
    $folderPath = ''
    $report = $null

    BeforeEach {
        $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName -ReportServerUri $reportServerUri
        $folderPath = '/' + $folderName

        # upload test reports and initialize data sources/data sets
        $report = Set-FolderReportDataSource($folderPath)

        # create a test subscription
        New-RsSubscription -ReportServerUri $reportServerUri -RsItem $report.Path -DeliveryMethod FileShare -Schedule (New-RsScheduleXml) -FileSharePath '\\unc\path' -Filename 'Report' -FileWriteMode Overwrite -RenderFormat PDF
    }

    AfterEach {
        Remove-RsCatalogItem -RsFolder $folderPath -ReportServerUri $reportServerUri -Confirm:$false
    }

    Context "Remove-RsSubscription with Proxy parameter" {
        It "Should remove a subscription" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            $reportSubscriptions = Get-RsSubscription -Path $report.Path -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 1

            Remove-RsSubscription -SubscriptionID $reportSubscriptions.SubscriptionID -Proxy $rsProxy -Confirm:$false

            $reportSubscriptions = Get-RsSubscription -Path $report.Path -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 0
        }

        It "Should remove all subscriptions" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

            # creating an additional subscription
            New-RsSubscription -Proxy $rsProxy -RsItem $report.Path -DeliveryMethod FileShare -Schedule (New-RsScheduleXml) -FileSharePath '\\unc\path' -Filename 'Report' -FileWriteMode Overwrite -RenderFormat PDF

            $reportSubscriptions = Get-RsSubscription -Path $report.Path -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 2

            Remove-RsSubscription -Subscription $reportSubscriptions -Proxy $rsProxy -Confirm:$false

            $reportSubscriptions = Get-RsSubscription -Path $report.Path -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 0
        }
    }

    Context "Remove-RsSubscription with ReportServerUri parameter" {
        It "Should remove a subscription" {
            $reportSubscriptions = Get-RsSubscription -Path $report.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1

            Remove-RsSubscription -SubscriptionID $reportSubscriptions.SubscriptionID -ReportServerUri $reportServerUri -Confirm:$false

            $reportSubscriptions = Get-RsSubscription -Path $report.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 0
        }

        It "Should remove all subscriptions" {
            # creating an additional subscription
            New-RsSubscription -ReportServerUri $reportServerUri -RsItem $report.Path -DeliveryMethod FileShare -Schedule (New-RsScheduleXml) -FileSharePath '\\unc\path' -Filename 'Report' -FileWriteMode Overwrite -RenderFormat PDF

            $reportSubscriptions = Get-RsSubscription -Path $report.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 2

            Remove-RsSubscription -Subscription $reportSubscriptions -ReportServerUri $reportServerUri -Confirm:$false

            $reportSubscriptions = Get-RsSubscription -Path $report.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 0
        }
    }

    Context "Remove-RsSubscription with ReportServerUri and Proxy Parameter" {
        It "Should remove a subscription" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            $reportSubscriptions = Get-RsSubscription -Path $report.Path -ReportServerUri $reportServerUri -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 1

            Remove-RsSubscription -SubscriptionID $reportSubscriptions.SubscriptionID -ReportServerUri $reportServerUri -Proxy $rsProxy -Confirm:$false

            $reportSubscriptions = Get-RsSubscription -Path $report.Path -ReportServerUri $reportServerUri -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 0
        }

        It "Should remove all subscriptions" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

            # creating an additional subscription
            New-RsSubscription -ReportServerUri $reportServerUri -Proxy $rsProxy -RsItem $report.Path -DeliveryMethod FileShare -Schedule (New-RsScheduleXml) -FileSharePath '\\unc\path' -Filename 'Report' -FileWriteMode Overwrite -RenderFormat PDF

            $reportSubscriptions = Get-RsSubscription -Path $report.Path -ReportServerUri $reportServerUri -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 2

            Remove-RsSubscription -Subscription $reportSubscriptions -ReportServerUri $reportServerUri -Proxy $rsProxy -Confirm:$false

            $reportSubscriptions = Get-RsSubscription -Path $report.Path -ReportServerUri $reportServerUri -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 0
        }
    }
}