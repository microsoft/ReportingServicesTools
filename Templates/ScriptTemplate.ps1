# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function DoSomeThingTo-RSCatalogItem
{
    <#
        .SYNOPSIS
            A brief description of the DoSomeThingTo-RSCatalogItem function.

        .DESCRIPTION
            A detailed description of the DoSomeThingTo-RSCatalogItem function.

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
            PS C:\> DoSomeThingTo-RSCatalogItem

            Does something to an RS Catalog Item
    #>
    
    [CmdletBinding()]
    param (
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
        
    }
    
    End
    {
        
    }
}

