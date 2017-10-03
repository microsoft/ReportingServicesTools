Function Import-RsSubscription {
    <#
        .SYNOPSIS
            This script imports a subscription that has been exported e.g via Get-RsSubscription | Export-RsSubscription .\somepath.xml
        
        .DESCRIPTION
            This script imports a subscription and rebuilds the .deliverysettings property so that the resultant object will be accepted by Set-RsSubscription.
            This is useful if you need to store your Subscription configs in a file (e.g to add to source control) and then later want to use that file to
            recreate your subscriptions.
                    
        .PARAMETER Path
            The path to the XML file that contains the exported subscription. 
            This is typically a file created by executing Get-RsSubscription | Export-CliXml .\somepath.xml
        
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
            Import-RsSubscription .\MySubscriptions.xml

            Description
            -----------
            This command will import the subscriptions contained in .\MySubscriptions.xml, recreate their .DeliverySettings properties
            and output a PowerShell object with the result.
    #>
        
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True,Position=0)]
        [string]
        $Path,

        [string]
        $ReportServerUri,
        
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    Begin { 
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }
    Process {    
        Write-Verbose "Importing Subscription from $Path..."
        $Subscription = Import-Clixml $Path

        ForEach ($Sub in $Subscription) {

            $Namespace = $Proxy.GetType().NameSpace
            $ParameterValues = @(New-Object "$Namespace.ParameterValue") * $Sub.DeliverySettings.ParameterValues.count

            $Sub.DeliverySettings.ParameterValues | ForEach-Object -Begin {$i = 0} {
                $ParameterValues[$i] = New-Object "$Namespace.ParameterValue"
                $ParameterValues[$i].Name = $_.Name
                $ParameterValues[$i].Value = $_.Value
                $i++
            }
    
            $DeliverySettings = New-Object "$Namespace.ExtensionSettings"
            $DeliverySettings.Extension = $Sub.DeliverySettings.Extension
            $DeliverySettings.ParameterValues = $ParameterValues
    
            $Sub.DeliverySettings = $DeliverySettings

            $Sub

        }
    }
}