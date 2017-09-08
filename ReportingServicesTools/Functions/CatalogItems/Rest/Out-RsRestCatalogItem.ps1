# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Out-RsRestCatalogItem
{
    <#
        .SYNOPSIS
            This command downloads catalog items from a report server to disk (using REST endpoint). It is for SQL Server Reporting Service 2016 and later.
        
        .DESCRIPTION
            This command downloads catalog items from a report server to disk (using REST endpoint). It is for SQL Server Reporting Service 2016 and later.
        
        .PARAMETER RsItem
            Path to catalog item to download.
        
        .PARAMETER Destination
            Folder to download catalog item to.
        
        .PARAMETER ApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v1.0". 
            NOTE: v1.0 of REST Endpoint is not supported by Microsoft.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.
        
        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Out-RsRestCatalogItem -RsItem '/Report' -Destination 'C:\reports'
            
            Description
            -----------
            Downloads the catalog item 'Report' to folder 'C:\reports' using v1.0 REST Endpoint located at http://localhost/reports.

        .EXAMPLE
            Out-RsRestCatalogItem -RsItem '/Report' -Destination 'C:\reports' -ApiVersion 'v1.0'
            
            Description
            -----------
            Downloads the catalog item 'Report' to folder 'C:\reports' using v1.0 REST Endpoint located at http://localhost/reports.

        .EXAMPLE
            Out-RsRestCatalogItem -WebSession $mySession -RsItem '/Report' -Destination 'C:\reports'

            Description
            -----------
            Downloads the catalog item 'Report' to folder 'C:\reports' using v1.0 REST Endpoint.

        .EXAMPLE
            Out-RsRestCatalogItem -ReportPortalUri 'http://myserver/reports' -RsItem '/Report' -Destination 'C:\reports'
            
            Description
            -----------
            Downloads the catalog item found at '/Report' to folder 'C:\reports' using v1.0 REST Endpoint located at http://myserver/reports.
    #>

    [CmdletBinding()]
    param (
        [Alias('ItemPath', 'Path', 'RsFolder')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $RsItem,
        
        [ValidateScript({ Test-Path $_ -PathType Container})]
        [Parameter(Mandatory = $True)]
        [string]
        $Destination,

        [ValidateSet("v1.0")]
        [string]
        $ApiVersion = "v1.0",
        
        [string]
        $ReportPortalUri,
        
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
        $catalogItemsByPathApi = $ReportPortalUri + "api/$ApiVersion/CatalogItemByPath(path=@path)?@path=%27{0}%27"
    }
    Process
    {
        foreach ($item in $RsItem)
        {
            try
            {
                Write-Verbose "Fetching metadata for $item from server..."
                $url = [string]::Format($catalogItemsByPathApi, $item)
                if ($Credential -ne $null)
                {
                    $response = Invoke-WebRequest -Uri $url -Method Get -Credential $Credential -Verbose:$false
                }
                else
                {
                    $response = Invoke-WebRequest -Uri $url -Method Get -UseDefaultCredentials -Verbose:$false
                }
            }
            catch
            {
                throw (New-Object System.Exception("Error while trying to fetch metadata for $item! Exception: $($_.Exception.Message)", $_.Exception))
            }

            Write-Verbose "Parsing metadata for $item..."
            $itemInfo = ConvertFrom-Json $response.Content

            Out-RsRestCatalogItemId -RsItemInfo $itemInfo -Destination $Destination -ApiVersion $ApiVersion -ReportPortalUri $ReportPortalUri -Credential $Credential -WebSession $WebSession 
        }
    }
}