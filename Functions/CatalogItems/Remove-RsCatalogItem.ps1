# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Remove-RsCatalogItem
{
    <#
<<<<<<< HEAD
        .SYNOPSIS
            This script creates a new data source on Report Server.
        
        .DESCRIPTION
            This script creates a new data source on Report Server.
        
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
=======
    .SYNOPSIS
        This function removes an item from the Report Server Catalog.

    .DESCRIPTION
        This function removes an item from the Report Server Catalog. 

    .PARAMETER ReportServerUri
        Specify the Report Server URL to your SQL Server Reporting Services Instance.

    .PARAMETER ReportServerCredentials
        Specify the credentials to use when connecting to your SQL Server Reporting Services Instance.

    .PARAMETER Proxy
        Specify the Proxy to use when communicating with Reporting Services server. If Proxy is not specified, connection to Report Server will be created using ReportServerUri, ReportServerUsername and ReportServerPassword.
    
    .PARAMETER RsFolder
        Specify the RsFolder path of the catalog item to remove.

    .EXAMPLE
        Remove-RsCatalogItem -ReportServerUri http://localhost/ReportServer -RsFolder /monthlyreports
   
        Description
        -----------
        Removes the monthlyreports folder, located directly at the root of the SSRS instance, and all objects below it.

    .EXAMPLE
        Get-RsCatalogItems -ReportServerUri http://localhost/ReportServer_SQL2016 -RsFolder '/SQL Server Performance Dashboard' |
        Out-GridView -PassThru |
        Remove-RsCatalogItem -ReportServerUri http://localhost/ReportServer_SQL2016
   
        Description
        -----------
        Gets a list of items from the SQL Server Performance Dashboard folder in a GridView from an SSRS instance names SQL2016 and allows the user to select items to be removed, after clicking "OK", only the items selected will be removed.

>>>>>>> refs/remotes/Microsoft/master
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
        
<<<<<<< HEAD
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
=======
        [Alias('Path')]
        [Parameter(Mandatory=$True,ValueFromPipeline = $true,ValueFromPipelinebyPropertyname = $true)]
        [string]
        $RsFolder
    )
process 
    {

        if(-not $Proxy)
        {
            $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Credentials $ReportServerCredentials 
        }

        try
        {
            Write-Verbose "Deleting catalog item $RsFolder..."
            $Proxy.DeleteItem($RsFolder)
            Write-Information "Catalog item deleted successfully!"
        }
        catch
        {
            Write-Error "Exception occurred while deleting catalog item! $($_.Exception.Message)"
            break
>>>>>>> refs/remotes/Microsoft/master
        }
    }
}
