# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<#
.SYNOPSIS
    This downloads catalog items from a report server to disk.

.DESCRIPTION
    This downloads catalog items from a report server to disk.
    Currently supported types to download are reports, datasources, datasets and resources.

.PARAMETER ReportServerUri
    Specify the Report Server URL to your SQL Server Reporting Services Instance.
    Has to be provided if proxy is not provided.

.PARAMETER ReportServerCredentials
    Specify the credentials to use when connecting to your SQL Server Reporting Services Instance.

.PARAMETER proxy
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
                
        [System.Management.Automation.PSCredential]
        $ReportServerCredentials,
        
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
            [Parameter(Mandatory=$True)]
            [string]$TypeName
        )

        if ($TypeName -eq 'Report')
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
            throw 'Unsupported item type! We only support items which are of type Report, Data Set or Data Source'
        }
    }

    if (-not $Proxy)
    {
        $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Credentials $ReportServerCredentials 
    }

    $itemType = $Proxy.GetItemType($Path)
    if ($itemType -eq 'Unknown')
    {
        throw "Make sure item exists at $Path and item is of type Report, DataSet, DataSource or Resource"
    }
    elseif ($itemType -eq 'Resource')
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

    Write-Verbose "Downloading $Path..."
    $bytes = $Proxy.GetItemDefinition($Path)
    
    if (!(Test-Path -Path $Destination))
    {
        Write-Verbose "Creating Folder $Destination..."
        New-Item -ItemType directory -Path $Destination | Out-Null
    }

    $DestinationFullPath = Resolve-Path $Destination
    Write-Verbose "Writing $itemType content to $DestinationFullPath\$fileName..."
    if ($itemType -eq 'DataSource')
    {
        $content = [System.Text.Encoding]::Unicode.GetString($bytes)
        [System.IO.File]::WriteAllText("$DestinationFullPath\$fileName", $content)
    }
    else 
    {
        [System.IO.File]::WriteAllBytes("$DestinationFullPath\$fileName", $bytes)
    }

    Write-Information "$Path was downloaded to $DestinationFullPath\$fileName successfully!"
}