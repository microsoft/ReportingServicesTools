# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<#
.SYNOPSIS
    This downloads catalog items from a report server to disk.

.DESCRIPTION
    This downloads catalog items from a report server to disk.
    Currently supported types to download are reports, datasources, datasets and resources.

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
    Path to catalog item to download.

.PARAMETER Destination
    Folder to download catalog item to.

.EXAMPLE
    Out-RsCatalogItem -ReportServerUri 'http://localhost/reportserver_sql2012' -Path /Report -Destination C:\reports
   
    Description
    -----------
    Download catalog item 'Report' to folder 'C:\reports'. 
#>

function Out-RsCatalogItem
{
    param(
        [string]
        $ReportServerUri = 'http://localhost/reportserver',
        
        [string]
        $ReportServerUsername,
        
        [string]
        $ReportServerPassword,
        
        $Proxy,

        [Parameter(Mandatory=$True)]
        [string]
        $Path,

        [Parameter(Mandatory=$True)]
        [string]
        $Destination
    )

    function Get-FileExtension
    {
        param(
            [string]$TypeName
        )

        if($TypeName -eq 'Report')
        {
            return '.rdl'
        }
        elseif ($TypeName -eq 'DataSource') 
        {
            return '.rsds'
        }
        elseif ($TypeName -eq 'DataSet')
        {
            return '.rsd'
        } 
        else 
        {
            throw 'Item has to be of type Report, DataSet or DataSource'
        }
    }

    if(-not $Proxy)
    {
        $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Username $ReportServerUsername -Password $ReportServerPassword 
    }

    $itemType = $Proxy.GetItemType($Path)
    if($itemType -eq 'Unknown')
    {
        Throw "Make sure item exists at $Path and item is of type Report, DataSet, DataSource or Resource"
    }
    elseif($itemType -eq 'Resource')
    {
        $itemName = ($path.Split("/"))[-1]
        # Resource contain the file extension as part of their name, so we don't need to call Get-FileExtension
        $fileName = $itemName
    }
    else 
    {
        $itemName = ($path.Split("/"))[-1]
        $fileName = $itemName + (Get-FileExtension $itemType)
    }

    $bytes = $Proxy.GetItemDefinition($Path)
    Write-Verbose "Downloading $Path to $Destination\$fileName"
    if(!(Test-Path -Path $Destination)){
        Write-Verbose "Creating Folder $Destination"
        New-Item -ItemType directory -Path $Destination
    }
    [System.IO.File]::WriteAllBytes("$Destination\$fileName", $bytes)
}