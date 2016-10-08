# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Register-PowerBI
{
    <#
    .SYNOPSIS
        This script configures Power BI integration.

    .DESCRIPTION
        This script configures Power BI integration by providing details about a previously configured Azure Active Directory Web App

    .PARAMETER SqlServerInstance (optional)
        Specify the name of the SQL Server Reporting Services Instance. The default Reporting Services instance is typically named 'MSSQLSERVER'.

    .PARAMETER SqlServerVersion (optional)
        Specify the version of the SQL Server Reporting Services Instance. 13 for SQL Server 2016, 12 for SQL Server 2014, 11 for SQL Server 2012
        (Power BI integration was introduced in SQL Server 2016)

    .PARAMETER ClientId 
        Specify the Azure AD Client ID

    .PARAMETER ClientSecret 
        Client secret (client key) created to access the Azure AD App

    .PARAMETER AppObjectId 
        App Object ID representing the Azure AD App

    .PARAMETER TenantName 
        Azure AD Tenant Name ie. the organization name

    .PARAMETER TenantId 
        Azure AD Tenant ID

    .PARAMETER ResourceUrl (optional)
        Overrides the default Power BI endpoint. Generally 'https://analysis.windows.net/powerbi/api'.

    .PARAMETER AuthUrl (optional)
        Overrides the default Azure AD authentication URL. Generally 'https://login.windows.net/common/oauth2/authorize'.

    .PARAMETER TokenUrl (optional)
        Overrides the default Azure AD token URL. Generally 'https://login.microsoftonline.com/common/oauth2/token'.

    .PARAMETER RedirectUrls 
        Redirect URLS - needs to match what is configured in the Azure AD app. General format:  http://{MyServerName}:80/reportserver/pages/LoginComplete.aspx

    .LINK
        https://blogs.msdn.microsoft.com/sqlrsteamblog/2016/07/22/manually-configuring-power-bi-integration-in-reporting-services/
    #>

    [cmdletbinding()]
    param
    (
        [string]
        $SqlServerInstance='MSSQLSERVER',

        [string]
        $SqlServerVersion='13',

        [Parameter(Mandatory=$True)]
        [string]
        $ClientId,

        [Parameter(Mandatory=$True)]
        [string]
        $ClientSecret,
        
        [Parameter(Mandatory=$True)]
        [string]
        $AppObjectId,
        
        [Parameter(Mandatory=$True)]
        [string]
        $TenantName,
        
        [Parameter(Mandatory=$True)]
        [string]
        $TenantId,
        
        [string]
        $ResourceUrl = 'https://analysis.windows.net/powerbi/api',
        
        [string]
        $AuthUrl = 'https://login.windows.net/common/oauth2/authorize',
        
        [string]
        $TokenUrl = 'https://login.microsoftonline.com/common/oauth2/token',
        
        [Parameter(Mandatory=$True)]
        [string]
        $RedirectUrls   
    )

    $rsWmiObject = New-RSConfigurationSettingObject -SqlServerInstance $SqlServerInstance -SqlServerVersion $SqlServerVersion

    Write-Verbose "Configuring Power BI ..."
    $configureResult = $rsWmiObject.SavePowerBIInformation($ClientId,
                                        $ClientSecret,
                                        $AppObjectId,
                                        $TenantName,
                                        $TenantId,
                                        $ResourceUrl,
                                        $AuthUrl,
                                        $TokenUrl,
                                        $RedirectUrls)

    if ($configureResult.HRESULT -eq 0) 
    {
        Write-Verbose "Success!"
    } 
    else
    {
        Write-Error "Fail! `n Errors: $($configureResult.ExtendedErrors)"
        Exit 1
    }
}
