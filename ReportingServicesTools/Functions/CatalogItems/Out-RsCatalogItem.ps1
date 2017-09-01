# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Out-RsCatalogItem
{
    <#
        .SYNOPSIS
            This downloads catalog items from a report server to disk.
        
        .DESCRIPTION
            This downloads catalog items from a report server to disk.
            Currently supported types to download are reports, datasources, datasets and resources.
        
        .PARAMETER RsItem
            Path to catalog item to download.
        
        .PARAMETER Destination
            Folder to download catalog item to.
        
        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.
        
        .EXAMPLE
            Out-RsCatalogItem -ReportServerUri 'http://localhost/reportserver_sql2012' -RsItem /Report -Destination C:\reports
            
            Description
            -----------
            Download catalog item 'Report' to folder 'C:\reports'.

        .EXAMPLE
            Get-RsFolderContent -ReportServerUri http://localhost/ReportServer -RsItem '/SQL Server Performance Dashboard' | 
            WHERE Name -Like Wait* | 
            Out-RsCatalogItem -ReportServerUri http://localhost/ReportServer -Destination c:\SQLReports
   
    Description
    -----------
    Downloads all catalog items from folder '/SQL Server Performance Dashboard' with a name that starts with 'Wait' to folder 'C:\SQLReports'. 			
    #>
    [CmdletBinding()]
    param (
        [Alias('ItemPath', 'Path', 'RsFolder')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $RsItem,
        
        [ValidateScript({ Test-Path $_ -PathType Container})]
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
    
    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        
        $DestinationFullPath = Convert-Path $Destination
    }
    
    Process
    {
        #region Processing each path passed to it
        foreach ($item in $RsItem)
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
