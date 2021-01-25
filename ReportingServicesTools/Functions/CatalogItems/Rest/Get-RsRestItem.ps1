# Copyright (c) 2020 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsRestItem
{
    <#
        .SYNOPSIS
            This function fetches a catalog item from the Report Server
        .DESCRIPTION
            This function fetches a catalog item from the Report Server using the REST API.
        .PARAMETER RsItem
            Specify the location of the catalog item which should be fetched.
        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.
        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".
        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.
        .EXAMPLE
            Get-RsRestItem -RsItem "/MyReport"
            Description
            -----------
            Fetches item object "MyReport" catalog item found in "/" folder from the Report Server located at http://localhost/reports.
        .EXAMPLE
            Get-RsRestItem -RsItem "/MyReport" -WebSession $session
            Description
            -----------
            Fetches item object "MyReport" catalog item found in "/" folder from the Report Server located at specificed WebSession object.
        .EXAMPLE
            Get-RsRestItem -RsItem "/MyReport" -ReportPortalUri http://myserver/reports
            Description
            -----------
            Fetches catalog item "MyReport" catalog item found in "/" folder from the Report Server located at http://myserver/reports.
        .EXAMPLE
            Get-RsRestItem -RsItem "/Finance" -ReportPortalUri http://myserver/reports
            Description
            -----------
            Fetches item "Finance" catalog item, which is a Folder object found in "/" folder from the Report Server located at http://myserver/reports.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [Alias('ItemPath','Path')]
        [string]
        $RsItem,

        [string]
        $ReportPortalUri,

        [Alias('ApiVersion')]
        [ValidateSet("v2.0")]
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
        $catalogItemsUri = $ReportPortalUri + "api/$RestApiVersion/CatalogItems(Path='{0}')"
    }
    Process
    {
        try
        {
            Write-Verbose "Fetching metadata for $RsItem..."
            $catalogItemsUri = [String]::Format($catalogItemsUri, $RsItem)
            if ($Credential -ne $null)
            {
                $response = Invoke-WebRequest -Uri $catalogItemsUri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
            }
            else
            {
                $response = Invoke-WebRequest -Uri $catalogItemsUri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
            }

            $item = ConvertFrom-Json $response.Content
            $itemType = $item.Type
            return [pscustomobject]@{
                Type = $item.Type
                Name = $item.Name
                Size = $item.Size
                CreatedBy = $item.CreatedBy
                CreatedDate = $item.CreatedDate
                ModifiedBy = $item.ModifiedBy
                ModifiedDate = $item.ModifiedDate
                Hidden = $item.Hidden
                Path = $item.Path
                Id   = $item.Id
                ParentFolderId   = $item.ParentFolderId
                Description = $item.Description
                ContentType = $item.ContentType
                Content = $item.Content
                IsFavorite   = $item.IsFavorite
                Roles = $item.Roles
            }
        }
        catch
        {
            throw (New-Object System.Exception("Failed to get for '$RsItem': $($_.Exception.Message)", $_.Exception))
        }
    }
}
New-Alias -Name "Get-RsCatalogItem" -Value Get-RsRestItem -Scope Global
New-Alias -Name "Get-RsItem" -Value Get-RsRestItem -Scope Global