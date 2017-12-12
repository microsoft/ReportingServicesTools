# Copyright (c) 2017 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsItemDataSource
{
    <#
        .SYNOPSIS
            This script retrieves embedded data sources for a report or a shared data set on Report Server.
        
        .DESCRIPTION
            This script retrieves embedded data sources for a report or a shared data set on Report Server.
        
        .PARAMETER RsItem
            Specify the path to report or shared data set.
        
        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.
        
        .EXAMPLE
            Get-RsItemDataSource -RsItem '/report'

            Description
            -----------
            This command will fetch data sources associated to '/report' catalog item from the Report Server located at http://localhost/reportserver.
        
        .EXAMPLE
            Get-RsItemDataSource -ReportServerUri 'http://remote-machine:8080/reportserver_sql16' -RsItem '/report

            Description
            -----------
            This command will fetch data sources associated to '/report' catalog item from the Report Server located at http://remote-machine:8080/reportserver_sql16.

        .EXAMPLE
            $rsProxy = New-RsWebServiceProxy (...)
            Get-RsItemDataSource -Proxy $rsProxy -RsItem '/report

            Description
            -----------
            This command will fetch data sources associated to '/report' catalog item from the Report Server located at $rsProxy.
    #>

    [cmdletbinding()]
    param
    (
        [Alias('ItemPath', 'DataSourcePath', 'Path')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string]
        $RsItem,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )

    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }
    Process
    {
        try
        {
            Write-Verbose "Retrieving data sources associated to $RsItem..."
            $Proxy.GetItemDataSources($RsItem)
            Write-Verbose "Data source retrieved successfully!"
        }
        catch
        {
            throw (New-Object System.Exception("Exception while retrieving datasource! $($_.Exception.Message)", $_.Exception))
        }
    }
}