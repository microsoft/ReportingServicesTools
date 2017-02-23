# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


<<<<<<< HEAD
function Write-RsFolderContent
=======
.DESCRIPTION
    Uploads all items in a folder on disk to a report server.
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
    Path to folder which contains items to upload on disk.

.PARAMETER RsFolder
    Folder on reportserver to upload the item to.

.EXAMPLE
    Write-RsFolderContent -ReportServerUri 'http://localhost/reportserver_sql2012' -Path c:\monthlyreports -RsFolder /monthlyReports
   
    Description
    -----------
    Uploads all reports under c:\monthlyreports to folder /monthlyReports.
#>

function Write-RsFolderContent()
>>>>>>> refs/remotes/Microsoft/master
{
    <#
        .SYNOPSIS
            Uploads all items in a folder on disk to a report server.
        
        .DESCRIPTION
            Uploads all items in a folder on disk to a report server.
            Currently, we are only supporting Report, DataSource and DataSet for uploads
        
        .PARAMETER Recurse
            A description of the Recurse parameter.
        
        .PARAMETER Path
            Path to folder which contains items to upload on disk.
        
        .PARAMETER Destination
            Folder on reportserver to upload the item to.
        
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
            Write-RsFolderContent -ReportServerUri 'http://localhost/reportserver_sql2012' -Path c:\monthlyreports -Destination /monthlyReports
            
            Description
            -----------
            Uploads all reports under c:\monthlyreports to folder /monthlyReports.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [switch]
        $Recurse,
        
        [Parameter(Mandatory = $True)]
        [string]
        $Path,
        
        [Alias('DestinationFolder')]
<<<<<<< HEAD
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
    
    if ($PSCmdlet.ShouldProcess($Path, "Upload all contents in folder $(if ($Recurse) { "and subfolders " })to $Destination"))
=======
        [Parameter(Mandatory=$True)]
        [string]
        $RsFolder
    )

    if(-not $Proxy)
    {
        $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Credentials $ReportServerCredentials 
    }

    $sourceFolder = Get-Item $Path
    if($sourceFolder.GetType().Name -ne "DirectoryInfo")
    {
        throw "$Path is not a folder"
    } 

    if($Recurse) { $items = Get-ChildItem $Path -Recurse } else { $items = Get-ChildItem $Path }
    foreach($item in $items)
>>>>>>> refs/remotes/Microsoft/master
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        
        if(-not (Test-Path $Path -PathType Container))
        {
<<<<<<< HEAD
            throw "$Path is not a folder"
=======
            $relativePath = Clear-Substring -string $item.FullName -substring $sourceFolder.FullName.TrimEnd("\") -position front
            $relativePath = Clear-Substring -string $relativePath -substring ("\" + $item.Name) -position back
            $relativePath = $relativePath.replace("\", "/")
            if($RsFolder -eq "/" -and $relativePath -ne "")
            {
                $parentFolder = $relativePath
            }
            else 
            {
                $parentFolder = $RsFolder + $relativePath               
            }

            Write-Verbose "Creating folder $parentFolder/$($item.Name)"
            $Proxy.CreateFolder($item.Name, $parentFolder, $null) | Out-Null
>>>>>>> refs/remotes/Microsoft/master
        }
        $sourceFolder = Get-Item $Path
        
        if ($Recurse)
        {
<<<<<<< HEAD
            $items = Get-ChildItem $Path -Recurse
        }
        else
        {
            $items = Get-ChildItem $Path
        }
        foreach ($item in $items)
        {
            if (($item.PSIsContainer) -and $Recurse)
=======
            $relativePath = Clear-Substring -string $item.FullName -substring $sourceFolder.FullName.TrimEnd("\") -position front
            $relativePath = Clear-Substring -string $relativePath -substring ("\" + $item.Name) -position back
            $relativePath = $relativePath.replace("\", "/")

            if($RsFolder -eq "/" -and $relativePath -ne "")
>>>>>>> refs/remotes/Microsoft/master
            {
                $relativePath = Clear-Substring -string $item.FullName -substring $sourceFolder.FullName.TrimEnd("\") -position front
                $relativePath = Clear-Substring -string $relativePath -substring ("\" + $item.Name) -position back
                $relativePath = $relativePath.replace("\", "/")
                if ($Destination -eq "/" -and $relativePath -ne "")
                {
                    $parentFolder = $relativePath
                }
                else
                {
                    $parentFolder = $Destination + $relativePath
                }
                
                Write-Verbose "Creating folder $parentFolder/$($item.Name)"
                try
                {
                    $Proxy.CreateFolder($item.Name, $parentFolder, $null) | Out-Null
                }
                catch
                {
                    throw (New-Object System.Exception("Failed to create folder '$($item.Name)' in '$parentFolder': $($_.Exception.Message)", $_.Exception))
                }
            }
            
            if ($item.Extension -eq ".rdl" -or
                $item.Extension -eq ".rsds" -or
                $item.Extension -eq ".rsd")
            {
<<<<<<< HEAD
                $relativePath = Clear-Substring -string $item.FullName -substring $sourceFolder.FullName.TrimEnd("\") -position front
                $relativePath = Clear-Substring -string $relativePath -substring ("\" + $item.Name) -position back
                $relativePath = $relativePath.replace("\", "/")
                
                if ($Destination -eq "/" -and $relativePath -ne "")
                {
                    $parentFolder = $relativePath
                }
                else
                {
                    $parentFolder = $Destination + $relativePath
                }
                
                try
                {
                    Write-RsCatalogItem -proxy $Proxy -Path $item.FullName -Destination $parentFolder -ErrorAction Stop
                }
                catch
                {
                    throw (New-Object System.Exception("Failed to create catalog item from '$($item.FullName)' in '$parentFolder': $($_.Exception)", $_.Exception))
                }
            }
=======
                $parentFolder = $RsFolder + $relativePath               
            }
            
            Write-RsCatalogItem -proxy $Proxy -Path $item.FullName -RsFolder $parentFolder
>>>>>>> refs/remotes/Microsoft/master
        }
    }
}
