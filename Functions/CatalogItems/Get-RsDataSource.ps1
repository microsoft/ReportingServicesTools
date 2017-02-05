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
            Specify the password to use when connecting to your SQL Server Reporting Services Instance.
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
            Get-RsDataSource -ReportServerUri 'http://remote-machine:8080/reportserver_sql16' -Credential 'CaptainAwesome' -Path '/path/to/my/datasource'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://remote-machine:8080/reportserver_sql16 using CaptainAwesome's credentials and retrieve details of data source found at '/path/to/my/datasource'.
        
        .NOTES
            Author:      ???
            Editors:     Friedrich Weinmann
            Created on:  ???
            Last Change: 03.02.2017
            Version:     1.1
            
            Release 1.1 (03.02.2017, Friedrich Weinmann)
            - Removed/Replaced all instances of "Write-Information", in order to maintain PowerShell 3.0 Compatibility.
            - Fixed Parameter help (Don't poison the name with "(optional)", breaks Get-Help)
            - Standardized the parameters governing the Report Server connection for consistent user experience.
            - Renamed the parameter 'DataSourcePath' to 'Path', in order to maintain parameter naming conventions. Added the previous name as an alias, for backwards compatiblity.
            - Changed type of parameter 'Path' to System.String[], to better facilitate pipeline & nonpipeline use
            - Added alias 'ItemPath' for parameter 'Path', for consistency's sake
            - Redesigned to accept pipeline input from 'Path'
            - Replaced "break" with a terminating error. break will crash more than just the function.
    
            Release 1.0 (???, ???)
            - Initial Release
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
        #region Connect to Report Server using Web Proxy
        if (-not $Proxy)
        {
            try
            {
                $splat = @{ }
                if ($PSBoundParameters.ContainsKey('ReportServerUri')) { $splat['ReportServerUri'] = $ReportServerUri }
                if ($PSBoundParameters.ContainsKey('Credential')) { $splat['Credential'] = $Credential }
                $Proxy = New-RSWebServiceProxy @splat
            }
            catch
            {
                throw
            }
        }
        #endregion Connect to Report Server using Web Proxy
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
