# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsSubscription
{
    <#
        .SYNOPSIS
            This script retrieves information about subscriptions for a report.

        .DESCRIPTION
            This script retrieves information about subscriptions for a report.

        .PARAMETER RsItem
            Specify the path to the report.

        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER ApiVersion
            The version of the API to use, 2010 by default. Sepcifiy '2005' if you need
            to query a Sql Server Reporting Service Instance running a version prior to
            SQL Server 2008 R2.

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.

        .EXAMPLE
            Get-RsSubscription -RsItem '/path/to/my/report'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and retrieve details of subscriptions found at '/path/to/my/report'.

        .EXAMPLE
            Get-RsSubscription -ReportServerUri 'http://remote-machine:8080/reportserver_sql16' -RsItem '/path/to/my/report'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://remote-machine:8080/reportserver_sql16 using current user's credentials and retrieve details of subscriptions found at '/path/to/my/report'.

        .EXAMPLE
            $rsProxy = New-RsWebServiceProxy -ReportServerUri 'http://remote-machine:8080/reportserver_sql16'
            Get-RsSubscription -Proxy $rsProxy -RsItem '/path/to/my/report'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://remote-machine:8080/reportserver_sql16 using current user's credentials and retrieve details of subscriptions found at '/path/to/my/report'.
    #>

    [cmdletbinding()]
    param
    (
        [Alias('Path')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $RsItem,

        [string]
        $ReportServerUri,

        [ValidateSet('2005','2006','2010')]
        [string]
        $ApiVersion = '2010',

        [System.Management.Automation.PSCredential]
        $Credential,

        $Proxy
    )
    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }
    Process
    {
        foreach ($item in $RsItem)
        {
            try
            {
                Write-Verbose "Retrieving subscriptions contents..."

                if ($Proxy.Url -match 'ReportService2005.asmx')
                {
                    if ($item -eq '/') { $item = $null }
                    $subscriptions = $Proxy.ListSubscriptions($Item,$null)
                }
                else
                {
                    $subscriptions = $Proxy.ListSubscriptions($Item)
                }

                Write-Verbose "Subscriptions retrieved successfully!"

                $namespace = $proxy.GetType().Namespace
                $DataRetrievalPlanDataType = "$namespace.DataRetrievalPlan"
                $ExtensionSettingsDataType = "$namespace.ExtensionSettings"
                $ActiveStateDataType = "$namespace.ActiveState"

                foreach ($subscription in $subscriptions)
                {
                    $extSettings = $null
                    $DataRetrievalPlan = $null
                    $desc = $null
                    $active = $null
                    $status = $null
                    $eventType = $null
                    $matchData = $null
                    $values = $null
                    $Result = $null

                    try
                    {
                        Write-Verbose "Retrieving subscription properties for $($subscription.SubscriptionID)..."

                        if ($subscription.IsDataDriven)
                        {
                            $null = $Proxy.GetDataDrivenSubscriptionProperties($subscription.SubscriptionID, [ref]$extSettings, [ref]$DataRetrievalPlan, [ref]$desc, [ref]$active, [ref]$status, [ref]$eventType, [ref]$matchData, [ref]$values)
                        }
                        else
                        {
                            $null = $Proxy.GetSubscriptionProperties($subscription.SubscriptionID, [ref]$extSettings, [ref]$desc, [ref]$active, [ref]$status, [ref]$eventType, [ref]$matchData, [ref]$values)
                        }

                        Write-Verbose "Subscription properties for $($subscription.SubscriptionID) retrieved successfully!"

                        #Set ExtensionSetting/s
                        $ExtensionSettings = New-Object $ExtensionSettingsDataType
                        $ExtensionSettings.Extension = $subscription.DeliverySettings.Extension
                        $ExtensionSettings.ParameterValues = $subscription.DeliverySettings.ParameterValues

                        #Set ActiveState
                        $ActiveState = New-Object $ActiveStateDataType
                        $ActiveState.DeliveryExtensionRemoved          = $subscription.Active.DeliveryExtensionRemoved
                        $ActiveState.DeliveryExtensionRemovedSpecified = $subscription.Active.DeliveryExtensionRemovedSpecified
                        $ActiveState.SharedDataSourceRemoved           = $subscription.Active.SharedDataSourceRemoved
                        $ActiveState.SharedDataSourceRemovedSpecified  = $subscription.Active.SharedDataSourceRemovedSpecified
                        $ActiveState.MissingParameterValue             = $subscription.Active.MissingParameterValue
                        $ActiveState.MissingParameterValueSpecified    = $subscription.Active.MissingParameterValueSpecified
                        $ActiveState.InvalidParameterValue             = $subscription.Active.InvalidParameterValue
                        $ActiveState.InvalidParameterValueSpecified    = $subscription.Active.InvalidParameterValueSpecified
                        $ActiveState.UnknownReportParameter            = $subscription.Active.UnknownReportParameter
                        $ActiveState.UnknownReportParameterSpecified   = $subscription.Active.UnknownReportParameterSpecified

                        $Result = @{
                            SubscriptionID        = $subscription.SubscriptionID
                            Owner                 = $subscription.Owner
                            Path                  = $subscription.Path
                            VirtualPath           = $subscription.VirtualPath
                            Report                = $subscription.Report
                            DeliverySettings      = $ExtensionSettings
                            Description           = $subscription.Description
                            Status                = $subscription.Status
                            Active                = $ActiveState
                            LastExecuted          = $subscription.LastExecuted
                            LastExecutedSpecified = $subscription.LastExecutedSpecified
                            ModifiedBy            = $subscription.ModifiedBy
                            ModifiedDate          = $subscription.ModifiedDate
                            EventType             = $subscription.EventType
                            IsDataDriven          = $subscription.IsDataDriven
                            MatchData             = $matchData
                            Values                = $values
                        }

                        if ($subscription.IsDataDriven)
                        {
                            $Result.Add('DataRetrievalPlan',$DataRetrievalPlan)
                        }

                        [pscustomobject]$Result
                    }
                    catch
                    {
                        Write-Error (New-Object System.Exception("Exception while retrieving subscription properties! $($_.Exception.Message)", $_.Exception))
                        Write-Verbose ($subscription | format-list | out-string)
                    }
                }
            }
            catch
            {
                throw (New-Object System.Exception("Exception while retrieving subscription(s)! $($_.Exception.Message)", $_.Exception))
            }
        }
    }
}
