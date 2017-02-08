# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<#
.SYNOPSIS
    This downloads catalog items from a folder to disk

.DESCRIPTION
    This downloads catalog items from a folder server to disk.
    Currently the script only downloads reports, datasources, datasets and resources.

.PARAMETER ReportServerUri
    Specify the Report Server URL to your SQL Server Reporting Services Instance.
    Has to be provided if proxy is not provided.

.PARAMETER ReportServerCredentials
    Specify the password to use when connecting to your SQL Server Reporting Services Instance.

.PARAMETER proxy
    Report server proxy to use. 
    Has to be provided if ReportServerUri is not provided.

.PARAMETER Recurse
    Recursively download subfolders.

.PARAMETER Path
    Path to folder on report server to download catalog items from. 

.PARAMETER Destination
    Folder to download catalog items to.

.EXAMPLE
    Out-RsFolderContent -ReportServerUri 'http://localhost/reportserver_sql2012' -Path /MonthlyReports -Destination C:\reports\MonthlyReports
   
    Description
    -----------
    Downloads catalogitems from /MonthlyReports into folder C:\reports\MonthlyReports

#>

function Out-RsFolderContent
{
    param(
        [string]
        $ReportServerUri = 'http://localhost/reportserver',
                
        [System.Management.Automation.PSCredential]
        $ReportServerCredentials,
        
        $Proxy,

        [switch]
        $Recurse,
        
        [Parameter(Mandatory=$True)]
        [string]
        $Path,
        
        [Parameter(Mandatory=$True)]
        [string]
        $Destination
    )

    if (-not $Proxy)
    {
        $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Credentials $ReportServerCredentials 
    }
    
    if ($Recurse) 
    {
        $items = Get-RsCatalogItems -proxy:$Proxy -Path:$Path -Recurse
    }
    else 
    {
        $items = Get-RsCatalogItems -proxy:$Proxy -Path:$Path
    }

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
            mkdir $newFolder -Force | Out-Null
            Write-Information "Folder: $newFolder was created successfully."
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
