# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<#

.SYNOPSIS

.DESCRIPTION

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
    
.EXAMPLE
    
    Description
    -----------
#>


function DoSomeThingTo-RSCatalogItem
{
    param(
        [string]
        $ReportServerUri = 'http://localhost/reportserver',
        
        [System.Management.Automation.PSCredential]
        $ReportServerCredentials,
        
        $Proxy
    )

    if(-not $Proxy)
    {
        $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Credentials $ReportServerCredentials
    }

    # Script logic ..
}

