# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsCatalogChildItem
{
    <#
        .SYNOPSIS
            List all catalog items under a given path.
        
        .DESCRIPTION
            List all catalog items under a given path.
        
        .PARAMETER Path
            Path to folder.
        
        .PARAMETER Recurse
            Recursively list subfolders with content.
    
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
            Get-RsCatalogChildItem -ReportServerUri 'http://localhost/reportserver_sql2012' -Path /
            
            Description
            -----------
            List all items under the root folder
        
        .NOTES
            Author:      ???
            Editors:     Friedrich Weinmann
            Created on:  ???
            Last Change: 02.02.2017
            Version:     1.1
            
            Release 1.1 (02.02.2017, Friedrich Weinmann)
            - Fixed Parameter help (Don't poison the name with "(optional)", breaks Get-Help)
            - Standardized the parameters governing the Report Server connection for consistent user experience.
            - Changed type of parameter 'Path' to System.String[], to better facilitate pipeline & nonpipeline use
            - Added alias 'ItemPath' for parameter 'Path', for consistency's sake
            - Redesigned to accept pipeline input from 'Path'
            - Renamed function from "Get-RsCatalogItems" to "Get-RsCatalogChildItem", in order to conform to naming standards. Introduced an alias with the old name for backwards compatibility.
    
            Release 1.0 (???, ???)
            - Initial Release
    #>
	
	[cmdletbinding()]
    param(
        [Alias('ItemPath')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,
        
        [switch]
        $Recurse,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    Begin
    {
        #region Connect to Report Server using Web Proxy
        if (-not $Proxy)
        {
            try
            {
                $splat = @{ }
                if ($PSBoundParameters.ContainsKey('ReportServerUri')) { $splat['ReportServerUri'] = $ReportServerUri }
                if ($PSBoundParameters.ContainsKey('Credential')) { $splat['Credential'] = $Credential }
                $Proxy = New-RSWebServiceProxy @splat
            }
            catch
            {
                throw
            }
        }
        #endregion Connect to Report Server using Web Proxy
    }
    
    Process
    {
        foreach ($item in $Path)
        {
            try { $Proxy.ListChildren($Item, $Recurse) }
            catch { throw }
        }
    }
}
New-Alias -Name "Get-RsCatalogItems" -Value Get-RsCatalogChildItem -Scope Global