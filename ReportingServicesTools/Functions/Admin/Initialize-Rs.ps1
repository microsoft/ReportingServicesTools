# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Initialize-Rs
{
    <#
        .SYNOPSIS
            This command initializes an instance of Report Server after the database and urls have been configured.
        
        .DESCRIPTION
            This command initializes an instance of Report Server after the database and urls have been configured.
        
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
        
        .EXAMPLE
            Initialize-Rs
            Description
            -----------
            This command will initialize the Report Server
    #>
    
    [cmdletbinding()]
    param
    (
      
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
        Write-Verbose "Initializing Report Server..."
        $result = $rsWmiObject.InitializeReportServer($rsWmiObject.InstallationID)
        Write-Verbose "Success!"
    }
    catch
    {
        throw (New-Object System.Exception("Failed to Initialize Report Server $($_.Exception.Message)", $_.Exception))
    }
    
    if ($result.HRESULT -ne 0)
    {
        throw "Failed to Initialize Report Server, ErrorCode: $($result.HRESULT)"
    }
}
