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
        
        .PARAMETER RsFolder
            Path to folder on report server to download catalog items from.
        
        .PARAMETER Destination
            Folder to download catalog items to.
    
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
            Out-RsFolderContent -ReportServerUri 'http://localhost/reportserver_sql2012' -RsFolder /MonthlyReports -Destination C:\reports\MonthlyReports
            
            Description
            -----------
            Downloads catalogitems from /MonthlyReports into folder C:\reports\MonthlyReports
    #>
    [CmdletBinding()]
    param(
        [switch]
        $Recurse,
        
        [Alias('ItemPath', 'Path')]
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,
        
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
        RsFolder = $RsFolder
        Recurse = $Recurse
        ErrorAction = 'Stop'
    }
    
    try
    {
        $items = Get-RsFolderContent @GetRsFolderContentParam
    }
    catch
    {
        throw (New-Object System.Exception("Failed to retrieve items in '$RsFolder': $($_.Exception.Message)", $_.Exception))
    }
    
    $Destination = Convert-Path $Destination

    ## Loop for folders first, because we need to ensure folders are written to disk before we  
    ## attempt to write any files. Otherwise, file writes will randomly fail to write because 
    ## its folder has not been created yet. 
    ## The Solution was to loop and create all folders then work on the files.
    ## Basically, create all folders, then write all the files.
    foreach ($item in $items)
    {
        if (($item.TypeName -eq 'Folder') -and $Recurse)
        {
            $relativePath = $item.Path
            if($RsFolder -ne "/")
            {
                $relativePath = Clear-Substring -string $relativePath -substring $RsFolder -position front
            }
            $relativePath = $relativePath.Replace("/", "\")
            
            $newFolder = $Destination + $relativePath
            Write-Verbose "Creating folder $newFolder"
            New-Item $newFolder -ItemType Directory -Force | Out-Null
            Write-Verbose "Folder: $newFolder was created successfully."
        }
    } ## End Folder Loop
    
   ## Loop for non-folders.
   foreach ($item in $items)
   {     
        if ($item.TypeName -eq "Resource" -or 
            $item.TypeName -eq "Report" -or 
            $item.TypeName -eq "DataSource" -or 
            $item.TypeName -eq "DataSet"   -or 
            $item.TypeName -eq "Component")
        {
            # TODO: REMOVE this comment below. This is the comment that caused me to look for a solution.
            # We're relying on the fact that the implementation of Get-RsFolderContent will show us the folder before their content, 
            # when using the -recurse option, so we can assume that any subfolder will be created before we download the items it contains
            $relativePath = $item.Path
            if($RsFolder -ne "/")
            {
                $relativePath = Clear-Substring -string $relativePath -substring $RsFolder -position front
            }
            $relativePath = Clear-Substring -string $relativePath -substring ("/" + $item.Name) -position back
            $relativePath = $relativePath.replace("/", "\")

            $folder = $Destination + $relativePath
            Out-RsCatalogItem -proxy $proxy -RsFolder $item.Path -Destination $folder
        }
    } ## End non-Folder loop
}
