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
        Values                = $null
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
        Values                = $null
    }
    
    return $subscription
}

Describe 'Export-RsSubscriptionXml' {
    
    $TestPath = 'TestDrive:\Subscription.xml'

    Context 'Export-RsSubscriptionXml' {
        
        Get-NewFileShareSubscription | Export-RsSubscriptionXml $TestPath
        $Result = Import-Clixml $TestPath

        It 'Should export a subscription' {
            $TestPath | Should Exist
            $Result.Description | Should Be 'Shared on \\unc\path'
        }
    }
}

