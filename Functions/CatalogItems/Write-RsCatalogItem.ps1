# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<#
.SYNOPSIS
    Uploads an item from disk to a repot server.

.DESCRIPTION
    Uploads an item from disk to a repot server.
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
    Path to item to upload on disk.

.PARAMETER RsFolder
    Folder on reportserver to upload the item to.

.PARAMETER override
    Override existing catalog item.

.EXAMPLE
    Write-RsCatalogItem -ReportServerUri http://localhost/reportserver_sql2012 -Path c:\reports\monthlyreport.rdl -RsFolder /financereports
   
    Description
    -----------
    Uploads the report monthlyreport.rdl to folder /financereports

.EXAMPLE
    Write-RsCatalogItem -ReportServerUri 'http://localhost/reportserver_sql2012' -Path c:\reports\monthlyreport.rdl, c:\reports\dailyreport.rdl -RsFolder /financereports
   
    Description
    -----------
    Uploads the monthlyreport.rdl and dailyreport.rdl report to folder /financereports

.EXAMPLE
    Write-RsCatalogItem -ReportServerUri 'http://localhost/reportserver_sql2012' -Path ( dir c:\reports -filter *.rdl) -RsFolder /financereports
   
    Description
    -----------
    Uploads all of the .rdl files to folder /financereports

#>

function Write-RsCatalogItem
{
    param(
        [string]
        $ReportServerUri = 'http://localhost/reportserver',
                
        [System.Management.Automation.PSCredential]
        $ReportServerCredentials,
        
        $Proxy,
        
        [Alias('FullName')]
        [Parameter(Mandatory=$True,ValueFromPipeline = $true,ValueFromPipelinebyPropertyname = $true)]
        [string[]]
        $Path,
        
        [Alias('Destination')]
        [Parameter(Mandatory=$True)]
        [string]
        $RsFolder,
        
        [Alias('Override')]
        [switch]
        $OverWrite
    )
    
    Begin
    {
    
        if(-not $Proxy)
        {
            $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Credentials $ReportServerCredentials 
        }
    }

    Process
    {
        foreach ($item in $Path)
        {
            if (!(Test-Path $Path))
            {
                throw "No item found at the specified path: $Path!"
            }

            $EntirePath = Resolve-Path $item
            $item = Get-Item $EntirePath 
            $itemType = Get-ItemType $item.Extension
            $itemName = $item.BaseName
    
    
            if($RsFolder -eq "/")
            {
                Write-Verbose "Uploading $EntirePath to /$($itemName)"
            }
            else 
            {
                Write-Verbose "Uploading $EntirePath to $RsFolder/$($itemName)"        
            }
    
            if ($itemType -eq 'DataSource') 
            {
                [xml] $content = Get-Content -Path $EntirePath
                if ($content.DataSourceDefinition -eq $null)
                {
                    throw "Data Source Definition not found in the specified file: $EntirePath!"
                }

                $extension = $content.DataSourceDefinition.Extension
                $connectionString = $content.DataSourceDefinition.ConnectString
                $enabled = $content.DataSourceDefinition.Enabled
                $credentialRetrieval = 'None'

                $newDataSourceCmd = "New-RsDataSource -RsFolder $RsFolder -Name $itemName -Extension $extension -CredentialRetrieval $credentialRetrieval"

                if (![String]::IsNullOrEmpty($connectionString))
                {
                    $newDataSourceCmd = $newDataSourceCmd + " -ConnectionString $connectionString"
                }

                if ($OverWrite)
                {
                    if ($enabled -eq $false)
                    {
                        New-RsDataSource -Proxy $Proxy -RsFolder $RsFolder -Name $itemName -Extension $extension -ConnectionString $connectionString -CredentialRetrieval $credentialRetrieval -Disabled -Overwrite | Out-Null
                    }
                    else 
                    {
                        New-RsDataSource -Proxy $Proxy -RsFolder $RsFolder -Name $itemName -Extension $extension -ConnectionString $connectionString -CredentialRetrieval $credentialRetrieval -Overwrite | Out-Null
                    }
                }
                else 
                {
                    if ($enabled -eq $false)
                    {
                        New-RsDataSource -Proxy $Proxy -RsFolder $RsFolder -Name $itemName -Extension $extension -ConnectionString $connectionString -CredentialRetrieval $credentialRetrieval -Disabled | Out-Null
                    }
                    else 
                    {
                        New-RsDataSource -Proxy $Proxy -RsFolder $RsFolder -Name $itemName -Extension $extension -ConnectionString $connectionString -CredentialRetrieval $credentialRetrieval | Out-Null
                    }  
                }
            } 
            else 
            {
                $bytes = [System.IO.File]::ReadAllBytes($EntirePath)
                $warnings = $null
                $Proxy.CreateCatalogItem($itemType, $itemName, $RsFolder, $OverWrite, $bytes, $null, [ref]$warnings) | Out-Null
            }

            Write-Information "$EntirePath was uploaded to $RsFolder successfully!"
        }
    }
}