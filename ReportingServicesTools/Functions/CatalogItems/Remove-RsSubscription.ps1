# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Remove-RsSubscription
{
    <#
        .SYNOPSIS
            This function removes an subscription from the report.
        
        .DESCRIPTION
            This function removes an subscription from the report.
        
        .PARAMETER Subscription
            An object returned from Get-RsSubscription that ccontains one or multiple SubscriptionId to remove. It is exclusive with $SubscriptionId parameter.

        .PARAMETER SubscriptionId
            The SubscriptionId to remove. It is exclusive with $Subscription parameter.
    
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
            Remove-RsSubscription -ReportServerUri http://localhost/ReportServer -SubscriptionId 'b4694569-99a9-4cb3-bd59-7bf710b04a0c'
   
            Description
            -----------
            Removes the subscription with ID 'b4694569-99a9-4cb3-bd59-7bf710b04a0c'

        .EXAMPLE
            Get-RsSubscription -ReportServerUri http://localhost/ReportServer_SQL2016 -Path '/path/to/my/report' |
            Out-GridView -PassThru |
            Remove-RsSubscription -ReportServerUri http://localhost/ReportServer_SQL2016
   
            Description
            -----------
            Gets a list of subscriptions from the report in a GridView from an SSRS instance names SQL2016 and allows the user to select items to be removed, after clicking "OK", only the items selected will be removed.
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName='MutipleSubscriptions', Mandatory = $True, ValueFromPipeline = $true)]
        [object[]]
        $Subscription,

        [Parameter(ParameterSetName='SingleSubscription', Mandatory=$True)]
        [string]
        $SubscriptionId,
        
        [string]
        $ReportServerUri,

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
        if ([System.String]::IsNullOrEmpty($SubscriptionId)) 
        {
            foreach ($item in $Subscription)
            {
                if ($PSCmdlet.ShouldProcess($item.SubscriptionId, "Delete the subscription")) 
                {
                    try 
                    {
                        Write-Verbose "Deleting subscription $($item.SubscriptionId) ..."
                        $Proxy.DeleteSubscription($item.SubscriptionId)
                        Write-Verbose "Subscription deleted successfully!"
                    }
                    catch 
                    {
                        throw (New-Object System.Exception("Exception occurred while deleting subscription id '$($item.SubscriptionId)'! $($_.Exception.Message)", $_.Exception))
                    }
                }
            }
        }
        else 
        {
            if ($PSCmdlet.ShouldProcess($SubscriptionId, "Delete the subscription")) 
            {
                try 
                {
                    Write-Verbose "Deleting subscription $SubscriptionId..."
                    $Proxy.DeleteSubscription($SubscriptionId)
                    Write-Verbose "Subscription deleted successfully!"
                }
                catch 
                {
                    throw (New-Object System.Exception("Exception occurred while deleting subscription id '$SubscriptionId'! $($_.Exception.Message)", $_.Exception))
                }
            }
        }
    }
}
