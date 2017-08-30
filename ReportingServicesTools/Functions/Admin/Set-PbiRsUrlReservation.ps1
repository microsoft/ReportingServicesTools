# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-PbiRsUrlReservation
{
    <#
        .SYNOPSIS
            This command configures the urls for PBI Report Server
        
        .DESCRIPTION
            This command configures the urls for PBI Report Server
        
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
            The credentials with which to connect to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER ListeningPort
            Specify the Listening Port

        .EXAMPLE
            Set-PbiRsUrlReservation
            Description
            -----------
            This command will configure the Report Server with the default urls http://myMachine/ReportServer and http://myMachine/Reports
        
        .EXAMPLE
            Set-PbiRsUrlReservation -ReportServerVirtualDirectory ReportServer2017 -PortalVirtualDirectory Reports2017 
            Description
            -----------
            This command will configure the url for the server with http://myMachine/ReportServer2017 and http://myMachine/Reports2017

        .EXAMPLE
            Set-PbiRsUrlReservation -ReportServerVirtualDirectory ReportServer2017 -PortalVirtualDirectory Reports2017  -ListeningPort 8080
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
    
    $pbirsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters
    
    try
    {
        Set-RsUrlReservation -ReportServerVirtualDirectory $ReportServerVirtualDirectory -PortalVirtualDirectory $PortalVirtualDirectory -ReportServerInstance $ReportServerInstance -ReportServerVersion $ReportServerVersion -ComputerName $ComputerName -Credential $Credential -ListeningPort $ListeningPort

        $powerBiApp = "PowerBIWebApp"
        Write-Verbose "Reserving Url for $powerBiApp..."
        $result = $pbirsWmiObject.ReserveURL($powerBiApp,"http://+:$ListeningPort",(Get-Culture).Lcid)

        if ($result.HRESULT -ne 0)
        {
            throw "Failed Reserving Url for $powerBiApp, Errocode: $($result.HRESULT)"
        }

        $officeWebApp = "OfficeWebApp"
        Write-Verbose "Reserving Url for $officeWebApp..."
        $result = $pbirsWmiObject.ReserveURL($officeWebApp,"http://+:$ListeningPort",(Get-Culture).Lcid)
        
        if ($result.HRESULT -ne 0)
        {
            throw "Failed Reserving Url for $officeWebApp, Errocode: $($result.HRESULT)"
        }       

        Write-Verbose "Success!"
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
