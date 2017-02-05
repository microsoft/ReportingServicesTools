# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Register-RsPowerBI
{
    <#
        .SYNOPSIS
            This script configures Power BI integration.
        
        .DESCRIPTION
            This script configures Power BI integration by providing details about a previously configured Azure Active Directory Web App
        
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
        
        .PARAMETER ResourceUrl
            Default: 'https://analysis.windows.net/powerbi/api'
            Overrides the default Power BI endpoint.
        
        .PARAMETER AuthUrl
            Default: 'https://login.windows.net/common/oauth2/authorize'
            Overrides the default Azure AD authentication URL.
        
        .PARAMETER TokenUrl
            Default: 'https://login.microsoftonline.com/common/oauth2/token'
            Overrides the default Azure AD token URL.
        
        .PARAMETER RedirectUrls
            Redirect URLS - needs to match what is configured in the Azure AD app. General format:  http://{MyServerName}:80/reportserver/pages/LoginComplete.aspx
        
        .PARAMETER ReportServerInstance
            Specify the name of the SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER ReportServerVersion
            Specify the version of the SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER ComputerName
            The Report Server to target.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Credential
            The credentials with which to connect to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .EXAMPLE
            PS C:\> Register-RsPowerBI -ClientId 'value1' -ClientSecret 'value2' -AppObjectId 'value3' -TenantName 'value4' -TenantId 'value5' -RedirectUrls 'value6'
    
            <Insert description here>
        
        .NOTES
            Author:      ???
            Editors:     Friedrich Weinmann
            Created on:  ???
            Last Change: 26.01.2017
            Version:     1.1
            
            Release 1.1 (26.01.2017, Friedrich Weinmann)
            - Fixed Parameter help (Don't poison the name with "(optional)", breaks Get-Help)
            - Implemented ShouldProcess (-WhatIf, -Confirm)
            - Replaced calling exit with throwing a terminating error (exit is a bit of an overkill when failing a simple execution)
            - Improved error message on failure.
            - Standardized the parameters governing the Report Server connection for consistent user experience.
            - Added input validation, to ensure no out-of-date servers are specified.
            - Renamed function from "Register-PowerBI" to "Register-RsPowerBI", in order to conform to naming standards and include the module prefix. Introduced an alias with the old name for backwards compatibility.
            
            Release 1.0 (???, ???)
            - Initial Release
        
        .LINK
            https://blogs.msdn.microsoft.com/sqlrsteamblog/2016/07/22/manually-configuring-power-bi-integration-in-reporting-services/
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(Mandatory = $True)]
        [string]
        $ClientId,

        [Parameter(Mandatory = $True)]
        [string]
        $ClientSecret,
        
        [Parameter(Mandatory = $True)]
        [string]
        $AppObjectId,
        
        [Parameter(Mandatory = $True)]
        [string]
        $TenantName,
        
        [Parameter(Mandatory = $True)]
        [string]
        $TenantId,
        
        [string]
        $ResourceUrl = 'https://analysis.windows.net/powerbi/api',
        
        [string]
        $AuthUrl = 'https://login.windows.net/common/oauth2/authorize',
        
        [string]
        $TokenUrl = 'https://login.microsoftonline.com/common/oauth2/token',
        
        [Parameter(Mandatory = $True)]
        [string]
        $RedirectUrls,
        
        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,
        
        [Alias('SqlServerVersion')]
        [ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion,
        
        [string]
        $ComputerName,
        
        [System.Management.Automation.PSCredential]
        $Credential
	)
	
	if ($PSCmdlet.ShouldProcess($ReportServerInstance, "Registering PowerBI for SQL Server Instance"))
	{
	    #region Connect to Report Server using WMI
        try
        {
            $splat = @{ }
            if ($PSBoundParameters.ContainsKey('ReportServerInstance')) { $splat['ReportServerInstance'] = $ReportServerInstance }
            if ($PSBoundParameters.ContainsKey('ReportServerVersion')) { $splat['ReportServerVersion'] = $ReportServerVersion }
            if ($PSBoundParameters.ContainsKey('ComputerName')) { $splat['ComputerName'] = $ComputerName }
            if ($PSBoundParameters.ContainsKey('Credential')) { $splat['Credential'] = $Credential }
            $rsWmiObject = New-RsConfigurationSettingObject @splat -MinimumSqlServerVersion "SQLServer2016"
        }
        catch
        {
            throw
        }
        #endregion Connect to Report Server using WMI

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
            Write-Verbose "Configuring Power BI ... Success!"
		}
		else
		{
			throw "Failed to register PowerBI for server instance: $ReportServerInstance. Errors: $($configureResult.ExtendedErrors)"
		}
	}
}
New-Alias -Name "Register-PowerBI" -Value "Register-RsPowerBI" -Scope Global