# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Write-RsCatalogItem
{
    <#
        .SYNOPSIS
            Uploads an item from disk to a report server.
        
        .DESCRIPTION
            Uploads an item from disk to a report server.
            Currently, we are only supporting Report, DataSource and DataSet for uploads
        
        .PARAMETER Path
            Path to item to upload on disk.
        
        .PARAMETER RsFolder
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
            Write-RsCatalogItem -ReportServerUri 'http://localhost/reportserver_sql2012' -Path c:\reports\monthlyreport.rdl -RsFolder /monthlyreports
            
            Description
            -----------
            Uploads the report monthlyreport.rdl to folder /monthlyreports
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,
        
        [Alias('DestinationFolder', 'RsFolder')]
        [Parameter(Mandatory = $True)]
        [string]
        $Destination,
        
        [Alias('Override')]
        [switch]
        $Overwrite,
        
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
    }
    
    Process
    {
        foreach ($item in $Path)
        {
            #region Manage Paths
            if (!(Test-Path $item))
            {
                throw "No item found at the specified path: $item!"
            }
            
            $EntirePath = Resolve-Path $item
            $item = Get-Item $EntirePath
            $itemType = Get-ItemType $item.Extension
            $itemName = $item.BaseName
            
            
            if ($Destination -eq "/")
            {
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
