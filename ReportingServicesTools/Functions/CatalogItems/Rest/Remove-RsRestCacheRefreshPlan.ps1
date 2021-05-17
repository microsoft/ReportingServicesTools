# Copyright (c) 2020 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Remove-RsRestCacheRefreshPlan {
    <#
        .SYNOPSIS
            This function deletes a CacheRefreshPlan from a report from the Report Server.
        .DESCRIPTION
            This function deletes a CacheRefreshPlan from a report from the Report Server using 
            the REST API.  Alternatively, when a report has multiple CacheRefreshPlans you can specify which 
            CacheRefreshPlan to delete by passing the Id of the CacheRefreshPlan to the -Id parameter.
        .PARAMETER RsReport
            Specify the location of the report which should have its CacheRefreshPlans deleted.
        .PARAMETER Id
            Specify the Id of the CacheRefreshPlan to delete.
        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance or Power BI Report Server Instance.
        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".
        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Remove-RsCacheRefreshPlan -RsReport '/MyReport' 

            Description
            -----------
            Fetches the CacheRefreshPlan of a report named "MyReport" found in "/" folder from the Report Server located at http://localhost/reports, 
            and deletes it.
            NOTE: This only works when the report has a single CacheRefreshPlan.

        .EXAMPLE
            $scheduleID = (Get-RsCacheRefreshPlan -RsReport '/MyReport').ID[0]
            Remove-RsCacheRefreshPlan -ID $scheduleID

            Description
            -----------
            Fetches the CacheRefreshPlan of a report named "MyReport" found in "/" folder from the Report Server and gets the ID of the first Schedule 
            refresh (when multiple are present), then deletes it.
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
        $CacheRefreshPlansUri = $ReportPortalUri + "api/$RestApiVersion/CacheRefreshPlans({0})"
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
                if ($RefreshPlan.Count -le 1)
                {
                    $CacheRefreshPlansUri = [String]::Format($CacheRefreshPlansUri, $RefreshPlan.Id)
                }
                else 
                {
                    Write-Warning "Unable to delete scheduled refresh for $RsReport because multiple CacheRefreshPlans are present."
                }
            }
            Write-Verbose "$($CacheRefreshPlansUri)"
            
            Write-Verbose "Deleting $($RefreshPlan.RsReport)$($Id)..."
            if ($Credential -ne $null)
            {
                $response = Invoke-RestMethod -Uri $CacheRefreshPlansUri -Method Delete -WebSession $WebSession -Credential $Credential -Verbose:$false
            }
            else
            {
                $response = Invoke-RestMethod -Uri $CacheRefreshPlansUri -Method Delete -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
            }
        }
        catch
        {
            throw (New-Object System.Exception("Unable to delete '$($RefreshPlan.RsReport)'  '$($Id)': $($_.Exception.Message)", $_.Exception))
        }
    }
}
New-Alias -Name "Remove-RsPbiReportRefresh" -Value Remove-RsRestCacheRefreshPlan -Scope Global