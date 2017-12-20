# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

#Not in use right now - need email configuration on the report server
Function New-InMemoryEmailSubscription
{

    [xml]$matchData = '<?xml version="1.0" encoding="utf-16" standalone="yes"?><ScheduleDefinition xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><StartDateTime xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer">2017-07-14T08:00:00.000+01:00</StartDateTime><WeeklyRecurrence xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer"><WeeksInterval>1</WeeksInterval><DaysOfWeek><Monday>true</Monday><Tuesday>true</Tuesday><Wednesday>true</Wednesday><Thursday>true</Thursday><Friday>true</Friday></DaysOfWeek></WeeklyRecurrence></ScheduleDefinition>'

    $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
    $namespace = $proxy.GetType().NameSpace

    $ExtensionSettingsDataType = "$namespace.ExtensionSettings"
    $ParameterValueOrFieldReference = "$namespace.ParameterValueOrFieldReference[]"
    $ParameterValueDataType = "$namespace.ParameterValue"

    #Set ExtensionSettings
    $ExtensionSettings = New-Object $ExtensionSettingsDataType
                    
    $ExtensionSettings.Extension = "Report Server Email"

    #Set ParameterValues
    $ParameterValues = New-Object $ParameterValueOrFieldReference -ArgumentList 8

    $to = New-Object $ParameterValueDataType
    $to.Name = "TO";
    $to.Value = "mail@rstools.com"; 
    $ParameterValues[0] = $to;

    $replyTo = New-Object $ParameterValueDataType
    $replyTo.Name = "ReplyTo";
    $replyTo.Value ="dank@rstools.com";
    $ParameterValues[1] = $replyTo;

    $includeReport = New-Object $ParameterValueDataType
    $includeReport.Name = "IncludeReport";
    $includeReport.Value = "False";
    $ParameterValues[2] = $includeReport;

    $renderFormat = New-Object $ParameterValueDataType
    $renderFormat.Name = "RenderFormat";
    $renderFormat.Value = "MHTML";
    $ParameterValues[3] = $renderFormat;

    $priority = New-Object $ParameterValueDataType
    $priority.Name = "Priority";
    $priority.Value = "NORMAL";
    $ParameterValues[4] = $priority;

    $subject = New-Object $ParameterValueDataType
    $subject.Name = "Subject";
    $subject.Value = "Your sales report";
    $ParameterValues[5] = $subject;

    $comment = New-Object $ParameterValueDataType
    $comment.Name = "Comment";
    $comment.Value = "Here is the link to your report.";
    $ParameterValues[6] = $comment;

    $includeLink = New-Object $ParameterValueDataType
    $includeLink.Name = "IncludeLink";
    $includeLink.Value = "True";
    $ParameterValues[7] = $includeLink;

    $ExtensionSettings.ParameterValues = $ParameterValues

    $subscription = [pscustomobject]@{
        DeliverySettings      = $ExtensionSettings
        Description           = "Send email to mail@rstools.com"
        EventType             = "TimedSubscription"
        IsDataDriven          = $false
        MatchData             = $matchData.OuterXml
        Values                = $null
    }
    
    return $subscription
}

Function New-InMemoryFileShareSubscription
{
    [xml]$matchData = '<?xml version="1.0" encoding="utf-16" standalone="yes"?><ScheduleDefinition xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><StartDateTime xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer">2017-07-14T08:00:00.000+01:00</StartDateTime><WeeklyRecurrence xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer"><WeeksInterval>1</WeeksInterval><DaysOfWeek><Monday>true</Monday><Tuesday>true</Tuesday><Wednesday>true</Wednesday><Thursday>true</Thursday><Friday>true</Friday></DaysOfWeek></WeeklyRecurrence></ScheduleDefinition>'

    $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
    $namespace = $proxy.GetType().NameSpace

    $ExtensionSettingsDataType = "$namespace.ExtensionSettings"
    $ParameterValueOrFieldReference = "$namespace.ParameterValueOrFieldReference[]"
    $ParameterValueDataType = "$namespace.ParameterValue"

    #Set ExtensionSettings
    $ExtensionSettings = New-Object $ExtensionSettingsDataType
    $ExtensionSettings.Extension = "Report Server FileShare"

    #Set ParameterValues
    $ParameterValues = New-Object $ParameterValueOrFieldReference -ArgumentList 7

    $to = New-Object $ParameterValueDataType
    $to.Name = "PATH";
    $to.Value = "\\unc\path"; 
    $ParameterValues[0] = $to;

    $replyTo = New-Object $ParameterValueDataType
    $replyTo.Name = "FILENAME";
    $replyTo.Value ="Report";
    $ParameterValues[1] = $replyTo;

    $includeReport = New-Object $ParameterValueDataType
    $includeReport.Name = "FILEEXTN";
    $includeReport.Value = "True";
    $ParameterValues[2] = $includeReport;

    $renderFormat = New-Object $ParameterValueDataType
    $renderFormat.Name = "USERNAME";
    $renderFormat.Value = "user";
    $ParameterValues[3] = $renderFormat;

    $priority = New-Object $ParameterValueDataType
    $priority.Name = "RENDER_FORMAT";
    $priority.Value = "PDF";
    $ParameterValues[4] = $priority;

    $subject = New-Object $ParameterValueDataType
    $subject.Name = "WRITEMODE";
    $subject.Value = "Overwrite";
    $ParameterValues[5] = $subject;

    $comment = New-Object $ParameterValueDataType
    $comment.Name = "DEFAULTCREDENTIALS";
    $comment.Value = "False";
    $ParameterValues[6] = $comment;

    $ExtensionSettings.ParameterValues = $ParameterValues

    $subscription = [pscustomobject]@{
        DeliverySettings      = $ExtensionSettings
        Description           = "Shared on \\unc\path"
        EventType             = "TimedSubscription"
        IsDataDriven          = $false
        MatchData             = $matchData.OuterXml
        Values                = $null
    }
    
    return $subscription
}

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

Describe "Copy-RsSubscription" {
    $folderPath = ''
    $newReport = $null
    $subscription = $null

    BeforeEach {
        $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
        $null = New-RsFolder -Path / -FolderName $folderName -ReportServerUri $reportServerUri
        $folderPath = '/' + $folderName

        # upload test reports and initialize data sources/data sets
        $newReport = Set-FolderReportDataSource($folderPath)

        # create a test subscription
        $subscription = New-InMemoryFileShareSubscription
    }

    AfterEach {
        Remove-RsCatalogItem -RsFolder $folderPath -ReportServerUri $reportServerUri -Confirm:$false -ErrorAction Continue
    }

    Context "Copy-RsSubscription with Proxy parameter"{
        It "Should set a subscription" {
            $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Copy-RsSubscription -Subscription $subscription -Path $newReport.Path -Proxy $proxy

            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
        }
    }

    Context "Copy-RsSubscription with ReportServerUri Parameter"{
        It "Should set a subscription" {
            Copy-RsSubscription -Subscription $subscription -Path $newReport.Path -ReportServerUri $reportServerUri

            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
        }
    }

    Context "Copy-RsSubscription with ReportServerUri and Proxy Parameter"{
        It "Should set a subscription" {
            $proxy = New-RsWebServiceProxy -ReportServerUri $ReportServerUri
            Copy-RsSubscription -ReportServerUri $ReportServerUri -Subscription $subscription -Path $newReport.Path -Proxy $proxy

            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
        }
    }
}

Describe "Copy-RsSubscription from pipeline" {
    $folderPath = ''
    $newReport = $null
    $subscription = $null

    BeforeEach {
        $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
        $null = New-RsFolder -Path / -FolderName $folderName -ReportServerUri $reportServerUri
        $folderPath = '/' + $folderName

        # upload test reports and initialize data sources/data sets
        $newReport = Set-FolderReportDataSource($folderPath)

        # create a test subscription
        $subscription = New-InMemoryFileShareSubscription
    }

    AfterEach {
        Remove-RsCatalogItem -RsFolder $folderPath -ReportServerUri $reportServerUri -Confirm:$false -ErrorAction Continue
    }

    Context "Copy-RsSubscription from pipeline with Proxy parameter"{
        It "Should set a subscription" {
            $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

            # Copy first subscription
            Copy-RsSubscription -Subscription $subscription -Path $newReport.Path -Proxy $proxy

            # Duplicate subscription
            Get-RsSubscription -Path $newReport.Path -Proxy $proxy | Copy-RsSubscription -Path $newReport.Path -Proxy $proxy

            # Get both subscription
            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 2
            ($reportSubscriptions | Select-Object SubscriptionId -Unique).Count | Should Be 2
        }
    }

    Context "Copy-RsSubscription from pipeline with ReportServerUri Parameter"{
        It "Should copy a subscription" {
            # Copy first subscription
            Copy-RsSubscription -Subscription $subscription -Path $newReport.Path -ReportServerUri $reportServerUri

            # Duplicate subscription
            Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri | Copy-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri

            # Get both subscription
            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 2
            ($reportSubscriptions | Select-Object SubscriptionId -Unique).Count | Should Be 2
        }
    }

    Context "Copy-RsSubscription from pipeline with ReportServerUri and Proxy Parameter"{
        It "Should copy a subscription" {
            $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

            # Copy first subscription
            Copy-RsSubscription -Subscription $subscription -Path $newReport.Path -ReportServerUri $reportServerUri -Proxy $proxy

            # Duplicate subscription
            Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri -Proxy $proxy | Copy-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri -Proxy $proxy

            # Get both subscription
            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 2
            ($reportSubscriptions | Select-Object SubscriptionId -Unique).Count | Should Be 2
        }
    }

    Context "Copy-RsSubscription from pipeline with input from disk"{
        It "Should copy a subscription" {
            $TestPath = 'TestDrive:\Subscription.xml'
            $subscription | Export-RsSubscriptionXml $TestPath
            $subscriptionFromDisk = Import-RsSubscriptionXml $TestPath -ReportServerUri $reportServerUri

            $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

            # Copy first subscription
            Copy-RsSubscription -Subscription $subscriptionFromDisk -Path $newReport.Path -ReportServerUri $reportServerUri -Proxy $proxy

            # Duplicate subscription
            Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri -Proxy $proxy | Copy-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri -Proxy $proxy

            # Get both subscription
            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 2
            ($reportSubscriptions | Select-Object SubscriptionId -Unique).Count | Should Be 2
        }
    }
}
