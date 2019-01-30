# Copyright (c) 2017 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsRestItemDataSource
{
    <#
        .SYNOPSIS
            This script fetches data sources related to a catalog item from the Report Server

        .DESCRIPTION
            This script fetches data sources related to a catalog item from the Report Server

        .PARAMETER RsItem
            Specify the location of the catalog item whose data sources should be fetched.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Get-RsRestItemDataSource -RsItem "/MyReport"

            Description
            -----------
            Fetches item information (including data sources) associated to "MyReport" catalog item found in "/" folder from the Report Server located at http://localhost/reports.

        .EXAMPLE
            Get-RsRestItemDataSource -RsItem "/MyReport" -WebSession $session

            Description
            -----------
            Fetches item information (including data sources) associated to "MyReport" catalog item found in "/" folder from the Report Server located at specificed WebSession object.

        .EXAMPLE
            Get-RsRestItemDataSource -RsItem "/MyReport" -ReportPortalUri http://myserver/reports

            Description
            -----------
            Fetches item information (including data sources) associated to "MyReport" catalog item found in "/" folder from the Report Server located at http://myserver/reports.
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
        $dataSourcesUri = $ReportPortalUri + "api/$RestApiVersion/{0}(Path='{1}')?`$expand=DataSources"
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

            Write-Verbose "Fetching data sources for $RsItem..."
            $dataSourcesUri = [String]::Format($dataSourcesUri, $itemType + "s", $RsItem)

            if ($Credential -ne $null)
            {
                $response = Invoke-WebRequest -Uri $dataSourcesUri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
            }
            else
            {
                $response = Invoke-WebRequest -Uri $dataSourcesUri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
            }

            $itemWithDataSources = ConvertFrom-Json $response.Content
            return $itemWithDataSources.DataSources
        }
        catch
        {
            throw (New-Object System.Exception("Failed to get data sources for '$RsItem': $($_.Exception.Message)", $_.Exception))
        }
    }
}