# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsFolderContent
{
	<#
	.SYNOPSIS
		List all catalog items under a given path.

	.DESCRIPTION
		List all catalog items under a given path.

	.PARAMETER ReportServerUri
		Specify the Report Server URL to your SQL Server Reporting Services Instance.
		Has to be provided if proxy is not provided.

	.PARAMETER ReportServerCredentials
		Specify the credentials to use when connecting to your SQL Server Reporting Services Instance.

	.PARAMETER Proxy
		Report server proxy to use. 
		Has to be provided if ReportServerUri is not provided.

	.PARAMETER Path
		Path to folder.

	.PARAMETER Recurse
		Recursively list subfolders with content.


	.EXAMPLE
		Get-RsFolderContent -ReportServerUri 'http://localhost/reportserver_sql2012' -Path /
	   
		Description
		-----------
		List all items under the root folder
	#>
	
	[cmdletbinding()]
    param(
        [string]
        $ReportServerUri = 'http://localhost/reportserver',
        
        [System.Management.Automation.PSCredential]
        $ReportServerCredentials,
        
        $Proxy,
        
        [Parameter(Mandatory=$True,ValueFromPipeline = $true,ValueFromPipelinebyPropertyname = $true)]
        [string]
        $Path,
        
        [switch]
        $Recurse
    )
process 
    {

        if(-not $Proxy)
        {
		    $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Credentials $ReportServerCredentials
        }

        $Proxy.ListChildren($Path, $Recurse)
    }
}
New-Alias -Name "Get-RsCatalogItems" -Value Get-RsFolderContent -Scope Global