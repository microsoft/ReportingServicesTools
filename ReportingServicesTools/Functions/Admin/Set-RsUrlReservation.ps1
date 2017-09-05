# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsUrlReservation
{
    <#
        .SYNOPSIS
            This command configures the urls for Report Server
        
        .DESCRIPTION
            This command configures the urls for Report Server
        
        .PARAMETER ReportServerVirtualDirectory
            Specify the name of the virtual directory for the Report Server Endpoint the default is ReportServer, it will configure it as http://myMachine/reportserver

        .PARAMETER PortalVirtualDirectory
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
            Specify the credentials to use when connecting to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER ListeningPort
            Specify the Listening Port

        .EXAMPLE
            Set-RsUrlReservation
            Description
            -----------
            This command will configure the Report Server with the default urls http://myMachine/ReportServer and http://myMachine/Reports
        
        .EXAMPLE
            Set-RsUrlReservation -ReportServerVirtualDirectory ReportServer2017 -PortalVirtualDirectory Reports2017 
            Description
            -----------
            This command will configure the url for the server with http://myMachine/ReportServer2017 and http://myMachine/Reports2017

        .EXAMPLE
            Set-RsUrlReservation -ReportServerVirtualDirectory ReportServer2017 -PortalVirtualDirectory Reports2017  -ListeningPort 8080
            Description
            -----------
            This command will configure the url for the server with http://myMachine:8080/ReportServer2017 and http://myMachine:8080/Reports2017
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
        $Credential,

        [int]
        $ListeningPort=80
    )
    
    $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters
    
    try
    {
        Write-Verbose "Setting Virtual Directory for ReportServerWebService..."
        $result = $rsWmiObject.SetVirtualDirectory("ReportServerWebService",$ReportServerVirtualDirectory,(Get-Culture).Lcid)
        
        if ($result.HRESULT -ne 0)
        {
            throw "Failed Setting Virtual Directory for ReportServerWebService, Errocode: $($result.HRESULT)"
        }

        Write-Verbose "Reserving Url for ReportServerWebService..."
        $result = $rsWmiObject.ReserveURL("ReportServerWebService","http://+:$ListeningPort",(Get-Culture).Lcid)

        if ($result.HRESULT -ne 0)
        {
            throw "Failed Reserving Url for ReportServerWebService, Errocode: $($result.HRESULT)"
        }

        if($ReportServerVersion -and $ReportServerVersion -lt 13)
        {
            $reportServerWebappName = "ReportManager"
        }
        else
        {
            $reportServerWebappName = "ReportServerWebApp"
        }

        Write-Verbose "Setting Virtual Directory for $reportServerWebappName..."
        $result = $rsWmiObject.SetVirtualDirectory($reportServerWebappName,$PortalVirtualDirectory,(Get-Culture).Lcid)

        if ($result.HRESULT -ne 0)
        {
            throw "Failed Setting Virtual Directory for $reportServerWebappName, Errocode: $($result.HRESULT)"
        }

        Write-Verbose "Reserving Url for $reportServerWebappName..."
        $result = $rsWmiObject.ReserveURL($reportServerWebappName,"http://+:$ListeningPort",(Get-Culture).Lcid)

        if ($result.HRESULT -ne 0)
        {
            throw "Failed Reserving Url for $reportServerWebappName, Errocode: $($result.HRESULT)"
        }


        Write-Verbose "Success!"
    }
    catch
    {
        throw (New-Object System.Exception("Failed to reserve Urls $($_.Exception.Message)", $_.Exception))
    }   
}
