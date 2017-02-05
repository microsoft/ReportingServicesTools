# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Write-RsCatalogItem
{
    <#
        .SYNOPSIS
            Uploads an item from disk to a report server.
        
        .DESCRIPTION
            Uploads an item from disk to a report server.
            Currently, we are only supporting Report, DataSource and DataSet for uploads
        
        .PARAMETER Path
            Path to item to upload on disk.
        
        .PARAMETER Destination
            Folder on reportserver to upload the item to.
        
       .PARAMETER Overwrite
            Overwrite the old entry, if an existing catalog item with same name exists at the specified destination.
        
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
            Write-RsCatalogItem -ReportServerUri 'http://localhost/reportserver_sql2012' -Path c:\reports\monthlyreport.rdl -Destination /monthlyreports
            
            Description
            -----------
            Uploads the report monthlyreport.rdl to folder /monthlyreports
        
        .NOTES
            Author:      ???
            Editors:     Friedrich Weinmann
            Created on:  ???
            Last Change: 05.02.2017
            Version:     1.1
            
            Release 1.1 (05.02.2017, Friedrich Weinmann)
            - Removed/Replaced all instances of "Write-Information", in order to maintain PowerShell 3.0 Compatibility.
            - Fixed Parameter help (Don't poison the name with "(optional)", breaks Get-Help)
            - Standardized the parameters governing the Report Server connection for consistent user experience.
            - Renamed the parameter 'Override' to 'Overwrite', for consistency's sake. Added the previous name as an alias, for backwards compatiblity.
            - Changed type of parameter 'Path' to System.String[], to better facilitate pipeline & nonpipeline use
            - Redesigned to accept pipeline input from 'Path'
            - Implemented ShouldProcess (-WhatIf, -Confirm)
            - Added alias 'DestinationFolder' for parameter 'Destination', for consistency's sake.
        
            Release 1.0 (???, ???)
            - Initial Release
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,
        
        [Alias('DestinationFolder')]
        [Parameter(Mandatory = $True)]
        [string]
        $Destination,
        
        [Alias('Override')]
        [switch]
        $Overwrite,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    Begin
    {
        #region Utility Function
        function Get-ItemType
        {
            param (
                [string]
                $FileExtension
            )
            
            if ($FileExtension -eq '.rdl')
            {
                return 'Report'
            }
            elseif ($FileExtension -eq '.rsds')
            {
                return 'DataSource'
            }
            elseif ($FileExtension -eq '.rsd')
            {
                return 'DataSet'
            }
            else
            {
                throw 'Uploading currently only supports .rdl, .rsds and .rsd files'
            }
        }
        #endregion Utility Function
        
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
            #region Manage Paths
            if (!(Test-Path $item))
            {
                throw "No item found at the specified path: $item!"
            }
            
            $EntirePath = Resolve-Path $item
            $item = Get-Item $EntirePath
            $itemType = Get-ItemType $item.Extension
            $itemName = $item.BaseName
            
            
            if ($Destination -eq "/")
            {
                Write-Verbose "Uploading $EntirePath to /$($itemName)"
            }
            else
            {
                Write-Verbose "Uploading $EntirePath to $Destination/$($itemName)"
            }
            #endregion Manage Paths
            
            if ($PSCmdlet.ShouldProcess("$itemName", "Upload from $EntirePath to Report Server at $Destination"))
            {
                #region Upload DataSource
                if ($itemType -eq 'DataSource')
                {
                    try { [xml]$content = Get-Content -Path $EntirePath -ErrorAction Stop }
                    catch { throw (New-Object System.Exception("Failed to access XML content of '$EntirePath': $($_.Exception.Message)", $_.Exception)) }
                    if ($content.DataSourceDefinition -eq $null)
                    {
                        throw "Data Source Definition not found in the specified file: $EntirePath!"
                    }
                    
                    $splat = @{
                        Proxy = $Proxy
                        Destination = $Destination
                        Name = $itemName
                        Extension = $content.DataSourceDefinition.Extension
                        ConnectionString = $content.DataSourceDefinition.ConnectString
                        Disabled = ("false" -like $content.DataSourceDefinition.Enabled)
                        CredentialRetrieval = 'None'
                        Overwrite = $Overwrite
                    }
                    
                    New-RsDataSource @splat
                }
                #endregion Upload DataSource
                
                #region Upload other stuff
                else
                {
                    $bytes = [System.IO.File]::ReadAllBytes($EntirePath)
                    $warnings = $null
                    try { $Proxy.CreateCatalogItem($itemType, $itemName, $Destination, $Overwrite, $bytes, $null, [ref]$warnings) | Out-Null }
                    catch { throw (New-Object System.Exception("Failed to create catalog item: $($_.Exception.Message)", $_.Exception)) }
                }
                #endregion Upload other stuff
                
                Write-Verbose "$EntirePath was uploaded to $Destination successfully!"
            }
        }
    }
}