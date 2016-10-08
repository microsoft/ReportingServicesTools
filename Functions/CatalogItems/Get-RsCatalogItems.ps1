# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<#
.SYNOPSIS
    List all catalog items under a given path.

.DESCRIPTION
    List all catalog items under a given path.

.PARAMETER ReportServerUri (optional)
    Specify the Report Server URL to your SQL Server Reporting Services Instance.
    Has to be provided if proxy is not provided.

.PARAMETER ReportServerUsername (optional)
    Specify the user name to use when connecting to your SQL Server Reporting Services Instance.

.PARAMETER ReportServerPassword (optional)
    Specify the password to use when connecting to your SQL Server Reporting Services Instance.

.PARAMETER Proxy (optional)
    Report server proxy to use. 
    Has to be provided if ReportServerUri is not provided.

.PARAMETER Path
    Path to folder.

.PARAMETER Recurse (optional)
    Recursively list subfolders with content.


.EXAMPLE
    Get-RsCatalogItems -ReportServerUri 'http://localhost/reportserver_sql2012' -Path /
   
    Description
    -----------
    List all items under the root folder
#>


function Get-RsCatalogItems
{
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
        $Path,
        
        [switch]
        $Recurse
    )

    if(-not $Proxy)
    {
        $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Username $ReportServerUsername -Password $ReportServerPassword 
    }

    $Proxy.ListChildren($Path, $Recurse)    
}