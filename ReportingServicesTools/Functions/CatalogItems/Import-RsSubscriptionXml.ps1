# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Import-RsSubscriptionXml {
    <#
        .SYNOPSIS
            This script imports a subscription that has been exported e.g via Get-RsSubscription | Export-RsSubscriptionXml .\somepath.xml

        .DESCRIPTION
            This script imports a subscription and rebuilds the SRSS specific properties so that the resultant object will be accepted by Set-RsSubscription.
            This is useful if you need to store your subscription configs in a file (e.g to add to source control) and then later want to use that file to
            recreate your subscriptions.

        .PARAMETER Path
            The path to the XML file that contains the exported subscription. 
            This is typically a file created by executing Get-RsSubscription | Export-RsSubscriptionXml .\somepath.xml

        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.

        .EXAMPLE
            Import-RsSubscriptionXml .\MySubscriptions.xml

            Description
            -----------
            This command will import the subscriptions contained in .\MySubscriptions.xml, recreate any SRSS specific properties
            and output a PowerShell object with the result.

        .EXAMPLE
            Import-RsSubscriptionXml .\MySubscriptions.xml | Copy-RsSubscription -RsItem /Example/Report

            Description
            -----------
            This command will import all the subscriptions contained in .\MySubscriptions.xml, recreate any SRSS specific properties
            and pipe the results to Copy-RsSubscription which will add them to the /Example/Report report.
            NOTE: You will need to supply the correct path for the -ReportServerUri parameter to both the Import-RsSubscriptionXml 
            & Copy-RsSubscription functions.  It has been omitted from this example for brevity.

        .EXAMPLE
            Import-RsSubscriptionXml .\MySubscriptions.xml | 
            Out-GridView -PassThru |
            Copy-RsSubscription -RsItem /Example/Report

            Description
            -----------
            This command will import the subscriptions contained in .\MySubscriptions.xml, recreate any SRSS specific properties
            and output a PowerShell object with the result.  The Out-GridView cmdlet allows you to examine and optionally filter the
            subscriptions from the .XML file, before adding them to the report via the Copy-RsSubscription function.
    #>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True,Position=0)]
        [string]
        $Path,

        [string]
        $ReportServerUri,

        [System.Management.Automation.PSCredential]
        $Credential,

        $Proxy
    )

    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        $Namespace = $Proxy.GetType().NameSpace
    }
    Process
    {
        Write-Verbose "Importing Subscription from $Path..."
        $Subscription = Import-Clixml $Path

        foreach ($Sub in $Subscription) 
        {
            #Recreate .DeliverySettings properties as valid SRSS object type
            $ParameterValues = @()

            $Sub.DeliverySettings.ParameterValues | ForEach-Object {
                if ($_.Name)
                {
                    $ParameterValues = $ParameterValues + (New-Object "$Namespace.ParameterValue" -Property @{ Name = $_.Name; Value = $_.Value })
                }
                elseif ($_.ParameterName)
                {
                    $ParameterValues = $ParameterValues + (New-Object "$Namespace.ParameterFieldReference" -Property @{ ParameterName = $_.ParameterName; FieldAlias = $_.FieldAlias })
                }
            }

            $DeliverySettings = @{
                Extension = $Sub.DeliverySettings.Extension
                ParameterValues = $ParameterValues 
            }

            $Sub.DeliverySettings = (New-Object "$Namespace.ExtensionSettings" -Property $DeliverySettings)

            #Recreate .Values property as valid SRSS object type
            $Values = @()

            $Sub.Values | ForEach-Object {

                if ($_.Name)
                {
                    $Values = $Values + (New-Object "$Namespace.ParameterValue" -Property @{ Name = $_.Name; Value = $_.Value })
                }
                elseif ($_.ParameterName)
                {
                    $Values = $Values + (New-Object "$Namespace.ParameterFieldReference" -Property @{ ParameterName = $_.ParameterName; FieldAlias = $_.FieldAlias })
                }
            }
            $Sub.Values = $Values


            #Recreate .DataRetrievalPlan property as valid SRSS object type for Data Driven subscriptions
            if ($Sub.IsDataDriven)
            {
                $DataSetDefinitionFields = @()
                    
                $Sub.DataRetrievalPlan.DataSet.Fields | ForEach-Object {
                    $DataSetDefinitionFields     = $DataSetDefinitionFields + (New-Object "$Namespace.Field" -Property @{ Alias = $_.Alias; Name  = $_.Name })
                }

                $DataSetDefinition = New-Object "$Namespace.DataSetDefinition"
                $DataSetDefinition.Fields = $DataSetDefinitionFields

                $DataSetDefinition.Query = New-Object "$Namespace.QueryDefinition"

                $DataSetDefinition.Query.CommandType            = $sub.DataRetrievalPlan.DataSet.Query.CommandType
                $DataSetDefinition.Query.CommandText            = $sub.DataRetrievalPlan.DataSet.Query.CommandText
                $DataSetDefinition.Query.Timeout                = $sub.DataRetrievalPlan.DataSet.Query.Timeout
                $DataSetDefinition.Query.TimeoutSpecified       = $sub.DataRetrievalPlan.DataSet.Query.TimeoutSpecified

                $DataSetDefinition.CaseSensitivity              = $sub.DataRetrievalPlan.DataSet.CaseSensitivity
                $DataSetDefinition.CaseSensitivitySpecified     = $sub.DataRetrievalPlan.DataSet.CaseSensitivitySpecified
                $DataSetDefinition.Collation                    = $sub.DataRetrievalPlan.DataSet.Collation
                $DataSetDefinition.AccentSensitivity            = $sub.DataRetrievalPlan.DataSet.AccentSensitivity
                $DataSetDefinition.AccentSensitivitySpecified   = $sub.DataRetrievalPlan.DataSet.AccentSensitivitySpecified
                $DataSetDefinition.KanatypeSensitivity          = $sub.DataRetrievalPlan.DataSet.KanatypeSensitivity
                $DataSetDefinition.KanatypeSensitivitySpecified = $sub.DataRetrievalPlan.DataSet.KanatypeSensitivitySpecified
                $DataSetDefinition.WidthSensitivity             = $sub.DataRetrievalPlan.DataSet.WidthSensitivity
                $DataSetDefinition.WidthSensitivitySpecified    = $sub.DataRetrievalPlan.DataSet.WidthSensitivitySpecified
                $DataSetDefinition.Name                         = $sub.DataRetrievalPlan.DataSet.Name

                $DataRetrievalPlanItem = New-Object "$Namespace.DataSourceReference"
                $DataRetrievalPlanItem.Reference = $sub.DataRetrievalPlan.Item.Reference

                $DataRetrievalSettings = @{ 
                    Item = $DataRetrievalPlanItem
                    DataSet = $DataSetDefinition
                }

                $DataRetrievalPlan = New-Object "$Namespace.DataRetrievalPlan" -Property $DataRetrievalSettings

                $Sub.DataRetrievalPlan = $DataRetrievalPlan  
            }

            #Output subscription
            $Sub
        }
    }
}