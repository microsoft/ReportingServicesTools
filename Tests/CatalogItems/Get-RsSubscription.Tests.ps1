# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

#Not in use right now - need email configuration on the report server
Function Get-NewEmailSubscription
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

Describe "Get-RsSubscription" {
        Context "Get-RsSubscription without parameters"{
                $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
                Write-RsCatalogItem -Path $localResourcesPath -RsFolder $folderPath
                $report = (Get-RsFolderContent -RsFolder $folderPath )| Where-Object TypeName -eq 'Report'
                
                Set-RsEmailSettings -SmtpServer "mail.rstools.com" -Authentication None -SenderAddress "mail@rstools.com" -ReportServerInstance PBIRS

                $subscription = Get-NewEmailSubscription
               

                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\UnDataset.rsd'
                Write-RsCatalogItem -Path $localResourcesPath -RsFolder $folderPath
                $dataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
                $DataSetPath = $folderPath + '/UnDataSet'
                
                $newRSDSName = "DataSource"
                $newRSDSExtension = "SQL"
                $newRSDSConnectionString = "Initial Catalog=DB; Data Source=Instance"
                $newRSDSCredentialRetrieval = "Store"
                #Dummy credentials
                $Pass = ConvertTo-SecureString -String "123" -AsPlainText -Force
                $newRSDSCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "sql", $Pass
                New-RsDataSource -RsFolder $folderPath -Name $newRSDSName -Extension $newRSDSExtension -ConnectionString $newRSDSConnectionString -CredentialRetrieval $newRSDSCredentialRetrieval -DatasourceCredentials $newRSDSCredential

                $DataSourcePath = "$folderPath/$newRSDSName"

                $RsDataSet = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSet'
                $RsDataSource = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSource'
                $RsDataSetSource = Get-RsItemReference -Path $DataSetPath | Where-Object ReferenceType -eq 'DataSource'

                #Set data source and data set for all objects
                Set-RsDataSourceReference -Path $DataSetPath -DataSourceName $RsDataSetSource.Name -DataSourcePath $DataSourcePath
                Set-RsDataSourceReference -Path $report.Path -DataSourceName $RsDataSource.Name -DataSourcePath $DataSourcePath
                Set-RsDataSetReference -Path $report.Path -DataSetName $RsDataSet.Name -DataSetPath $dataSet.Path

                Set-RsSubscription -Subscription $subscription -Path $report.Path

                $reportSubscriptions = Get-RsSubscription -Path $report.Path

                It "Should found a reference to a subscription" {
                   @($reportSubscriptions).Count | Should Be 1
                   $reportSubscriptions.Report | Should Be "emptyReport"
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }
        
        Context "Get-RsSubscription with Proxy parameter"{
                $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
                Write-RsCatalogItem -Path $localResourcesPath -RsFolder $folderPath
                $report = (Get-RsFolderContent -RsFolder $folderPath )| Where-Object TypeName -eq 'Report'
                $subscription = Get-NewFileShareSubscription
        
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\UnDataset.rsd'
                Write-RsCatalogItem -Path $localResourcesPath -RsFolder $folderPath
                $dataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
                $DataSetPath = $folderPath + '/UnDataSet'
                
                $newRSDSName = "DataSource"
                $newRSDSExtension = "SQL"
                $newRSDSConnectionString = "Initial Catalog=DB; Data Source=Instance"
                $newRSDSCredentialRetrieval = "Store"
                #Dummy credentials
                $Pass = ConvertTo-SecureString -String "123" -AsPlainText -Force
                $newRSDSCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "sql", $Pass
                New-RsDataSource -RsFolder $folderPath -Name $newRSDSName -Extension $newRSDSExtension -ConnectionString $newRSDSConnectionString -CredentialRetrieval $newRSDSCredentialRetrieval -DatasourceCredentials $newRSDSCredential
        
                $DataSourcePath = "$folderPath/$newRSDSName"
        
                $RsDataSet = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSet'
                $RsDataSource = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSource'
                $RsDataSetSource = Get-RsItemReference -Path $DataSetPath | Where-Object ReferenceType -eq 'DataSource'
        
                #Set data source and data set for all objects
                Set-RsDataSourceReference -Path $DataSetPath -DataSourceName $RsDataSetSource.Name -DataSourcePath $DataSourcePath
                Set-RsDataSourceReference -Path $report.Path -DataSourceName $RsDataSource.Name -DataSourcePath $DataSourcePath
                Set-RsDataSetReference -Path $report.Path -DataSetName $RsDataSet.Name -DataSetPath $dataSet.Path
                
                $proxy = New-RsWebServiceProxy
                Set-RsSubscription -Subscription $subscription -Path $report.Path -Proxy $proxy
                
                $reportSubscriptions = Get-RsSubscription -Path $report.Path
        
                It "Should found a reference to a subscription" {
                   @($reportSubscriptions).Count | Should Be 1
                   $reportSubscriptions.Report | Should Be "emptyReport"
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }
        
        Context "Get-RsSubscription with ReportServerUri Parameter"{
                $reportServerUri = 'http://localhost/reportserver'
        
                $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
                New-RsFolder -ReportServerUri $ReportServerUri -Path / -FolderName $folderName
                $folderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
                Write-RsCatalogItem -ReportServerUri $ReportServerUri -Path $localResourcesPath -RsFolder $folderPath
                $report = (Get-RsFolderContent -ReportServerUri $ReportServerUri -RsFolder $folderPath )| Where-Object TypeName -eq 'Report'
                $subscription = Get-NewFileShareSubscription
        
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\UnDataset.rsd'
                Write-RsCatalogItem -ReportServerUri $ReportServerUri -Path $localResourcesPath -RsFolder $folderPath
                $dataSet = (Get-RsFolderContent -ReportServerUri $ReportServerUri -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
                $DataSetPath = $folderPath + '/UnDataSet'
                
                $newRSDSName = "DataSource"
                $newRSDSExtension = "SQL"
                $newRSDSConnectionString = "Initial Catalog=DB; Data Source=Instance"
                $newRSDSCredentialRetrieval = "Store"
                #Dummy credentials
                $Pass = ConvertTo-SecureString -String "123" -AsPlainText -Force
                $newRSDSCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "sql", $Pass
                New-RsDataSource -ReportServerUri $reportServerUri -RsFolder $folderPath -Name $newRSDSName -Extension $newRSDSExtension -ConnectionString $newRSDSConnectionString -CredentialRetrieval $newRSDSCredentialRetrieval -DatasourceCredentials $newRSDSCredential
        
                $DataSourcePath = "$folderPath/$newRSDSName"
        
                $RsDataSet = Get-RsItemReference -ReportServerUri $reportServerUri -Path $report.Path | Where-Object ReferenceType -eq 'DataSet'
                $RsDataSource = Get-RsItemReference -ReportServerUri $reportServerUri -Path $report.Path | Where-Object ReferenceType -eq 'DataSource'
                $RsDataSetSource = Get-RsItemReference -ReportServerUri $reportServerUri -Path $DataSetPath | Where-Object ReferenceType -eq 'DataSource'
        
                #Set data source and data set for all objects
                Set-RsDataSourceReference -ReportServerUri $reportServerUri -Path $DataSetPath -DataSourceName $RsDataSetSource.Name -DataSourcePath $DataSourcePath
                Set-RsDataSourceReference -ReportServerUri $reportServerUri -Path $report.Path -DataSourceName $RsDataSource.Name -DataSourcePath $DataSourcePath
                Set-RsDataSetReference -ReportServerUri $reportServerUri -Path $report.Path -DataSetName $RsDataSet.Name -DataSetPath $dataSet.Path
        
                Set-RsSubscription -Subscription $subscription -Path $report.Path -ReportServerUri $reportServerUri
                
                $reportSubscriptions = Get-RsSubscription -ReportServerUri $ReportServerUri -Path $report.Path
        
                It "Should found a reference to a subscription" {
                   @($reportSubscriptions).Count | Should Be 1
                   $reportSubscriptions.Report | Should Be "emptyReport"
                }
                Remove-RsCatalogItem -ReportServerUri $ReportServerUri -RsFolder $folderPath
        }
        
        Context "Get-RsSubscription with ReportServerUri and Proxy Parameter"{
                $reportServerUri = 'http://localhost/reportserver'
        
                $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
                Write-RsCatalogItem -Path $localResourcesPath -RsFolder $folderPath
                $report = (Get-RsFolderContent -RsFolder $folderPath )| Where-Object TypeName -eq 'Report'
                $subscription = Get-NewFileShareSubscription
        
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\UnDataset.rsd'
                Write-RsCatalogItem -Path $localResourcesPath -RsFolder $folderPath
                $dataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
                $DataSetPath = $folderPath + '/UnDataSet'
                
                $newRSDSName = "DataSource"
                $newRSDSExtension = "SQL"
                $newRSDSConnectionString = "Initial Catalog=DB; Data Source=Instance"
                $newRSDSCredentialRetrieval = "Store"
                #Dummy credentials
                $Pass = ConvertTo-SecureString -String "123" -AsPlainText -Force
                $newRSDSCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "sql", $Pass
                New-RsDataSource -RsFolder $folderPath -Name $newRSDSName -Extension $newRSDSExtension -ConnectionString $newRSDSConnectionString -CredentialRetrieval $newRSDSCredentialRetrieval -DatasourceCredentials $newRSDSCredential
        
                $DataSourcePath = "$folderPath/$newRSDSName"
        
                $RsDataSet = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSet'
                $RsDataSource = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSource'
                $RsDataSetSource = Get-RsItemReference -Path $DataSetPath | Where-Object ReferenceType -eq 'DataSource'
        
                #Set data source and data set for all objects
                Set-RsDataSourceReference -Path $DataSetPath -DataSourceName $RsDataSetSource.Name -DataSourcePath $DataSourcePath
                Set-RsDataSourceReference -Path $report.Path -DataSourceName $RsDataSource.Name -DataSourcePath $DataSourcePath
                Set-RsDataSetReference -Path $report.Path -DataSetName $RsDataSet.Name -DataSetPath $dataSet.Path
                
                $proxy = New-RsWebServiceProxy
                $reportServerUri = 'http://localhost/reportserver'
                Set-RsSubscription -Subscription $subscription -Path $report.Path -ReportServerUri $reportServerUri -Proxy $proxy
                
                $reportSubscriptions = Get-RsSubscription -Path $report.Path
        
                It "Should found a reference to a subscription" {
                   @($reportSubscriptions).Count | Should Be 1
                   $reportSubscriptions.Report | Should Be "emptyReport"
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }
}