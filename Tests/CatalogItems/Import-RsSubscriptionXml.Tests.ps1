# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

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

Describe 'Import-RsSubscriptionXml' {
    Context 'Import-RsSubscriptionXml' {
        It 'Should import a subscription' {
            $TestPath = 'TestDrive:\Subscription.xml'
            New-InMemoryFileShareSubscription | Export-RsSubscriptionXml $TestPath
            $Result = Import-RsSubscriptionXml $TestPath -ReportServerUri $reportServerUri

            $Result.Description | Should Be 'Shared on \\unc\path'
        }
    }
}