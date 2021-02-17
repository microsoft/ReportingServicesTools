# Copyright (c) 2017 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsRestItemDataModelParameter
{
    <#
        .SYNOPSIS
            This function fetches the Data Model Parameters related to a Catalog Item report from the Report Server. This is currently only applicable to Power BI Reports and only from ReportServer October/2020 or higher.

        .DESCRIPTION
            This function fetches the Data Model Parameters related to a Catalog Item report from the Report Server. This is currently only applicable to Power BI Reports and only from ReportServer October/2020 or higher.

        .PARAMETER RsItem
            Specify the location of the catalog item whose data model parameters should be fetched.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your Power Bi Report Server Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Get-RsRestItemDataModelParameter -RsItem "/MyPbixReport1"

            Description
            -----------
            Fetches data model parameter information associated to "MyReport" catalog item found in "/" folder from the Report Server located at http://localhost/reports.

        .EXAMPLE
            Get-RsRestItemDataModelParameter -RsItem "/MyReport" -WebSession $session

            Description
            -----------
            Fetches data model parameter information associated to "MyReport" catalog item found in "/" folder from the Report Server located at specificed WebSession object.

        .EXAMPLE
            Get-RsRestItemDataModelParameter -RsItem "/MyReport" -ReportPortalUri http://myserver/reports

            Description
            -----------
            Fetches data model parameter information associated to "MyReport" catalog item found in "/" folder from the Report Server located at http://myserver/reports.
        
        .LINK
            https://docs.microsoft.com/en-us/power-bi/report-server/connect-data-source-apis
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $RsItem,

        [string]
        $ReportPortalUri,

        [ValidateSet("v2.0")]
        [string]
        $RestApiVersion = "v2.0",

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
        $parametersUri = $ReportPortalUri + "api/$RestApiVersion/{0}(Path='{1}')?`$expand=DataModelParameters"
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

            Write-Verbose "Fetching parameters for $RsItem..."
            $parametersUri = [String]::Format($parametersUri, $itemType + "s", $RsItem)

            if ($Credential -ne $null)
            {
                $paramResponse = Invoke-WebRequest -Uri $parametersUri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
            }
            else
            {
                $paramResponse = Invoke-WebRequest -Uri $parametersUri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
            }

            Write-Verbose $paramResponse
            $itemWithDataSources = ConvertFrom-Json $paramResponse.Content
            return $itemWithDataSources.DataModelParameters
        }
        catch
        {
            Write-Error "Error fetching parameters for '$RsItem': $($_.Exception.Message)"
            throw (New-Object System.Exception("Failed to get data model parameters for '$RsItem': $($_.Exception.Message)", $_.Exception))
        }
    }
}
New-Alias -Name "Get-RsRestItemDataModelParameters" -Value Get-RsRestItemDataModelParameter -Scope Global