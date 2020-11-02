# Copyright (c) 2020 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsCacheRefreshPlan
{
    <#
        .SYNOPSIS
            This script fetches a catalog item from the Report Server
        .DESCRIPTION
            This script fetches a catalog item from the Report Server using the REST API.
        .PARAMETER RsReport
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
            Get-RsRestItem -RsReport "/MyReport"
            Description
            -----------
            Fetches item object "MyReport" catalog item found in "/" folder from the Report Server located at http://localhost/reports.
        .EXAMPLE
            Get-RsRestItem -RsReport "/MyReport" -WebSession $session
            Description
            -----------
            Fetches item object "MyReport" catalog item found in "/" folder from the Report Server located at specificed WebSession object.
        .EXAMPLE
            Get-RsRestItem -RsReport "/MyReport" -ReportPortalUri http://myserver/reports
            Description
            -----------
            Fetches catalog item "MyReport" catalog item found in "/" folder from the Report Server located at http://myserver/reports.
        .EXAMPLE
            Get-RsRestItem -RsReport "/Finance" -ReportPortalUri http://myserver/reports
            Description
            -----------
            Fetches item "Finance" catalog item, which is a Folder object found in "/" folder from the Report Server located at http://myserver/reports.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true)]
        [Alias('ItemPath','Path', 'RsItem')]
        [string]
        $RsReport,

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
        $catalogItemsUri = $ReportPortalUri + "api/$RestApiVersion/PowerBIReports({0})/CacheRefreshPlans"
    }
    Process
    {
        try
        {
            Write-Verbose "Fetching metadata for $RsReport..."
            if ($Credential -ne $null)
            {
                $Report = Get-RsItem -ReportPortalUri $ReportPortalUri -RsItem $RsReport -WebSession $WebSession -Credential $Credential -Verbose:$false
            }
            else
            {
                $Report = Get-RsItem -ReportPortalUri $ReportPortalUri -RsItem $RsReport -WebSession $WebSession -Verbose:$false
            }

            Write-Verbose "Fetching CacheRefreshPlans for $RsReport..."
            $catalogItemsUri = [String]::Format($catalogItemsUri, $Report.Id)
            if ($Credential -ne $null)
            {
                $response = Invoke-RestMethod -Uri $catalogItemsUri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
            }
            else
            {
                $response = Invoke-RestMethod -Uri $catalogItemsUri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
            }

            $item = $response.value
            return [pscustomobject]@{
                RsReport = $item.CatalogItemPath
                EventType = $item.EventType
                LastRunTime = $item.LastRunTime
                LastStatus = $item.LastStatus
                Description = $item.Description
                Id = $item.Id
                ScheduleDescription = $item.ScheduleDescription
                Owner = $item.Owner
                ModifiedBy = $item.ModifiedBy
                ModifiedDate = $item.ModifiedDate
                Schedule   = $item.Schedule
                ParameterValues   = $item.ParameterValues
            }
        }
        catch
        {
            throw (New-Object System.Exception("Failed to get for '$RsReport': $($_.Exception.Message)", $_.Exception))
        }
    }
}