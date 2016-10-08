# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RSConfigurationSettingObject
{
    <#
    .SYNOPSIS
        This script creates a new WMI Object that is connected to Reporting Services WMI Provider.

    .DESCRIPTION
        This script creates a new WMI Object that is connected to Reporting Services WMI Provider. 

    .PARAMETER SqlServerInstance (optional)
        Specify the name of the SQL Server Reporting Services Instance.
    
    .PARAMETER SqlServerVersion (optional)
        Specify the version of the SQL Server Reporting Services Instance. 13 for SQL Server 2016, 12 for SQL Server 2014, 11 for SQL Server 2012

    .EXAMPLE 
        New-RSConfigurationSettingObject 
        Description
        -----------
        This command will retrieve and return WMI Object associated to the default instance (MSSQLSERVER) of SQL Server 2016 Reporting Services.

    .EXAMPLE 
        New-RSConfigurationSettingObject -SqlServerInstance 'SQL2016' 
        Description
        -----------
        This command will retrieve and return WMI Object associated to the named instance (SQL2016) of SQL Server 2016 Reporting Services.

    .EXAMPLE 
        New-RSConfigurationSettingObject -SqlServerVersion '11' 
        Description
        -----------
        This command will retrieve and return WMI Object associated to the default instance (MSSQLSERVER) of SQL Server 2012 Reporting Services.

    .EXAMPLE 
        New-RSConfigurationSettingObject -SqlServerInstance 'SQL2012' -SqlServerVersion '11' 
        Description
        -----------
        This command will retrieve and return WMI Object associated to the named instance (SQL2012) of SQL Server 2012 Reporting Services.
    #>

    [cmdletbinding()]
    param
    (
        [string]
        $SqlServerInstance='MSSQLSERVER',

        [string]
        $SqlServerVersion='13'
    )

    $namespace = "root\Microsoft\SqlServer\ReportServer\RS_$SqlServerInstance\v$SqlServerVersion\Admin"
    return Get-WmiObject -namespace $namespace -class MSReportServer_ConfigurationSetting -ErrorAction Stop
}
