# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

#Not in use right now - need email configuration on the report server
Function Get-NewSubscription
{

    [xml]$matchData = '<?xml version="1.0" encoding="utf-16" standalone="yes"?><ScheduleDefinition xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><StartDateTime xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer">2017-07-14T08:00:00.000+01:00</StartDateTime><WeeklyRecurrence xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer"><WeeksInterval>1</WeeksInterval><DaysOfWeek><Monday>true</Monday><Tuesday>true</Tuesday><Wednesday>true</Wednesday><Thursday>true</Thursday><Friday>true</Friday></DaysOfWeek></WeeklyRecurrence></ScheduleDefinition>'
    
    $proxy = New-RsWebServiceProxy
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
    }
    
    return $subscription
}

Function Get-NewFileShareSubscription
{

    [xml]$matchData = '<?xml version="1.0" encoding="utf-16" standalone="yes"?><ScheduleDefinition xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><StartDateTime xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer">2017-07-14T08:00:00.000+01:00</StartDateTime><WeeklyRecurrence xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer"><WeeksInterval>1</WeeksInterval><DaysOfWeek><Monday>true</Monday><Tuesday>true</Tuesday><Wednesday>true</Wednesday><Thursday>true</Thursday><Friday>true</Friday></DaysOfWeek></WeeklyRecurrence></ScheduleDefinition>'
    
    $proxy = New-RsWebServiceProxy
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
    }
    
    return $subscription
}

Function Set-FolderReportDataSource
{
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

Describe "Set-RsSubscription" {
        Context "Set-RsSubscription without parameters"{
                $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
                $null = New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName

                $newReport = Set-FolderReportDataSource($folderPath)

                $subscription = Get-NewFileShareSubscription

                Set-RsSubscription -Subscription $subscription -Path $newReport.Path
                
                $reportSubscriptions = Get-RsSubscription -Path $newReport.Path

                It "Should set a subscription" {
                   @($reportSubscriptions).Count | Should Be 1
                   $reportSubscriptions.Report | Should Be "emptyReport"
                   $reportSubscriptions.EventType | Should Be "TimedSubscription"
                   $reportSubscriptions.IsDataDriven | Should Be $false
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }
        
        Context "Set-RsSubscription with Proxy parameter"{
                $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
                $null = New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName

                $proxy = New-RsWebServiceProxy

                $newReport = Set-FolderReportDataSource($folderPath)

                $subscription = Get-NewFileShareSubscription
                
                Set-RsSubscription -Subscription $subscription -Path $newReport.Path -Proxy $proxy
                
                $reportSubscriptions = Get-RsSubscription -Path $newReport.Path

                It "Should set a subscription" {
                   @($reportSubscriptions).Count | Should Be 1
                   $reportSubscriptions.Report | Should Be "emptyReport"
                   $reportSubscriptions.EventType | Should Be "TimedSubscription"
                   $reportSubscriptions.IsDataDriven | Should Be $false
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }

        Context "Set-RsSubscription with ReportServerUri Parameter"{
                $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
                $null = New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName
                
                $reportServerUri = 'http://localhost/reportserver'
        
                $newReport = Set-FolderReportDataSource($folderPath)

                $subscription = Get-NewFileShareSubscription
                
                Set-RsSubscription -ReportServerUri $ReportServerUri -Subscription $subscription -Path $newReport.Path
                
                $reportSubscriptions = Get-RsSubscription -Path $newReport.Path

                It "Should set a subscription" {
                   @($reportSubscriptions).Count | Should Be 1
                   $reportSubscriptions.Report | Should Be "emptyReport"
                   $reportSubscriptions.EventType | Should Be "TimedSubscription"
                   $reportSubscriptions.IsDataDriven | Should Be $false
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }

        Context "Set-RsSubscription with ReportServerUri and Proxy Parameter"{
                $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
                $null = New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName
                
                $reportServerUri = 'http://localhost/reportserver'
                $proxy = New-RsWebServiceProxy

                $newReport = Set-FolderReportDataSource($folderPath)

                $subscription = Get-NewFileShareSubscription
                
                Set-RsSubscription -ReportServerUri $ReportServerUri -Subscription $subscription -Path $newReport.Path -Proxy $proxy
                
                $reportSubscriptions = Get-RsSubscription -Path $newReport.Path

                It "Should set a subscription" {
                   @($reportSubscriptions).Count | Should Be 1
                   $reportSubscriptions.Report | Should Be "emptyReport"
                   $reportSubscriptions.EventType | Should Be "TimedSubscription"
                   $reportSubscriptions.IsDataDriven | Should Be $false
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }
}

Describe "Set-RsSubscription from pipeline" {
        Context "Set-RsSubscription from pipeline without parameters"{
                $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
                $null = New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName

                $newReport = Set-FolderReportDataSource($folderPath)

                $subscription = Get-NewFileShareSubscription

                #Set first subscription
                Set-RsSubscription -Subscription $subscription -Path $newReport.Path
                
                # Duplicate subscription
                Get-RsSubscription -Path $newReport.Path | Set-RsSubscription -Path $newReport.Path
                
                # Get both subscription
                $reportSubscriptions = Get-RsSubscription -Path $newReport.Path

                It "Should set a subscription" {
                   @($reportSubscriptions).Count | Should Be 2
                   ($reportSubscriptions | Select-Object SubscriptionId -Unique).Count | Should Be 2
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }

        Context "Set-RsSubscription from pipeline with Proxy parameter"{
                $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
                $null = New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName

                $proxy = New-RsWebServiceProxy

                $newReport = Set-FolderReportDataSource($folderPath)

                $subscription = Get-NewFileShareSubscription

                #Set first subscription
                Set-RsSubscription -Subscription $subscription -Path $newReport.Path -Proxy $proxy
                
                # Duplicate subscription
                Get-RsSubscription -Path $newReport.Path | Set-RsSubscription -Path $newReport.Path
                
                # Get both subscription
                $reportSubscriptions = Get-RsSubscription -Path $newReport.Path

                It "Should set a subscription" {
                  @($reportSubscriptions).Count | Should Be 2
                   ($reportSubscriptions | Select-Object SubscriptionId -Unique).Count | Should Be 2
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }

        Context "Set-RsSubscription from pipeline with ReportServerUri Parameter"{
                $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
                $null = New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName
                
                $reportServerUri = 'http://localhost/reportserver'
        
                $newReport = Set-FolderReportDataSource($folderPath)

                $subscription = Get-NewFileShareSubscription

                #Set first subscription
                Set-RsSubscription -ReportServerUri $reportServerUri -Subscription $subscription -Path $newReport.Path
                
                # Duplicate subscription
                Get-RsSubscription -Path $newReport.Path | Set-RsSubscription -Path $newReport.Path
                
                # Get both subscription
                $reportSubscriptions = Get-RsSubscription -Path $newReport.Path

                It "Should set a subscription" {
                   @($reportSubscriptions).Count | Should Be 2
                   ($reportSubscriptions | Select-Object SubscriptionId -Unique).Count | Should Be 2
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }

        Context "Set-RsSubscription from pipeline with ReportServerUri and Proxy Parameter"{
                $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
                $null = New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName
                
                $reportServerUri = 'http://localhost/reportserver'
                $proxy = New-RsWebServiceProxy

                $newReport = Set-FolderReportDataSource($folderPath)

                $subscription = Get-NewFileShareSubscription

                #Set first subscription
                Set-RsSubscription -ReportServerUri $reportServerUri -Proxy $proxy -Subscription $subscription -Path $newReport.Path
                
                # Duplicate subscription
                Get-RsSubscription -Path $newReport.Path | Set-RsSubscription -Path $newReport.Path
                
                # Get both subscription
                $reportSubscriptions = Get-RsSubscription -Path $newReport.Path

                It "Should set a subscription" {
                   @($reportSubscriptions).Count | Should Be 2
                   ($reportSubscriptions | Select-Object SubscriptionId -Unique).Count | Should Be 2
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }
}