# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<#
.SYNOPSIS
    Uploads an item from disk to a repot server.

.DESCRIPTION
    Uploads an item from disk to a repot server.
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
    Path to item to upload on disk.

.PARAMETER Destination
    Folder on reportserver to upload the item to.

.PARAMETER override (optional)
    Override existing catalog item.

.EXAMPLE
    Write-RsCatalogItem -ReportServerUri 'http://localhost/reportserver_sql2012' -Path c:\reports\monthlyreport.rdl -Destination /monthlyreports
   
    Description
    -----------
    Uploads the report monthlyreport.rdl to folder /monthlyreports
#>

function Write-RsCatalogItem
{
    param(
        [string]
        $ReportServerUri = 'http://localhost/reportserver',
        
        [string]
        $ReportServerUsername,
        
        [string]
        $ReportServerPassword,
        
        $proxy,
        
        [Parameter(Mandatory=$True)]
        [string]
        $Path,
        
        [Parameter(Mandatory=$True)]
        [string]
        $Destination,
        
        [switch]
        $Override
    )

    function Get-ItemType
    {
        param(
            [string]$FileExtension
        )

        if($FileExtension -eq '.rdl')
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
    
    if(-not $Proxy)
    {
        $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Username $ReportServerUsername -Password $ReportServerPassword 
    }

    
    $item = get-item $Path 
    $itemType = Get-ItemType $item.Extension
    $itemName = $item.BaseName
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $warnings = $null
    
    if($Destination -eq "/")
    {
        Write-Output "Uploading $Path to /$($itemName)"
    }
    else 
    {
        Write-Output "Uploading $Path to $Destination/$($itemName)"        
    }
    
    $Proxy.CreateCatalogItem($itemType, $itemName, $Destination, $override, $bytes, $null, [ref]$warnings) | Out-Null
}