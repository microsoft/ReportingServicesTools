# Copyright (c) 2017 Friedrich Weinmann. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Connect-RsReportServer
{
    <#
        .SYNOPSIS
            Connects to a Reporting Server
        
        .DESCRIPTION
            This function can be used to specify default connection information to connect to a Reporting Server, both using WMI or WebProxy.
        
        .PARAMETER ComputerName
            The name of the computer to connect via WMI to.
            Only used for WMI access.
        
        .PARAMETER Instance
            The name of the SQL instance to connect via WMI to.
            Only used for WMI access.
        
        .PARAMETER Version
            The version of the SQL Server whose reporting services you connect to via WMI to.
            Only used for WMI access.
        
        .PARAMETER Credential
            The credentials used to execute all requests. Null it in order to use your current user's credentials.
            Used both for WMI access as well as WebApi access.
        
        .PARAMETER Uri
            The Uri to connect to for accessing the WebApi.
            Only used by the WebApi.
        
        .EXAMPLE
            PS C:\> Connect-RsReportServer -ComputerName "srv-foobar" -Instance "Northwind" -Uri "http://srv-foobar/reportserver/"
    
            Configures WMI access to
            - Target the server "srv-foobar"
            - Target the instance "Northwind"
            
            Configures WebApi access to
            - Connect to the Uri: "http://srv-foobar/reportserver/"
        
        .NOTES
            Author:      Friedrich Weinmann
            Editors:     -
            Created on:  27.01.2017
            Last Change: 27.01.2017
            Version:     1.0
    
            Release 1.0 (27.01.2017, Friedrich Weinmann)
            - Initial Release
    #>
    
    [CmdletBinding()]
    param
    (
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        $ComputerName,
        
        [string]
        $Instance,
        
        [ReportingServicesTools.SqlServerVersion]
        $Version,
        
        [AllowEmptyString()]
        [AllowNull()]
        [PSCredential]
        $Credential,
        
        [string]
        $Uri,
        
        [switch]
        $RegisterProxy
    )
    
    if ($PSBoundParameters.ContainsKey("ComputerName")) { [ReportingServicesTools.ConnectionHost]::ComputerName = $ComputerName }
    if ($PSBoundParameters.ContainsKey("Instance")) { [ReportingServicesTools.ConnectionHost]::Instance = $Instance }
    if ($PSBoundParameters.ContainsKey("Version")) { [ReportingServicesTools.ConnectionHost]::Version = $Version }
    if ($PSBoundParameters.ContainsKey("Credential")) { [ReportingServicesTools.ConnectionHost]::Credential = $Credential }
    if ($PSBoundParameters.ContainsKey("Uri"))
    {
        [ReportingServicesTools.ConnectionHost]::Uri = $Uri
        try
        {
            $proxy = New-RsWebServiceProxy -ReportServerUri ([ReportingServicesTools.ConnectionHost]::Uri) -Credential ([ReportingServicesTools.ConnectionHost]::Credential) -ErrorAction Stop
            [ReportingServicesTools.ConnectionHost]::Proxy = $proxy
        }
        catch
        {
            throw (New-Object System.Exception("Failed to establish proxy connection to $Uri : $($_.Exception.Message)", $_.Exception))
        }
    }
}
