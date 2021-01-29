function Get-RsRestCacheRefreshPlanHistory
{
    <#
        .SYNOPSIS
            This function fetches the history of CacheRefreshPlan(s) from a Power BI report.

        .DESCRIPTION
            This function fetches the history of CacheRefreshPlan(s) from a Power BI report.

        .PARAMETER RsReport
            Specify the location of the Power BI report for which the CacheRefreshPlans should be fetched.

        .PARAMETER Id
            Specify the Id of the CacheRefreshPlan for a Power BI report which should be fetched.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your Power BI Report Server Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Get-RsRestCacheRefreshPlanHistory -RsReport "/MyReport"
            Description
            -----------
            Fetches the history of all CacheRefreshPlans for the "MyReport" catalog item found in "/" folder from the Report Server located at http://localhost/reports.

        .EXAMPLE
            Get-RsRestCacheRefreshPlanHistory -RsReport "/MyReport" -WebSession $session
            Description
            -----------
            Fetches the history of all CacheRefreshPlans for the "MyReport" catalog item found in "/" folder from the Report Server located at specificed WebSession object.
        
        .EXAMPLE
            Get-RsRestCacheRefreshPlanHistory -RsReport "/MyReport" -ReportPortalUri http://myserver/reports
            Description
            -----------
            Fetches the history of all CacheRefreshPlans for the "MyReport" catalog item found in "/" folder from the Report Server located at http://myserver/reports.

        .EXAMPLE
            Get-RsRestCacheRefreshPlanHistory -Id 'f8796f95-31c8-46fe-b184-4677cbbf5abf' -ReportPortalUri http://myserver/reports
            Description
            -----------
            Fetches the history of all CacheRefreshPlans for the "Finance" report from the Report Server located at http://myserver/reports.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('ItemPath','Path', 'RsItem')]
        [string]
        $RsReport,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]
        $ReportPortalUri,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('CacheRefreshPlan')]
        [string]
        $Id = $null,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('ApiVersion')]
        [ValidateSet("v2.0")]
        [string]
        $RestApiVersion = "v2.0",

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )
    Begin
    {
        $WebSession = New-RsRestSessionHelper -BoundParameters $PSBoundParameters
        $ReportPortalUri = Get-RsPortalUriHelper -WebSession $WebSession
    }
    Process
    {

        if($RsReport){
            if ($Credential -ne $null)
            {
                $CachePlans = Get-RsRestCacheRefreshPlan -ReportPortalUri $ReportPortalUri -RsItem $RsReport -Credential $Credential -Verbose:$false
            }
            else
            {
                $CachePlans = Get-RsRestCacheRefreshPlan -ReportPortalUri $ReportPortalUri -RsItem $RsReport -WebSession $WebSession -Verbose:$false
            }

            foreach($CachePlan in $CachePlans){
                $CacheRefreshPlanUri = $ReportPortalUri + "api/$RestApiVersion/CacheRefreshPlans({0})/History"
                $CacheRefreshPlanUri = [String]::Format($CacheRefreshPlanUri, $CachePlan.Id)
                Write-Verbose "$CacheRefreshPlanUri"
                if ($Credential -ne $null)
                {
                    $response = Invoke-RestMethod -Uri $CacheRefreshPlanUri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
                }
                else
                {
                    $response = Invoke-RestMethod -Uri $CacheRefreshPlanUri -Method Get -WebSession $WebSession -UseDefaultCredentials
                }
                return $response.value
            }
        }

        if($Id){
            $CacheRefreshPlanUri = $ReportPortalUri + "api/$RestApiVersion/CacheRefreshPlans({0})/History"
            $CacheRefreshPlanUri = [String]::Format($CacheRefreshPlanUri, $Id)
            Write-Verbose "$CacheRefreshPlanUri"
            if ($Credential -ne $null)
            {
                $response = Invoke-RestMethod -Uri $CacheRefreshPlanUri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
            }
            else
            {
                $response = Invoke-RestMethod -Uri $CacheRefreshPlanUri -Method Get -WebSession $WebSession -UseDefaultCredentials
            }
            return $response.value
        }
    }
}