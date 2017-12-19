# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

Function Set-FolderReportDataSource {
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

Function New-RsScheduleXML {
    Return '<ScheduleDefinition><StartDateTime>2017-10-04T09:38:34</StartDateTime><WeeklyRecurrence><WeeksInterval>1</WeeksInterval><DaysOfWeek><Monday>True</Monday><Tuesday>True</Tuesday><Wednesday>True</Wednesday><Thursday>True</Thursday><Friday>True</Friday></DaysOfWeek></WeeklyRecurrence></ScheduleDefinition>'
}


Describe 'New-RsSubscription' {
    $folderPath = ''
    $newReport = $null

    BeforeEach {
        $folderName = 'SutNewRsSubscription_' + [guid]::NewGuid()
        $null = New-RsFolder -Path / -FolderName $folderName -ReportServerUri $reportServerUri
        $folderPath = '/' + $folderName
        $newReport = Set-FolderReportDataSource($folderPath)
    }

    AfterEach {
        Remove-RsCatalogItem -RsFolder $folderPath -ReportServerUri $reportServerUri -Confirm:$false -ErrorAction Continue
    }

    Context 'New-RsSubscription FileShare Subscription with Proxy parameter' {
        It 'Should create a new fileshare subscription' {
            $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            New-RsSubscription -RsItem $newReport.Path -DeliveryMethod 'FileShare' -FileSharePath '\\some\path' -FileName 'file.pdf' -RenderFormat PDF -Schedule (New-RsScheduleXML) -Proxy $proxy
            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri

            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
        }
    }

    Context 'New-RsSubscription FileShare Subscription with ReportServerUri Parameter' {
        It 'Should create a new fileshare subscription' {
            New-RsSubscription -RsItem $newReport.Path -DeliveryMethod 'FileShare' -FileSharePath '\\some\path' -FileName 'file.pdf' -RenderFormat PDF -Schedule (New-RsScheduleXML) -ReportServerUri $reportServerUri
            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri

            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
        }
    }

    Context 'New-RsSubscription with ReportServerUri and Proxy Parameter' {
        It 'Should create a new subscription' {
            $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            New-RsSubscription -RsItem $newReport.Path -DeliveryMethod 'FileShare' -FileSharePath '\\some\path' -FileName 'file.pdf' -RenderFormat PDF -Schedule (New-RsScheduleXML) -ReportServerUri $reportServerUri -Proxy $proxy
            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri

            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
        }
    }
}