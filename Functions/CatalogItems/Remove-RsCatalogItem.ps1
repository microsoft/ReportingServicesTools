# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Remove-RsCatalogItem
{
    <#
        .SYNOPSIS
            This function removes an item from the Report Server Catalog.
        
        .DESCRIPTION
            This function removes an item from the Report Server Catalog.
        
        .PARAMETER Path
            Specify the path of the catalog item to remove.
    
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
            PS C:\> Remove-RsCatalogItem -Path '/item'
    
            Removes /item from the Report Server
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
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
        foreach ($item in $Path)
        {
            if ($PSCmdlet.ShouldProcess($item, "Delete the catalog item"))
            {
                try
                {
                    Write-Verbose "Deleting catalog item $item..."
                    $Proxy.DeleteItem($item)
                    Write-Verbose "Catalog item deleted successfully!"
                }
                catch
                {
                    throw (New-Object System.Exception("Exception occurred while deleting catalog item '$item'! $($_.Exception.Message)", $_.Exception))
                }
            }
        }
    }
}
