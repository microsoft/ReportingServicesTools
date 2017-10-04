# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Function Set-FolderReportDataSource {
    param (
        [string]
        $NewFolderPath
    )
    
    $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
    $null = Write-RsCatalogItem -Path $localResourcesPath -RsFolder $NewFolderPath
    $report = (Get-RsFolderContent -RsFolder $NewFolderPath )| Where-Object TypeName -eq 'Report'

    $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\UnDataset.rsd'
    $null = Write-RsCatalogItem -Path $localResourcesPath -RsFolder $NewFolderPath
    $dataSet = (Get-RsFolderContent -RsFolder $NewFolderPath ) | Where-Object TypeName -eq 'DataSet'
    $DataSetPath = $NewFolderPath + '/UnDataSet'
                
    $newRSDSName = "DataSource"
    $newRSDSExtension = "SQL"
    $newRSDSConnectionString = "Initial Catalog=DB; Data Source=Instance"
    $newRSDSCredentialRetrieval = "Store"

    #Dummy credentials
    $Pass = ConvertTo-SecureString -String "123" -AsPlainText -Force
    $newRSDSCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "sql", $Pass
    $null = New-RsDataSource -RsFolder $NewFolderPath -Name $newRSDSName -Extension $newRSDSExtension -ConnectionString $newRSDSConnectionString -CredentialRetrieval $newRSDSCredentialRetrieval -DatasourceCredentials $newRSDSCredential

    $DataSourcePath = "$NewFolderPath/$newRSDSName"

    $RsDataSet = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSet'
    $RsDataSource = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSource'
    $RsDataSetSource = Get-RsItemReference -Path $DataSetPath | Where-Object ReferenceType -eq 'DataSource'

    #Set data source and data set for all objects
    $null = Set-RsDataSourceReference -Path $DataSetPath -DataSourceName $RsDataSetSource.Name -DataSourcePath $DataSourcePath
    $null = Set-RsDataSourceReference -Path $report.Path -DataSourceName $RsDataSource.Name -DataSourcePath $DataSourcePath
    $null = Set-RsDataSetReference -Path $report.Path -DataSetName $RsDataSet.Name -DataSetPath $dataSet.Path

    return $report
}

Function New-RsScheduleXML {
    Return '<ScheduleDefinition><StartDateTime>2017-10-04T09:38:34</StartDateTime><WeeklyRecurrence><WeeksInterval>1</WeeksInterval><DaysOfWeek><Monday>True</Monday><Tuesday>True</Tuesday><Wednesday>True</Wednesday><Thursday>True</Thursday><Friday>True</Friday></DaysOfWeek></WeeklyRecurrence></ScheduleDefinition>'
}


Describe 'New-RsSubscription' {

    Context 'New-RsSubscription FileShare Subscription' {

        $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
        $null = New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName

        $newReport = Set-FolderReportDataSource($folderPath)

        New-RsSubscription -Path $newReport.Path -Destination 'FileShare' -DestinationPath '\\some\path' -FileName 'file.pdf' -RenderFormat PDF -Schedule (New-RsScheduleXML)
                
        $reportSubscriptions = Get-RsSubscription -Path $newReport.Path

        It 'Should create a new subscription' {
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
        }

        Remove-RsCatalogItem -RsFolder $folderPath
    }

    Context 'New-RsSubscription FileShare Subscription with Proxy parameter' {

        $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
        $null = New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName

        $proxy = New-RsWebServiceProxy

        $newReport = Set-FolderReportDataSource($folderPath)

        New-RsSubscription -Path $newReport.Path -Destination 'FileShare' -DestinationPath '\\some\path' -FileName 'file.pdf' -RenderFormat PDF -Schedule (New-RsScheduleXML) -Proxy $proxy
                
        $reportSubscriptions = Get-RsSubscription -Path $newReport.Path

        It 'Should create a new subscription' {
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
        }

        Remove-RsCatalogItem -RsFolder $folderPath
    }
        
    Context 'New-RsSubscription FileShare Subscription with ReportServerUri Parameter' {

        $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
        $null = New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName

        $reportServerUri = 'http://localhost/reportserver'

        $newReport = Set-FolderReportDataSource($folderPath)

        New-RsSubscription -Path $newReport.Path -Destination 'FileShare' -DestinationPath '\\some\path' -FileName 'file.pdf' -RenderFormat PDF -Schedule (New-RsScheduleXML) -ReportServerUri $ReportServerUri
                
        $reportSubscriptions = Get-RsSubscription -Path $newReport.Path

        It 'Should create a new subscription' {
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
        }

        Remove-RsCatalogItem -RsFolder $folderPath
    }

    Context 'New-RsSubscription with ReportServerUri and Proxy Parameter' {

        $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
        $null = New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName

        $reportServerUri = 'http://localhost/reportserver'
        $proxy = New-RsWebServiceProxy

        $newReport = Set-FolderReportDataSource($folderPath)

        New-RsSubscription -Path $newReport.Path -Destination 'FileShare' -DestinationPath '\\some\path' -FileName 'file.pdf' -RenderFormat PDF -Schedule (New-RsScheduleXML) -ReportServerUri $ReportServerUri -Proxy $proxy
                
        $reportSubscriptions = Get-RsSubscription -Path $newReport.Path

        It 'Should create a new subscription' {
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
        }

        Remove-RsCatalogItem -RsFolder $folderPath
    }
}