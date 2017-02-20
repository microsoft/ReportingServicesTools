# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<#
.SYNOPSIS
    This downloads catalog items from a report server to disk.

.DESCRIPTION
    This downloads catalog items from a report server to disk.
    Currently supported types to download are reports, datasources, datasets and resources.
    This function will overwrite files -Destination which have the same name as the items being passed to the command.

.PARAMETER ReportServerUri
    Specify the Report Server URL to your SQL Server Reporting Services Instance.
    Has to be provided if proxy is not provided.

.PARAMETER ReportServerCredentials
    Specify the credentials to use when connecting to your SQL Server Reporting Services Instance.

.PARAMETER proxy
    Report server proxy to use. 
    Has to be provided if ReportServerUri is not provided.

.PARAMETER RsFolder
    Path to catalog item in SSRS to download.

.PARAMETER Destination
    Folder to download catalog item to.

.EXAMPLE
    Out-RsCatalogItem -ReportServerUri http://localhost/reportserver_sql2012 -RsFolder /Report -Destination C:\reports
   
    Description
    -----------
    Download catalog item 'Report' to folder 'C:\reports'.

.EXAMPLE
    Get-RsFolderContent -ReportServerUri http://localhost/ReportServer -RsFolder '/SQL Server Performance Dashboard' | 
    WHERE Name -Like Wait* | 
    Out-RsCatalogItem -ReportServerUri http://localhost/ReportServer -Destination c:\SQLReports
   
    Description
    -----------
    Downloads all catalog items from folder '/SQL Server Performance Dashboard' with a name that starts with 'Wait' to folder 'C:\SQLReports'. 
#>

function Out-RsCatalogItem
{
    param(
        [string]
        $ReportServerUri = 'http://localhost/reportserver',
                
        [System.Management.Automation.PSCredential]
        $ReportServerCredentials,
        
        $Proxy,

        [Alias('Path')]
        [Parameter(Mandatory=$True,ValueFromPipeline = $true,ValueFromPipelinebyPropertyname = $true)]
        [string[]]
        $RsFolder,

        [Parameter(Mandatory=$True)]
        [string]
        $Destination
    )
    Begin
    {

        if (-not $Proxy)
        {
            $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Credentials $ReportServerCredentials 
        }
    }
    
    Process
    {
        foreach ($item in $RsFolder)
        {
            $itemType = $Proxy.GetItemType($item)
            if ($itemType -eq 'Unknown')
            {
                throw "Make sure item exists at $RsFolder and item is of type Report, DataSet, DataSource or Resource"
            }
            elseif ($itemType -eq 'Resource')
            {
                $itemName = ($RsFolder.Split("/"))[-1]
                # Resource contain the file extension as part of their name, so we don't need to call Get-FileExtension
                $fileName = $itemName
            }
            else 
            {
                $itemName = ($RsFolder.Split("/"))[-1]
                $fileName = $itemName + (Get-FileExtension $itemType)
            }

            Write-Verbose "Downloading $RsFolder..."
            $bytes = $Proxy.GetItemDefinition($RsFolder)
    
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

            Write-Information "$RsFolder was downloaded to $DestinationFullPath\$fileName successfully!"
        }
    }
}