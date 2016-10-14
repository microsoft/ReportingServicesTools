# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<#
.SYNOPSIS
    Uploads all items in a folder on disk to a report server.

.DESCRIPTION
    Uploads all items in a folder on disk to a report server.
    Currently, we are only supporting Report, DataSource and DataSet for uploads

.PARAMETER ReportServerUri (optional)
    Specify the Report Server URL to your SQL Server Reporting Services Instance.
    Has to be provided if proxy is not provided.

.PARAMETER ReportServerUsername (optional)
    Specify the user name to use when connecting to your SQL Server Reporting Services Instance.

.PARAMETER ReportServerPassword (optional)
    Specify the password to use when connecting to your SQL Server Reporting Services Instance.

.PARAMETER proxy (optional)
    Report server proxy to use. 
    Has to be provided if ReportServerUri is not provided.

.PARAMETER Path
    Path to folder which contains items to upload on disk.

.PARAMETER DestinationFolder
    Folder on reportserver to upload the item to.

.EXAMPLE
    Write-RsFolderContent -ReportServerUri 'http://localhost/reportserver_sql2012' -Path c:\monthlyreports -DestinationFolder /monthlyReports
   
    Description
    -----------
    Uploads all reports under c:\monthlyreports to folder /monthlyReports.
#>

function Write-RsFolderContent()
{
    param(
        [string]
        $ReportServerUri = 'http://localhost/reportserver',
        
        [string]
        $ReportServerUsername,
        
        [string]
        $ReportServerPassword,
        $Proxy,
        
        [switch]
        $Recurse,
        
        [Parameter(Mandatory=$True)]
        [string]
        $Path,
        
        [Parameter(Mandatory=$True)]
        [string]
        $DestinationFolder
    )

    if(-not $Proxy)
    {
        $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Credentials $ReportServerCredentials 
    }

    $sourceFolder = Get-Item $Path
    if($sourceFolder.GetType().Name -ne "DirectoryInfo")
    {
        throw "$Path is not a folder"
    } 
    
    # Write-Verbose "Creating folder $DestinationFolder"
    # $Proxy.CreateFolder($sourceFolder.Name, $Destination, $null) | Out-Null

    if($Recurse) { $items = Get-ChildItem $Path -Recurse } else { $items = Get-ChildItem $Path }
    foreach($item in $items)
    {
        if(($item.GetType().Name -eq "DirectoryInfo") -and $Recurse)
        {
            $relativePath = $item.FullName.Replace($sourceFolder.FullName.TrimEnd("\"), "").Replace("\" + $item.Name, "")
            $parentFolder = $DestinationFolder + $relativePath.replace("\", "/")
            Write-Verbose "Creating folder $parentFolder/$($item.Name)"
            $Proxy.CreateFolder($item.Name, $parentFolder, $null) | Out-Null
        }

        if($item.Extension -eq ".rdl" -or
           $item.Extension -eq ".rsds" -or
           $item.Extension -eq ".rsd")
        {
            $relativePath = $item.FullName.Replace($sourceFolder.FullName.TrimEnd("\"), "").Replace("\" + $item.Name, "")
            $parentFolder = $DestinationFolder + $relativePath.replace("\", "/")
            Write-RsCatalogItem -proxy $Proxy -Path $item.FullName -Destination $parentFolder
        }
    }
}
