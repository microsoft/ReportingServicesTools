# Licensed under the MIT License (MIT)

function Get-RsRestDataSource {
    <#
    .SYNOPSIS
    Fetches a data source from the report server

    .DESCRIPTION
    Fetches a data source from the report server

    .PARAMETER RsItem
    Specify the path of the data source to fetch

    .PARAMETER ReportPortalUri
    Specify the Report Portal URL to your SQL Server Reporting Services Instance.

    .PARAMETER RestApiVersion
    Specify the version of REST Endpoint to use. Valid values are: "v2.0".

    .PARAMETER Credential
    Specify the credentials to use when connecting to the Report Server.

    .PARAMETER WebSession
    Specify the session to be used when making calls to REST Endpoint.

    .EXAMPLE
    Get-RsRestDataSource -ReportPortalUri http://localhost/reports -RsItem "/MyDataSource"

    Fetches data source information associated to "MyDataSource" data source found in "/" folder.
    The returned objects properties can be found on https://app.swaggerhub.com/apis/microsoft-rs/SSRS/2.0#/DataSource

    .NOTES
    General notes
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
        $splatInvokeWebRequest = New-RestSessionHelperSplat -BoundParameters $PSBoundParameters
        $ReportPortalUri = Get-RsPortalUriHelper -WebSession $splatInvokeWebRequest.WebSession
        $dsItemsUriFormat = $ReportPortalUri + "api/$RestApiVersion/DataSources(Path='{0}')"
    }
    Process {
        try {
            $dsItemUri = [String]::Format($dsItemsUriFormat, $RsItem)

            Write-Verbose "Retrieving data source contents $dsItemUri ..."
            $response = Invoke-WebRequest @splatInvokeWebRequest -Method 'GET' -Uri $dsItemUri
            $item = ConvertFrom-Json $response.Content

            [PSCustomObject] $item | Select-Object -ExcludeProperty '@odata.context','@odata.type'
        } catch {
            $e = $_
            if ($e.ErrorDetails.Message) {
                $ErrorDetail = ($e.ErrorDetails.Message | ConvertFrom-Json).error
            }
            throw (New-Object System.Exception("Exception while retrieving datasource! $($ErrorDetail.message)", $e.Exception))
        }
    }
}