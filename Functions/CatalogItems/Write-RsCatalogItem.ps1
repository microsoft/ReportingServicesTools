# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<<<<<<< HEAD
=======
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
>>>>>>> refs/remotes/Microsoft/master

function Write-RsCatalogItem
{
    <#
        .SYNOPSIS
            Uploads an item from disk to a report server.
        
        .DESCRIPTION
            Uploads an item from disk to a report server.
            Currently, we are only supporting Report, DataSource and DataSet for uploads
        
<<<<<<< HEAD
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
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,
        
        [Alias('DestinationFolder')]
        [Parameter(Mandatory = $True)]
=======
        [Alias('FullName')]
        [Parameter(Mandatory=$True,ValueFromPipeline = $true,ValueFromPipelinebyPropertyname = $true)]
        [string[]]
        $Path,
        
        [Alias('Destination')]
        [Parameter(Mandatory=$True)]
>>>>>>> refs/remotes/Microsoft/master
        [string]
        $RsFolder,
        
        [Alias('Override')]
        [switch]
<<<<<<< HEAD
        $Overwrite,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
=======
        $OverWrite
>>>>>>> refs/remotes/Microsoft/master
    )
    
    Begin
    {
<<<<<<< HEAD
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
=======
    
        if(-not $Proxy)
        {
            $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Credentials $ReportServerCredentials 
>>>>>>> refs/remotes/Microsoft/master
        }
        #endregion Utility Function
        
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }
<<<<<<< HEAD
    
=======

>>>>>>> refs/remotes/Microsoft/master
    Process
    {
        foreach ($item in $Path)
        {
<<<<<<< HEAD
            #region Manage Paths
            if (!(Test-Path $item))
            {
                throw "No item found at the specified path: $item!"
=======
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
>>>>>>> refs/remotes/Microsoft/master
            }
            
            $EntirePath = Resolve-Path $item
            $item = Get-Item $EntirePath
            $itemType = Get-ItemType $item.Extension
            $itemName = $item.BaseName
            
            
            if ($Destination -eq "/")
            {
<<<<<<< HEAD
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
                    try
                    {
                        [xml]$content = Get-Content -Path $EntirePath -ErrorAction Stop
                    }
                    catch
                    {
                        throw (New-Object System.Exception("Failed to access XML content of '$EntirePath': $($_.Exception.Message)", $_.Exception))
                    }
                    if ($content.DataSourceDefinition -eq $null)
                    {
                        throw "Data Source Definition not found in the specified file: $EntirePath!"
                    }
                    
                    $NewRsDataSourceParam = @{
                        Proxy = $Proxy
                        Destination = $Destination
                        Name = $itemName
                        Extension = $content.DataSourceDefinition.Extension
                        ConnectionString = $content.DataSourceDefinition.ConnectString
                        Disabled = ("false" -like $content.DataSourceDefinition.Enabled)
                        CredentialRetrieval = 'None'
                        Overwrite = $Overwrite
                    }
                    
                    New-RsDataSource @NewRsDataSourceParam
                }
                #endregion Upload DataSource
                
                #region Upload other stuff
                else
                {
                    $bytes = [System.IO.File]::ReadAllBytes($EntirePath)
                    $warnings = $null
                    try
                    {
                        $Proxy.CreateCatalogItem($itemType, $itemName, $Destination, $Overwrite, $bytes, $null, [ref]$warnings) | Out-Null
                    }
                    catch
                    {
                        throw (New-Object System.Exception("Failed to create catalog item: $($_.Exception.Message)", $_.Exception))
                    }
                }
                #endregion Upload other stuff
                
                Write-Verbose "$EntirePath was uploaded to $Destination successfully!"
            }
        }
    }
}
=======
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
>>>>>>> refs/remotes/Microsoft/master
