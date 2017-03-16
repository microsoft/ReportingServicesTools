# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Out-RsFolderContent
{
    <#
        .SYNOPSIS
            This downloads catalog items from a folder to disk
        
        .DESCRIPTION
            This downloads catalog items from a folder server to disk.
            Currently the script only downloads reports, datasources, datasets and resources.
        
        .PARAMETER Recurse
            Recursively download subfolders.
        
        .PARAMETER Path
            Path to folder on report server to download catalog items from.
        
        .PARAMETER Destination
            Folder to download catalog items to.
    
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
            Out-RsFolderContent -ReportServerUri 'http://localhost/reportserver_sql2012' -Path /MonthlyReports -Destination C:\reports\MonthlyReports
            
            Description
            -----------
            Downloads catalogitems from /MonthlyReports into folder C:\reports\MonthlyReports
    #>
    [CmdletBinding()]
    param(
        [switch]
        $Recurse,
        
        [Alias('ItemPath')]
        [Parameter(Mandatory = $True)]
        [string]
        $Path,
        
        [ValidateScript({ Test-Path $_ -PathType Container })]
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
    
    $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    
    $GetRsFolderContentParam = @{
        Proxy = $Proxy
        Path = $Path
        Recurse = $Recurse
        ErrorAction = 'Stop'
    }
    
    try
    {
        $items = Get-RsFolderContent @GetRsFolderContentParam
    }
    catch
    {
        throw (New-Object System.Exception("Failed to retrieve items in '$Path': $($_.Exception.Message)", $_.Exception))
    }
    
    $Destination = Resolve-Path $Destination
    
    foreach ($item in $items)
    {
        if (($item.TypeName -eq 'Folder') -and $Recurse)
        {
            $relativePath = $item.Path
            if($Path -ne "/")
            {
                $relativePath = Clear-Substring -string $relativePath -substring $Path -position front
            }
            $relativePath = $relativePath.Replace("/", "\")
            
            $newFolder = $Destination + $relativePath
            Write-Verbose "Creating folder $newFolder"
            New-Item $newFolder -ItemType Directory -Force | Out-Null
            Write-Verbose "Folder: $newFolder was created successfully."
        }
        
        if ($item.TypeName -eq "Resource" -or 
            $item.TypeName -eq "Report" -or 
            $item.TypeName -eq "DataSource" -or 
            $item.TypeName -eq "DataSet")
        {
            # We're relying on the fact that the implementation of Get-RsCatalogItems will show us the folder before their content, 
            # when using the -recurse option, so we can assume that any subfolder will be created before we download the items it contains
            $relativePath = $item.Path
            if($Path -ne "/")
            {
                $relativePath = Clear-Substring -string $relativePath -substring $Path -position front
            }
            $relativePath = Clear-Substring -string $relativePath -substring ("/" + $item.Name) -position back
            $relativePath = $relativePath.replace("/", "\")

            $folder = $Destination + $relativePath
            Out-RsCatalogItem -proxy $proxy -Path $item.Path -Destination $folder
        }
    }
}
