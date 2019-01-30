# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsDataSource
{
    <#
        .SYNOPSIS
            This script retrieves information about data source on Report Server.
        
        .DESCRIPTION
            This script retrieves information about data source found at the specified location on Report Server.
        
        .PARAMETER Path
            Specify the path to the data source.
        
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
            Get-RsDataSource -Path '/path/to/my/datasource'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and retrieve details of data source found at '/path/to/my/datasource'.
        
        .EXAMPLE
            Get-RsDataSource -ReportServerUri 'http://remote-machine:8080/reportserver_sql16' -Path '/path/to/my/datasource'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://remote-machine:8080/reportserver_sql16 using current user's credentials and retrieve details of data source found at '/path/to/my/datasource'.
        
        .EXAMPLE
            $rsProxy = New-RsWebServiceProxy -ReportServerUri 'http://remote-machine:8080/reportserver_sql16'
            Get-RsDataSource -Proxy $rsProxy -Path '/path/to/my/datasource'
            Description
            -----------
            This command will establish a connection to the Report Server located at $rsProxy using current user's credentials and retrieve details of data source found at '/path/to/my/datasource'.
    #>

    [cmdletbinding()]
    param
    (
        [Alias('ItemPath', 'DataSourcePath')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,
        
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
        foreach ($Item in $Path)
        {
            try
            {
                Write-Verbose "Retrieving data source contents..."
                $Proxy.GetDataSourceContents($Item)
                Write-Verbose "Data source retrieved successfully!"
            }
            catch
            {
                throw (New-Object System.Exception("Exception while retrieving datasource! $($_.Exception.Message)", $_.Exception))
            }
        }
    }
}
