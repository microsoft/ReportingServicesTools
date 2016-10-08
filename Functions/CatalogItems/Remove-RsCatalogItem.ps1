# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Remove-RsCatalogItem
{
    <#
    .SYNOPSIS
        This script creates a new data source on Report Server.

    .DESCRIPTION
        This script creates a new data source on Report Server. 

    .PARAMETER ReportServerUri (optional)
        Specify the Report Server URL to your SQL Server Reporting Services Instance.

    .PARAMETER ReportServerUsername (optional)
        Specify the user name to use when connecting to your SQL Server Reporting Services Instance.

    .PARAMETER ReportServerPassword (optional)
        Specify the password to use when connecting to your SQL Server Reporting Services Instance.

    .PARAMETER Proxy (optional)
        Specify the Proxy to use when communicating with Reporting Services server. If Proxy is not specified, connection to Report Server will be created using ReportServerUri, ReportServerUsername and ReportServerPassword.
    
    .PARAMETER Path
        Specify the path of the catalog item to remove.
    #>

    [cmdletbinding()]
    param(
        [string]
        $ReportServerUri = 'http://localhost/reportserver',
        
        [string]
        $ReportServerUsername,
        
        [string]
        $ReportServerPassword,
        
        $Proxy,
        
        [Parameter(Mandatory=$True)]
        [string]
        $Path
    )

    if(-not $Proxy)
    {
        $Proxy = New-RsWebServiceProxy -ReportServerUri $ReportServerUri -Username $ReportServerUsername -Password $ReportServerPassword 
    }

    try
    {
        Write-Verbose "Deleting catalog item $Path..."
        $Proxy.DeleteItem($Path)
        Write-Information "Catalog item deleted successfully!"
    }
    catch
    {
        Write-Error "Exception occurred while deleting catalog item! $($_.Exception.Message)"
        break
    }
}