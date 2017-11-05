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
            Write-RsRestCatalogItem -Path 'c:\reports\monthlyreport.rdl' -RsFolder '/monthlyreports'
            
            Description
            -----------
            Uploads the report 'monthlyreport.rdl' to folder '/monthlyreports' to v1.0 REST Endpoint located at http://localhost/reports/.

        .EXAMPLE
            Write-RsRestCatalogItem -Path 'c:\reports\monthlyreport.rdl' -RsFolder '/monthlyreports' -RestApiVersion 'v1.0'
            
            Description
            -----------
            Uploads the report 'monthlyreport.rdl' to folder '/monthlyreports' to v1.0 REST Endpoint located at http://localhost/reports/.

        .EXAMPLE
            Write-RsRestCatalogItem -WebSession $mySession -Path 'c:\reports\monthlyreport.rdl' -RsFolder '/monthlyreports'
            
            Description
            -----------
            Uploads the report 'monthlyreport.rdl' to folder '/monthlyreports' to v1.0 REST Endpoint.

        .EXAMPLE
            Write-RsRestCatalogItem -ReportPortalUri 'http://myserver/reports' -Path 'c:\reports\monthlyreport.rdl' -RsFolder '/monthlyreports'
            
            Description
            -----------
            Uploads the report 'monthlyreport.rdl' to folder '/monthlyreports' to v1.0 REST Endpoint located at http://myserver/reports.
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
                if ($RsFolder -eq "/" -and $relativePath -ne "")
                {
                    $parentFolder = $relativePath
                }
                else
                {
                    $parentFolder = $RsFolder + $relativePath
                }

                New-RsRestFolder -WebSession $WebSession -RestApiVersion $RestApiVersion -FolderName $item.Name -RsFolder $parentFolder | Out-Null
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

                Write-RsRestCatalogItem -WebSession $WebSession -RestApiVersion $RestApiVersion -Path $item.FullName -RsFolder $parentFolder
            }
        }
    }

}
