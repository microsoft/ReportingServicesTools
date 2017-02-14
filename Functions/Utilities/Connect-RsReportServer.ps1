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
        
        .PARAMETER ReportServerInstance
            The name of the SQL Instance to connect via WMI to.
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
            Connect-RsReportServer -ComputerName "srv-foobar" -ReportServerInstance "Northwind" -Uri "http://srv-foobar/reportserver/"
    
            Configures WMI access to
            - Target the server "srv-foobar"
            - Target the Instance "Northwind"
            
            Configures WebApi access to
            - Connect to the Uri: "http://srv-foobar/reportserver/"
    #>
    
    [CmdletBinding()]
    param
    (
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        $ComputerName,
        
        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,
        
        [Alias('SqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion,
        
        [AllowEmptyString()]
        [AllowNull()]
        [PSCredential]
        $Credential,
        
        [string]
        $Uri,
        
        [switch]
        $RegisterProxy
    )
    
    if ($PSBoundParameters.ContainsKey("ComputerName"))
    {
        [Microsoft.ReportingServicesTools.ConnectionHost]::ComputerName = $ComputerName
    }
    if ($PSBoundParameters.ContainsKey("ReportServerInstance"))
    {
        [Microsoft.ReportingServicesTools.ConnectionHost]::Instance = $ReportServerInstance
    }
    if ($PSBoundParameters.ContainsKey("Version"))
    {
        [Microsoft.ReportingServicesTools.ConnectionHost]::Version = $Version
    }
    if ($PSBoundParameters.ContainsKey("Credential"))
    {
        [Microsoft.ReportingServicesTools.ConnectionHost]::Credential = $Credential
    }
    
    if ($PSBoundParameters.ContainsKey("Uri"))
    {
        [Microsoft.ReportingServicesTools.ConnectionHost]::Uri = $Uri
        try
        {
            $proxy = New-RsWebServiceProxy -ReportServerUri ([Microsoft.ReportingServicesTools.ConnectionHost]::Uri) -Credential ([Microsoft.ReportingServicesTools.ConnectionHost]::Credential) -ErrorAction Stop
            [Microsoft.ReportingServicesTools.ConnectionHost]::Proxy = $proxy
        }
        catch
        {
            throw (New-Object System.Exception("Failed to establish proxy connection to $Uri : $($_.Exception.Message)", $_.Exception))
        }
    }
}
