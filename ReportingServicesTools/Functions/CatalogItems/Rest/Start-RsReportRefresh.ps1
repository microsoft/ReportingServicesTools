# Copyright (c) 2020 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Start-RsReportRefresh
{
    <#
        .SYNOPSIS
            This function fetches the CacheRefreshPlans of a report from the Report Server, and refreshes them.
        .DESCRIPTION
            This function fetches the CacheRefreshPlans of a report from the Report Server, and refreshes them using the REST API.
        .PARAMETER RsReport
            Specify the location of the report which should have its CacheRefreshPlans fetched & refreshed.
        .PARAMETER Id
            Specify the Id of the CacheRefreshPlan to start ferfreshing.
        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance or Power BI Report Server Instance.
        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".
        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.
        .EXAMPLE
            Start-RsReportRefresh -RsReport "/MyReport"

            Description
            -----------
            Fetches the CacheRefreshPlans of a report named "MyReport" found in "/" folder from the Report Server located at http://localhost/reports, 
            and refreshes them.

        .EXAMPLE
            Get-RsCacheRefreshPlan -RsReport '/MyReport' | Start-RsReportRefresh

            Description
            -----------
            Fetches the CacheRefreshPlans of a report named "MyReport" found in "/" folder from the Report Server located at http://localhost/reports, 
            and refreshes them.

        .EXAMPLE
            Start-RsReportRefresh -RsReport "/MyReport" -WebSession $session

            Description
            -----------
            Fetches the CacheRefreshPlans of a report named "MyReport" catalog item found in "/" folder from the Report Server located at specificed WebSession object, 
            and refreshes them.

        .EXAMPLE
            Start-RsReportRefresh -RsReport "/MyReport" -ReportPortalUri http://myserver/reports

            Description
            -----------
            Fetches the CacheRefreshPlans of a report named "MyReport" found in "/" folder from the Report Server located at http://myserver/reports, 
            and refreshes them.
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('ItemPath','Path', 'RsItem')]
        [string]
        $RsReport,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('CacheRefreshPlan')]
        [string]
        $Id = $null,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
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
        $CacheRefreshPlansUri = $ReportPortalUri + "api/$RestApiVersion/CacheRefreshPlans({0})/Model.Execute"
    }
    Process
    {
        try
        {
            if (-not $RsReport)
            {
                Write-Verbose "Fetching CacheRefreshPlans for Id $Id..."
                $CacheRefreshPlansUri = [String]::Format($CacheRefreshPlansUri, $Id)
            }
            else
            {
                Write-Verbose "Fetching CacheRefreshPlans for $RsReport..."
                if ($Credential -ne $null)
                {
                    $RefreshPlan = Get-RsCacheRefreshPlan -ReportPortalUri $ReportPortalUri -RsReport $RsReport -WebSession $WebSession -Credential $Credential -Verbose:$false
                }
                else
                {
                    $RefreshPlan = Get-RsCacheRefreshPlan -ReportPortalUri $ReportPortalUri -RsReport $RsReport -WebSession $WebSession -Verbose:$false
                }
                $CacheRefreshPlansUri = [String]::Format($CacheRefreshPlansUri, $RefreshPlan.Id)
            }
            Write-Verbose "$($CacheRefreshPlansUri)"
            
            Write-Verbose "Starting Refresh for $($RefreshPlan.RsReport)$($Id)..."
            if ($Credential -ne $null)
            {
                $response = Invoke-RestMethod -Uri $CacheRefreshPlansUri -Method Post -WebSession $WebSession -Credential $Credential -Verbose:$false
            }
            else
            {
                $response = Invoke-RestMethod -Uri $CacheRefreshPlansUri -Method Post -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
            }
        }
        catch
        {
            throw (New-Object System.Exception("Unable to refresh model for '$($RefreshPlan.RsReport)'  '$($Id)': $($_.Exception.Message)", $_.Exception))
        }
    }
}