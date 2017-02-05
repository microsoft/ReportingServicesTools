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
        
        .NOTES
            Author:      ???
            Editors:     Friedrich Weinmann
            Created on:  ???
            Last Change: 03.02.2017
            Version:     1.1
            
            Release 1.1 (03.02.2017, Friedrich Weinmann)
            - Removed/Replaced all instances of "Write-Information", in order to maintain PowerShell 3.0 Compatibility.
            - Fixed Parameter help (Don't poison the name with "(optional)", breaks Get-Help)
            - Standardized the parameters governing the Report Server connection for consistent user experience.
            - Changed type of parameter 'Path' to System.String[], to better facilitate pipeline & nonpipeline use
            - Added alias 'ItemPath' for parameter 'Path', for consistency's sake
            - Redesigned to accept pipeline input from 'Path'
            - BREAKING CHANGE! (well ... somewhat):
              Added Path validation to 'Destination' parameter. The previous implementation was error-prone anyway (it would fail on most cases caught by this change anyway).
              Furthermore, given that this function is a single-item operation, automatically creating folders is outside the scope of this function and should not be added anyway.
    
            Release 1.0 (???, ???)
            - Initial Release
    #>
    [CmdletBinding()]
    param (
        [Alias('ItemPath')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,
        
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
        
        #region Connect to Report Server using Web Proxy
        if (-not $Proxy)
        {
            try
            {
                $splat = @{ }
                if ($PSBoundParameters.ContainsKey('ReportServerUri')) { $splat['ReportServerUri'] = $ReportServerUri }
                if ($PSBoundParameters.ContainsKey('Credential')) { $splat['Credential'] = $Credential }
                $Proxy = New-RSWebServiceProxy @splat
            }
            catch
            {
                throw
            }
        }
        #endregion Connect to Report Server using Web Proxy
        
        $DestinationFullPath = Resolve-Path $Destination
    }
    
    Process
    {
        #region Processing each path passed to it
        foreach ($item in $Path)
        {
            #region Retrieving content from Report Server
            try { $itemType = $Proxy.GetItemType($item) }
            catch { throw (New-Object System.Exception("Failed to retrieve item type of '$item' from proxy: $($_.Exception.Message)", $_.Exception)) }
            
            switch ($itemType)
            {
                "Unknown" { throw "Make sure item exists at $item and item is of type Report, DataSet, DataSource or Resource" }
                "Resource" { $fileName = ($item.Split("/"))[-1] }
                default { $fileName = "$(($item.Split("/"))[-1])$(Get-FileExtension -TypeName $itemType)" }
            }
            
            Write-Verbose "Downloading $item..."
            try { $bytes = $Proxy.GetItemDefinition($item) }
            catch { throw (New-Object System.Exception("Failed to retrieve item definition of '$item' from proxy: $($_.Exception.Message)", $_.Exception)) }
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