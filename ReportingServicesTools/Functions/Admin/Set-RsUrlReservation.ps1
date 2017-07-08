# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsUrlReservation
{
    <#
        .SYNOPSIS
            This script configures the urls for Report Server
        
        .DESCRIPTION
            This script configures the urls for Report Server
        
        .PARAMETER ReportServerVirtualDirectory
            Specify the name of the virtual directory for the Report Server Endpoint the default is ReportServer, it will configure it as http://myMachine/reportserver
        
        .PARAMETER SenderAddress
            Specify the name of the virtual directory for the Portal Endpoint the default is ReportServer, it will configure it as http://myMachine/reports
        
        .PARAMETER ReportServerInstance
            Specify the name of the SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER ReportServerVersion
            Specify the version of the SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER ComputerName
            The Report Server to target.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Credential
            The credentials with which to connect to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .EXAMPLE
            Set-RsUrlReservation
            Description
            -----------
            This command will configure the Report Server with the default urls for Report Server and for the Portal
        
        .EXAMPLE
            Set-RsEmailSettings -ReportServerVirtualDirectory ReportServer2017 -PortalVirtualDirectory Reports2017 -ReportServerVersion '11' 
            Description
            -----------
            This command will configure the url for the server with http://myMachine/ReportServer2017 and http://myMachine/Reports2017
    #>
    
    [cmdletbinding()]
    param
    (
        [string]
        $ReportServerVirtualDirectory = "ReportServer",
        
        [string]
        $PortalVirtualDirectory="Reports",
        
        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,
        
        [Alias('SqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion,
        
        [string]
        $ComputerName,
        
        [System.Management.Automation.PSCredential]
        $Credential
    )
    
    $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters
    
    try
    {
        $rsWmiObject.SetVirtualDirectory("ReportServerWebService",$ReportServerVirtualDirectory,(Get-Culture).Lcid)
        $rsWmiObject.ReserveURL("ReportServerWebService","http://+:80",(Get-Culture).Lcid)
        if($ReportServerVersion -and $ReportServerVersion -lt 13)
        {
            $reportServerWebappName = "ReportManager"
        }
        else
        {
            $reportServerWebappName = "ReportServerWebApp"
        }
        $rsWmiObject.SetVirtualDirectory($reportServerWebappName,$PortalVirtualDirectory,(Get-Culture).Lcid)
        $rsWmiObject.ReserveURL($reportServerWebappName,"http://+:80",(Get-Culture).Lcid)
    }
    catch
    {
        throw (New-Object System.Exception("Failed to reserve Urls $($_.Exception.Message)", $_.Exception))
    }
    
    if ($result.HRESULT -ne 0)
    {
        throw "Failed to reserve Urls, Errocode: $($result.HRESULT)"
    }
}
