# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsFolderContent
{
    <#
        .SYNOPSIS
            List all catalog items under a given path.
        
        .DESCRIPTION
            List all catalog items under a given path.
        
        .PARAMETER RsFolder
            Path to folder on SSRS instance.
        
        .PARAMETER Recurse
            Recursively list subfolders with content.
    
        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.
    
        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.
        
        .EXAMPLE
            Get-RsFolderContent -ReportServerUri 'http://localhost/reportserver_sql2012' -RsFolder /
            
            Description
            -----------
            List all items under the root folder
    
        .EXAMPLE
            Get-RsFolderContent -ReportServerUri http://localhost/ReportServer -RsFolder / -Recurse

            Description
            -----------
            Lists all items directly under the root of the SSRS instance and recursively under all sub-folders.
    
        .EXAMPLE
            Get-RsFolderContent -RsFolder '/SQL Server Performance Dashboard' | WHERE Name -Like Wait* | Out-RsCatalogItem -Destination c:\SQLReports
       
            Description
            -----------
            Downloads all catalog items from folder '/SQL Server Performance Dashboard' with a name that starts with 'Wait' to folder 'C:\SQLReports'.
    #>
    
    [cmdletbinding()]
    param(
        [Alias('ItemPath', 'Path')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $RsFolder,
        
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
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }
    
    Process
    {
        foreach ($item in $RsFolder)
        {
            try
            {
                $Proxy.ListChildren($Item, $Recurse)
            }
            catch
            {
                throw
            }
        }
    }
}
New-Alias -Name "Get-RsCatalogItems" -Value Get-RsFolderContent -Scope Global
New-Alias -Name "Get-RsChildItem" -Value Get-RsFolderContent -Scope Global
New-Alias -Name "rsdir" -Value Get-RsFolderContent -Scope Global
