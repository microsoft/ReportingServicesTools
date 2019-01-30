# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Write-RsRestFolderContent
{
    <#
        .SYNOPSIS
            This command uploads an item from disk to a report server.

        .DESCRIPTION
            This command uploads an item from disk to a report server.

        .PARAMETER Path
            Path to item to upload on disk.

        .PARAMETER RsFolder
            Folder on reportserver to upload the item to.

        .PARAMETER Overwrite
            Overwrite the old entry, if an existing catalog item with same name exists at the specified destination.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v1.0", "v2.0".
            NOTE:
                - v1.0 of REST Endpoint is not supported by Microsoft and is for SSRS 2016.
                - v2.0 of REST Endpoint is supported by Microsoft and is for SSRS 2017, PBIRS October 2017 and newer releases.

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Write-RsRestFolderContent -Path 'c:\reports' -RsFolder '/'
            
            Description
            -----------
            Uploads all the items found under 'C:\reports' to folder '/' using v2.0 REST Endpoint of Report Server located at http://localhost/reports.

        .EXAMPLE
            Write-RsRestFolderContent -Path 'c:\reports' -RsFolder '/' -RestApiVersion 'v1.0'
            
            Description
            -----------
            Uploads all the items found under 'C:\reports' to folder '/' using v1.0 REST Endpoint of Report Server located at http://localhost/reports.

        .EXAMPLE
            Write-RsRestFolderContent -WebSession $mySession -Path 'c:\reports' -RsFolder '/'
            
            Description
            -----------
            Uploads all the items found under 'C:\reports' to folder '/' using v2.0 REST Endpoint of the Report Server identified by the WebSession object.

        .EXAMPLE
            Write-RsRestFolderContent -ReportPortalUri 'http://myserver/reports' -Path 'c:\reports' -RsFolder '/'
            
            Description
            -----------
            Uploads all the items found under 'C:\reports' to folder '/' using v2.0 REST Endpoint of the Report Server located at http://myserver/reports.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,

        [switch]
        $Recurse,

        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,

        [Alias('Override')]
        [switch]
        $Overwrite,

        [string]
        $ReportPortalUri,

        [Alias('ApiVersion')]
        [ValidateSet("v1.0", "v2.0")]
        [string]
        $RestApiVersion = "v2.0",

        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )
    Begin
    {
        $WebSession = New-RsRestSessionHelper -BoundParameters $PSBoundParameters
        $ReportPortalUri = Get-RsPortalUriHelper -WebSession $WebSession
        $catalogItemsUri = $ReportPortalUri + "api/$RestApiVersion/CatalogItems"
        $folderUri = $ReportPortalUri + "api/$RestApiVersion/Folders(Path='{0}')"
    }
    Process
    {
        if (!(Test-Path -Path $Path -PathType Container))
        {
            throw "No folder found at $Path!"
        }
        $sourceFolder = Get-Item $Path

        if ($Recurse)
        {
            $items = Get-ChildItem -Path $Path -Recurse
        }
        else
        {
            $items = Get-ChildItem -Path $Path
        }

        foreach ($item in $items)
        {
            if (($item.PSIsContainer) -and $Recurse)
            {
                $relativePath = Clear-Substring -string $item.FullName -substring $sourceFolder.FullName.TrimEnd("\") -position front
                $relativePath = Clear-Substring -string $relativePath -substring ("\" + $item.Name) -position back
                $relativePath = $relativePath.replace("\", "/")

                $folderUriPath = $null
                $folderExists = $null
                $folderInfo = $null
                if ($RsFolder -eq "/" -and $relativePath -ne "")
                {
                    $parentFolder = $relativePath
                    $folderUriPath = "$RsFolder/$($item.name)"
                }
                else
                {
                    $parentFolder = $RsFolder + $relativePath
                    if ($RsFolder -eq "/")
                    {
                        $folderUriPath = $RsFolder + $($item.name)
                    }
                    else
                    {
                        $folderUriPath = "$RsFolder/$($item.name)"
                    }
                }

                $uri = [String]::Format($folderUri, $folderUriPath)

                try
                {
                    # Try to get folder info
                    if ($Credential -ne $null)
                    {
                        $response = Invoke-WebRequest -Uri $uri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
                    }
                    else
                    {
                        $response = Invoke-WebRequest -Uri $uri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
                    }

                    # parsing response to get folder name
                    $folderInfo = ConvertFrom-Json $response.Content
                    if ($folderInfo.Name -eq $item.Name)
                    {
                        $folderExists = $true
                    }
                }
                catch
                {
                    # Folder not found (404)
                    if ($_.Exception.Response -ne $null -and $_.Exception.Response.StatusCode -eq 404)
                    {
                        $folderExists = $false
                    }
                }

                if ($folderExists)
                {
                    Write-Verbose "Folder $($item.Name) already exits. Skipping."
                }
                else
                {
                    New-RsRestFolder -WebSession $WebSession -RestApiVersion $RestApiVersion -FolderName $item.Name -RsFolder $parentFolder | Out-Null
                }
            }

            if ($item.Extension -ne "")
            {
                $relativePath = Clear-Substring -string $item.FullName -substring $sourceFolder.FullName.TrimEnd("\") -position front
                $relativePath = Clear-Substring -string $relativePath -substring ("\" + $item.Name) -position back
                $relativePath = $relativePath.replace("\", "/")

                if ($RsFolder -eq "/" -and $relativePath -ne "")
                {
                    $parentFolder = $relativePath
                }
                else
                {
                    $parentFolder = $RsFolder + $relativePath
                }

                try
                {
                    Write-RsRestCatalogItem -WebSession $WebSession -RestApiVersion $RestApiVersion -Path $item.FullName -RsFolder $parentFolder -Overwrite:$Overwrite -Credential $Credential
                }
                catch
                {
                    Write-Error "Failed to create catalog item from '$($item.FullName)' in '$parentFolder': If the catalog item already exists (error: (409) Conflict), you can specify the -Overwrite parameter. $($_.Exception)"
                }
            }
        }
    }

}
