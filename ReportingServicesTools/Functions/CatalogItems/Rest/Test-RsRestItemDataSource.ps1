function Test-RsRestItemDataSource
{
    <#
        .SYNOPSIS
            This function fetches the DataSources from a Paginated or Power BI report and tests them to see if the connection can be made.

        .DESCRIPTION
            This function fetches the DataSources from a Paginated or Power BI report and tests them to see if the connection can be made.
            It tests using the connection information currently stopred in the report.

        .PARAMETER RsReport
            Specify the location of the Power BI report for which the DataSources should be fetched.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your Power BI Report Server Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Test-RsRestItemDataSource -RsReport "/MyReport"
            Description
            -----------
            Fetches all the DataSources for the "MyReport" catalog item found in "/" folder from the Report Server located at http://localhost/reports, and tests them to see if they can connect.

        .EXAMPLE
            Test-RsRestItemDataSource -RsReport "/MyReport" -WebSession $session
            Description
            -----------
            Fetches all the DataSources for the "MyReport" catalog item found in "/" folder from the Report Server located at specificed WebSession object, and tests them to see if they can connect.
        
        .EXAMPLE
            Test-RsRestItemDataSource -RsReport "/MyReport" -ReportPortalUri http://myserver/reports
            Description
            -----------
            Fetches all the DataSources for the "MyReport" catalog item found in "/" folder from the Report Server located at http://myserver/reports, and tests them to see if they can connect.
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

        if ($Credential -ne $null)
        {
            $Report = Get-RsRestItem -ReportPortalUri $ReportPortalUri -RsItem $RsReport -Credential $Credential -Verbose:$false
            $ReportDataSources = Get-RsRestItemDataSource -ReportPortalUri $ReportPortalUri -RsItem $Report.Path -WebSession $WebSession -Credential $Credential -Verbose:$false
        }
        else
        {
            $Report = Get-RsRestItem -ReportPortalUri $ReportPortalUri -RsItem $RsReport -WebSession $WebSession -Verbose:$false
            $ReportDataSources = Get-RsRestItemDataSource -ReportPortalUri $ReportPortalUri -RsItem $Report.Path -WebSession $WebSession -Verbose:$false
        }

        $DataSourceResponses = @()
        if($Report.Type -eq 'Report'){
            <# Paginated #>
            foreach($ReportDataSource in $ReportDataSources){
                $payload = @{
                "DataSourceName" = "$($ReportDataSource.Name)"
                }
                $payloadJson = ConvertTo-Json $payload -Depth 15
        
                $DataSourceConnectionUri = $ReportPortalUri + "api/$RestApiVersion/Reports({0})/Model.CheckDataSourceConnection"
                $DataSourceConnectionUri = [String]::Format($DataSourceConnectionUri, $Report.Id)
                Write-Verbose "$DataSourceConnectionUri"
                if ($Credential -ne $null)
                {
                    $PostResponse = Invoke-RestMethod -Uri $DataSourceConnectionUri -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -Credential $Credential -Verbose:$false
                }
                else
                {
                    $PostResponse = Invoke-RestMethod -Uri $DataSourceConnectionUri -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
                }
                $PostResponse | Add-Member -MemberType NoteProperty -Name ReportName -Value $Report.Name
                $PostResponse | Add-Member -MemberType NoteProperty -Name DataSourceName -Value $ReportDataSource.Name
                $PostResponse | Add-Member -MemberType NoteProperty -Name DataSourceId -Value $ReportDataSource.Id
                $DataSourceResponses += $PostResponse
            }
            return $DataSourceResponses
        }
        elseif($Report.Type -eq 'PowerBIReport'){
            <# PBI #>
            foreach($ReportDataSource in $ReportDataSources){
                $payload = @{
                "DataSourceName" = "$($ReportDataSource.id)"
                }
                $payloadJson = ConvertTo-Json $payload -Depth 15
        
                $DataSourceConnectionUri = $ReportPortalUri + "api/$RestApiVersion/PowerBIReports({0})/Model.CheckDataSourceConnection"
                $DataSourceConnectionUri = [String]::Format($DataSourceConnectionUri, $Report.Id)
                Write-Verbose "$DataSourceConnectionUri"
                if ($Credential -ne $null)
                {
                    $PostResponse = Invoke-RestMethod -Uri $DataSourceConnectionUri -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -Credential $Credential -Verbose:$false
                }
                else
                {
                    $PostResponse = Invoke-RestMethod -Uri $DataSourceConnectionUri -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
                }
                $PostResponse | Add-Member -MemberType NoteProperty -Name ReportName -Value $Report.Name
                $PostResponse | Add-Member -MemberType NoteProperty -Name DataSourceName -Value $ReportDataSource.Name
                $PostResponse | Add-Member -MemberType NoteProperty -Name DataSourceId -Value $ReportDataSource.Id
                $DataSourceResponses += $PostResponse
            }
            return $DataSourceResponses
        }
    }
}
