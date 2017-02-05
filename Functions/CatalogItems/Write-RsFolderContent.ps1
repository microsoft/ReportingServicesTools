# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Write-RsFolderContent
{
    <#
        .SYNOPSIS
            Uploads all items in a folder on disk to a report server.
        
        .DESCRIPTION
            Uploads all items in a folder on disk to a report server.
            Currently, we are only supporting Report, DataSource and DataSet for uploads
        
        .PARAMETER Recurse
            A description of the Recurse parameter.
        
        .PARAMETER Path
            Path to folder which contains items to upload on disk.
        
        .PARAMETER Destination
            Folder on reportserver to upload the item to.
        
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
            Write-RsFolderContent -ReportServerUri 'http://localhost/reportserver_sql2012' -Path c:\monthlyreports -Destination /monthlyReports
            
            Description
            -----------
            Uploads all reports under c:\monthlyreports to folder /monthlyReports.
        
        .NOTES
            Author:      ???
            Editors:     Friedrich Weinmann
            Created on:  ???
            Last Change: 05.02.2017
            Version:     1.1
            
            Release 1.1 (05.02.2017, Friedrich Weinmann)
            - Fixed Parameter help (Don't poison the name with "(optional)", breaks Get-Help)
            - Standardized the parameters governing the Report Server connection for consistent user experience.
            - Renamed the parameter 'DestinationFolder' to 'Destination', for consistency's sake. Added the previous name as an alias, for backwards compatiblity.
            - Implemented ShouldProcess (-WhatIf, -Confirm)
    
            Release 1.0 (???, ???)
            - Initial Release
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [switch]
        $Recurse,
        
        [Parameter(Mandatory = $True)]
        [string]
        $Path,
        
        [Alias('DestinationFolder')]
        [Parameter(Mandatory = $True)]
        [string]
        $Destination,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    if ($PSCmdlet.ShouldProcess($Path, "Upload all contents in folder $(if ($Recurse) { "and subfolders " })to $Destination"))
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
        
        if(-not (Test-Path $Path -PathType Container))
        {
            throw "$Path is not a folder"
        }
        $sourceFolder = Get-Item $Path
        
        if($Recurse) { $items = Get-ChildItem $Path -Recurse } else { $items = Get-ChildItem $Path }
        foreach ($item in $items)
        {
            if (($item.PSIsContainer) -and $Recurse)
            {
                $relativePath = Clear-Substring -string $item.FullName -substring $sourceFolder.FullName.TrimEnd("\") -position front
                $relativePath = Clear-Substring -string $relativePath -substring ("\" + $item.Name) -position back
                $relativePath = $relativePath.replace("\", "/")
                if ($Destination -eq "/" -and $relativePath -ne "")
                {
                    $parentFolder = $relativePath
                }
                else
                {
                    $parentFolder = $Destination + $relativePath
                }
                
                Write-Verbose "Creating folder $parentFolder/$($item.Name)"
                try { $Proxy.CreateFolder($item.Name, $parentFolder, $null) | Out-Null }
                catch { throw (New-Object System.Exception("Failed to create folder '$($item.Name)' in '$parentFolder': $($_.Exception.Message)", $_.Exception))}
            }
            
            if ($item.Extension -eq ".rdl" -or
                $item.Extension -eq ".rsds" -or
                $item.Extension -eq ".rsd")
            {
                $relativePath = Clear-Substring -string $item.FullName -substring $sourceFolder.FullName.TrimEnd("\") -position front
                $relativePath = Clear-Substring -string $relativePath -substring ("\" + $item.Name) -position back
                $relativePath = $relativePath.replace("\", "/")
                
                if ($Destination -eq "/" -and $relativePath -ne "")
                {
                    $parentFolder = $relativePath
                }
                else
                {
                    $parentFolder = $Destination + $relativePath
                }
                
                try { Write-RsCatalogItem -proxy $Proxy -Path $item.FullName -Destination $parentFolder -ErrorAction Stop }
                catch { throw (New-Object System.Exception("Failed to create catalog item from '$($item.FullName)' in '$parentFolder': $($_.Exception)", $_.Exception))}
            }
        }
    }
}
