# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsSubscription
{
    <#
        .SYNOPSIS
            This script retrieves information about subscriptions for a report.
        
        .DESCRIPTION
            This script retrieves information about subscriptions for a report.
        
        .PARAMETER Path
            Specify the path to the report.
        
        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Credential
            Specify the password to use when connecting to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.
        
        .EXAMPLE
            Get-RsSubscription -Path '/path/to/my/report'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and retrieve details of subscriptions found at '/path/to/my/report'.
        
        .EXAMPLE
            Get-RsSubscription -ReportServerUri 'http://remote-machine:8080/reportserver_sql16' -Path '/path/to/my/report'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://remote-machine:8080/reportserver_sql16 using current user's credentials and retrieve details of subscriptions found at '/path/to/my/report'.
    #>

    [cmdletbinding()]
    param
    (
        [Alias('ItemPath')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
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
        foreach ($Item in $Path)
        {
            try
            {
                Write-Verbose "Retrieving subscriptions contents..."
                #$Proxy.ListSubscriptions($Item)
                
                $subscriptions = $Proxy.ListSubscriptions($Item)
                Write-Verbose "Subscriptions retrieved successfully!"

                $extSettings = $null
                $desc = $null
                $active = $null
                $status = $null
                $eventType = $null
                $matchData = $null
                $values = $null
                
                Write-Verbose "GetSubscriptionProperties"
                foreach ($subscription in $subscriptions) {
                    $null = $Proxy.GetSubscriptionProperties($subscription.SubscriptionID, [ref]$extSettings, [ref]$desc, [ref]$active, [ref]$status, [ref]$eventType, [ref]$matchData, [ref]$values)

                    $namespace = $proxy.GetType().Namespace

                    $ExtensionSettingsDataType = "$namespace.ExtensionSettings"
                    $ActiveStateDataType = "$namespace.ActiveState"
                    
                    #Set ExtensionSettings
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
                    
                    [pscustomobject]@{
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
                
                }
            }
            catch
            {
                throw (New-Object System.Exception("Exception while retrieving subscription(s)! $($_.Exception.Message)", $_.Exception))
            }
        }
    }
}
