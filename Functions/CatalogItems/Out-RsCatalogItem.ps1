# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<<<<<<< HEAD
=======
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
>>>>>>> refs/remotes/Microsoft/master

function Out-RsCatalogItem
{
    <#
        .SYNOPSIS
            This downloads catalog items from a report server to disk.
        
<<<<<<< HEAD
        .DESCRIPTION
            This downloads catalog items from a report server to disk.
            Currently supported types to download are reports, datasources, datasets and resources.
        
        .PARAMETER Path
            Path to catalog item to download.
        
        .PARAMETER Destination
            Folder to download catalog item to.
        
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
            Out-RsCatalogItem -ReportServerUri 'http://localhost/reportserver_sql2012' -Path /Report -Destination C:\reports
            
            Description
            -----------
            Download catalog item 'Report' to folder 'C:\reports'.
    #>
    [CmdletBinding()]
    param (
        [Alias('ItemPath')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,
        
        [ValidateScript({ Test-Path $_ -PathType Container})]
        [Parameter(Mandatory = $True)]
=======
        $Proxy,

        [Alias('Path')]
        [Parameter(Mandatory=$True,ValueFromPipeline = $true,ValueFromPipelinebyPropertyname = $true)]
        [string[]]
        $RsFolder,

        [Parameter(Mandatory=$True)]
>>>>>>> refs/remotes/Microsoft/master
        [string]
        $Destination,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
<<<<<<< HEAD
    
    Begin
    {
        #region Utility Functions
        function Get-FileExtension
        {
            param (
                [Parameter(Mandatory = $True)]
                [string]
                $TypeName
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
        #endregion Utility Functions
        
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        
        $DestinationFullPath = Resolve-Path $Destination
=======
    Begin
    {

        if (-not $Proxy)
        {
            $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Credentials $ReportServerCredentials 
        }
>>>>>>> refs/remotes/Microsoft/master
    }
    
    Process
    {
<<<<<<< HEAD
        #region Processing each path passed to it
        foreach ($item in $Path)
        {
            #region Retrieving content from Report Server
            try
            {
                $itemType = $Proxy.GetItemType($item)
            }
            catch
            {
                throw (New-Object System.Exception("Failed to retrieve item type of '$item' from proxy: $($_.Exception.Message)", $_.Exception))
            }
            
            switch ($itemType)
            {
                "Unknown"
                {
                    throw "Make sure item exists at $item and item is of type Report, DataSet, DataSource or Resource"
                }
                "Resource"
                {
                    $fileName = ($item.Split("/"))[-1]
                }
                default
                {
                    $fileName = "$(($item.Split("/"))[-1])$(Get-FileExtension -TypeName $itemType)"
                }
            }
            
            Write-Verbose "Downloading $item..."
            try
            {
                $bytes = $Proxy.GetItemDefinition($item)
            }
            catch
            {
                throw (New-Object System.Exception("Failed to retrieve item definition of '$item' from proxy: $($_.Exception.Message)", $_.Exception))
            }
            #endregion Retrieving content from Report Server
            
            #region Writing results to file
            Write-Verbose "Writing $itemType content to $DestinationFullPath\$fileName..."
            try
            {
                if ($itemType -eq 'DataSource')
                {
                    $content = [System.Text.Encoding]::Unicode.GetString($bytes)
                    [System.IO.File]::WriteAllText("$DestinationFullPath\$fileName", $content)
                }
                else
                {
                    [System.IO.File]::WriteAllBytes("$DestinationFullPath\$fileName", $bytes)
                }
            }
            catch
            {
                throw (New-Object System.IO.IOException("Failed to write content to '$DestinationFullPath\$fileName' : $($_.Exception.Message)", $_.Exception))
            }
            
            Write-Verbose "$item was downloaded to $DestinationFullPath\$fileName successfully!"
            #endregion Writing results to file
        }
        #endregion Processing each path passed to it
    }
    
    End
    {
        
    }
}
=======
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
>>>>>>> refs/remotes/Microsoft/master
