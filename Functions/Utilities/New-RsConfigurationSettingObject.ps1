# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsConfigurationSettingObject
{
    <#
        .SYNOPSIS
            This script creates a new WMI Object that is connected to Reporting Services WMI Provider.
        
        .DESCRIPTION
            This script creates a new WMI Object that is connected to Reporting Services WMI Provider.
        
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
        
        .PARAMETER MinimumSqlServerVersion
            The minimum SQL server version required in order to establish a connection. If trying to connect to a lower version, this function will error out.
            This allows a function to require such minimum version, without having to complicate code by looking up defaults and considering user input.
        
        .EXAMPLE
            New-RsConfigurationSettingObject
            Description
            -----------
            This command will retrieve and return WMI Object associated to the default instance (MSSQLSERVER) of SQL Server 2016 Reporting Services.
        
        .EXAMPLE
            New-RsConfigurationSettingObject -SqlServerInstance 'SQL2016'
            Description
            -----------
            This command will retrieve and return WMI Object associated to the named instance (SQL2016) of SQL Server 2016 Reporting Services.
        
        .EXAMPLE
            New-RsConfigurationSettingObject -SqlServerVersion '11'
            Description
            -----------
            This command will retrieve and return WMI Object associated to the default instance (MSSQLSERVER) of SQL Server 2012 Reporting Services.
        
        .EXAMPLE
            New-RsConfigurationSettingObject -SqlServerInstance 'SQL2012' -SqlServerVersion 'SQLServer2012'
            Description
            -----------
            This command will retrieve and return WMI Object associated to the named instance (SQL2012) of SQL Server 2012 Reporting Services.
    #>

    [cmdletbinding()]
    param
    (
        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance = ([Microsoft.ReportingServicesTools.ConnectionHost]::Instance),
        
        [Alias('SqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion = ([Microsoft.ReportingServicesTools.ConnectionHost]::Version),
        
        [string]
        $ComputerName = ([Microsoft.ReportingServicesTools.ConnectionHost]::ComputerName),
        
        [System.Management.Automation.PSCredential]
        $Credential = ([Microsoft.ReportingServicesTools.ConnectionHost]::Credential),
        
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $MinimumSqlServerVersion
    )
    
    if (($MinimumSqlServerVersion) -and ($MinimumSqlServerVersion -gt $ReportServerVersion))
    {
        throw (New-Object System.Management.Automation.PSArgumentException("Trying to connect to $ComputerName \ $ReportServerInstance, but it is only $ReportServerVersion when at least $MinimumSqlServerVersion is required!"))
    }
    
    $getWmiObjectParameters = @{
        ErrorAction = "Stop"
        Namespace = "root\Microsoft\SqlServer\ReportServer\RS_$ReportServerInstance\v$($ReportServerVersion.Value__)\Admin"
        Class = "MSReportServer_ConfigurationSetting"
    }
    
    if ($ComputerName)
    {
        $getWmiObjectParameters["ComputerName"] = $ComputerName
    }
    if ($Credential)
    {
        $getWmiObjectParameters["Credential"] = $Credential
    }
    
    Get-WmiObject @getWmiObjectParameters
}
