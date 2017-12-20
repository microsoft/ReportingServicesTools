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

Describe "Get-RsSubscription" {
    $folderPath = ''
    $newReport = $null

    BeforeEach {
        $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
        $null = New-RsFolder -Path / -FolderName $folderName -ReportServerUri $reportServerUri
        $folderPath = '/' + $folderName

        # upload test reports and initialize data sources/data sets
        $newReport = Set-FolderReportDataSource($folderPath)

        # create a test subscription
        New-RsSubscription -ReportServerUri $reportServerUri -RsItem $newReport.Path -DeliveryMethod FileShare -Schedule (New-RsScheduleXml) -FileSharePath '\\unc\path' -Filename 'Report' -FileWriteMode Overwrite -RenderFormat PDF
    }

    Context "Get-RsSubscription with Proxy parameter"{
        It "Should found a reference to a subscription" {
            $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            $reportSubscriptions = Get-RsSubscription -RsItem $newReport.Path -Proxy $proxy

            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
            $reportSubscriptions.DeliverySettings.Extension | Should Be "Report Server FileShare"
            ($reportSubscriptions.DeliverySettings.ParameterValues | Where-Object { $_.Name -eq 'Path' }).Value | Should Be "\\unc\path"
            ($reportSubscriptions.DeliverySettings.ParameterValues | Where-Object { $_.Name -eq 'FileName' }).Value | Should Be "Report"
            ($reportSubscriptions.DeliverySettings.ParameterValues | Where-Object { $_.Name -eq 'WriteMode' }).Value | Should Be "Overwrite"
            ($reportSubscriptions.DeliverySettings.ParameterValues | Where-Object { $_.Name -eq 'DefaultCredentials' }).Value | Should Be True
        }
    }
    
    Context "Get-RsSubscription with ReportServerUri Parameter"{
        It "Should found a reference to a subscription" {
            $reportSubscriptions = Get-RsSubscription -RsItem $newReport.Path -ReportServerUri $reportServerUri

            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
            $reportSubscriptions.DeliverySettings.Extension | Should Be "Report Server FileShare"
            ($reportSubscriptions.DeliverySettings.ParameterValues | Where-Object { $_.Name -eq 'Path' }).Value | Should Be "\\unc\path"
            ($reportSubscriptions.DeliverySettings.ParameterValues | Where-Object { $_.Name -eq 'FileName' }).Value | Should Be "Report"
            ($reportSubscriptions.DeliverySettings.ParameterValues | Where-Object { $_.Name -eq 'WriteMode' }).Value | Should Be "Overwrite"
            ($reportSubscriptions.DeliverySettings.ParameterValues | Where-Object { $_.Name -eq 'DefaultCredentials' }).Value | Should Be True
        }
    }
    
    Context "Get-RsSubscription with ReportServerUri and Proxy Parameter"{
        It "Should found a reference to a subscription" {
            $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            $reportSubscriptions = Get-RsSubscription -RsItem $newReport.Path -Proxy $proxy -ReportServerUri $reportServerUri

            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
            $reportSubscriptions.DeliverySettings.Extension | Should Be "Report Server FileShare"
            ($reportSubscriptions.DeliverySettings.ParameterValues | Where-Object { $_.Name -eq 'Path' }).Value | Should Be "\\unc\path"
            ($reportSubscriptions.DeliverySettings.ParameterValues | Where-Object { $_.Name -eq 'FileName' }).Value | Should Be "Report"
            ($reportSubscriptions.DeliverySettings.ParameterValues | Where-Object { $_.Name -eq 'WriteMode' }).Value | Should Be "Overwrite"
            ($reportSubscriptions.DeliverySettings.ParameterValues | Where-Object { $_.Name -eq 'DefaultCredentials' }).Value | Should Be True
        }
    }
}