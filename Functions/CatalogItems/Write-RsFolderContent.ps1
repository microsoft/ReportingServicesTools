# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<#
.SYNOPSIS
    Uploads all items in a folder on disk to a report server.

.DESCRIPTION
    Uploads all items in a folder on disk to a report server.
    Currently, we are only supporting Report, DataSource and DataSet for uploads

.PARAMETER ReportServerUri
    Specify the Report Server URL to your SQL Server Reporting Services Instance.
    Has to be provided if proxy is not provided.

.PARAMETER ReportServerCredentials
    Specify the credentials to use when connecting to your SQL Server Reporting Services Instance.

.PARAMETER proxy
    Report server proxy to use. 
    Has to be provided if ReportServerUri is not provided.

.PARAMETER Path
    Path to folder which contains items to upload on disk.

.PARAMETER RsFolder
    Folder on reportserver to upload the item to.

.EXAMPLE
    Write-RsFolderContent -ReportServerUri 'http://localhost/reportserver_sql2012' -Path c:\monthlyreports -RsFolder /monthlyReports
   
    Description
    -----------
    Uploads all reports under c:\monthlyreports to folder /monthlyReports.
#>

function Write-RsFolderContent()
{
    param(
        [string]
        $ReportServerUri = 'http://localhost/reportserver',
                
        [System.Management.Automation.PSCredential]
        $ReportServerCredentials,
        $Proxy,
        
        [switch]
        $Recurse,
        
        [Parameter(Mandatory=$True)]
        [string]
        $Path,
        
        [Alias('DestinationFolder')]
        [Parameter(Mandatory=$True)]
        [string]
        $RsFolder
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

    if($Recurse) { $items = Get-ChildItem $Path -Recurse } else { $items = Get-ChildItem $Path }
    foreach($item in $items)
    {
        if(($item.GetType().Name -eq "DirectoryInfo") -and $Recurse)
        {
            $relativePath = Clear-Substring -string $item.FullName -substring $sourceFolder.FullName.TrimEnd("\") -position front
            $relativePath = Clear-Substring -string $relativePath -substring ("\" + $item.Name) -position back
            $relativePath = $relativePath.replace("\", "/")
            if($RsFolder -eq "/" -and $relativePath -ne "")
            {
                $parentFolder = $relativePath
            }
            else 
            {
                $parentFolder = $RsFolder + $relativePath               
            }

            Write-Verbose "Creating folder $parentFolder/$($item.Name)"
            $Proxy.CreateFolder($item.Name, $parentFolder, $null) | Out-Null
        }

        if($item.Extension -eq ".rdl" -or
           $item.Extension -eq ".rsds" -or
           $item.Extension -eq ".rsd")
        {
            $relativePath = Clear-Substring -string $item.FullName -substring $sourceFolder.FullName.TrimEnd("\") -position front
            $relativePath = Clear-Substring -string $relativePath -substring ("\" + $item.Name) -position back
            $relativePath = $relativePath.replace("\", "/")

            if($RsFolder -eq "/" -and $relativePath -ne "")
            {
                $parentFolder = $relativePath
            }
            else 
            {
                $parentFolder = $RsFolder + $relativePath               
            }
            
            Write-RsCatalogItem -proxy $Proxy -Path $item.FullName -RsFolder $parentFolder
        }
    }
}
