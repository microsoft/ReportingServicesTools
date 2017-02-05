# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsDatabaseCredentials
{
    <#
        .SYNOPSIS
            This script configures the credentials used to connect to the database used by SQL Server Reporting Services.
        
        .DESCRIPTION
            This script configures the credentials used to connect to the database used by SQL Server Reporting Services. You must be an admin in RS and SQL Server in order to perform this operation successfully.
        
        .PARAMETER Authentication
            Indicate what type of credentials to use when connecting to the database. 0 for Windows, 1 for SQL, and 2 for Service Account.
        
        .PARAMETER DatabaseCredential
            Specify the credentials to use when connecting to the SQL Server.
            Note: This parameter will be ignored whenever DatabaseCredentialType is set to 2!
        
        .PARAMETER IsRemoteDatabaseServer
            Specify this parameter when the database server is on a different machine than the machine Reporting Services is on.
        
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
            Set-RsDatabaseCredentials -DatabaseCredentialType 0 -DatabaseCredential $myCredentials
            Description
            -----------
            This command will configure Reporting Services to connect to the database using Windows credentials ($myCredentials).
        
        .EXAMPLE
            Set-RsDatabaseCredentials -DatabaseCredentialType 1 -DatabaseCredential $sqlCredentials
            Description
            -----------
            This command will configure Reporting Services to connect to the database using SQL credentials ($sqlCredentials).
        
        .EXAMPLE
            Set-RsDatabaseCredentials -DatabaseCredentialType 2
            Description
            -----------
            This command will configure Reporting Services to connect to the database using Service Account credentials.
        
        .NOTES
            Author:      ???
            Editors:     Friedrich Weinmann
            Created on:  ???
            Last Change: 31.01.2017
            Version:     1.1
            
            Release 1.1 (31.01.2017, Friedrich Weinmann)
            - Fixed Parameter help (Don't poison the name with "(optional)", breaks Get-Help)
            - Standardized the parameters governing the Report Server connection for consistent user experience.
            - Renamed the parameter 'DatabaseCredentialType' to 'Authentication', in order to maintain parameter naming conventions. Added the previous name as an alias, for backwards compatiblity.
            - Replaced the parametertype of -Authentication to the new enumeration ReportingServicesTools.SqlServerAuthentication.
            - Removed the parameter validation on Authentication: ValidateSet serves no purpose with an enumerated type.
            - Altered the way "New-RsConfigurationSettingObject" is called to the default template. This offers a consistent experience across all WMI-based functions.
            - Replaced calling exit with throwing a terminating error (exit is a bit of an overkill when failing a simple execution)
            - Improved error message on failure.
            - Implemented ShouldProcess (-WhatIf, -Confirm)
            
            Release 1.0 (???, ???)
            - Initial Release
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('DatabaseCredentialType')]
        [ReportingServicesTools.SqlServerAuthentication]
        $Authentication,

        [System.Management.Automation.PSCredential]
        $DatabaseCredential,

        [switch]
        $IsRemoteDatabaseServer,
        
        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,
        
        [Alias('SqlServerVersion')]
        [ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion,
        
        [string]
        $ComputerName,
        
        [System.Management.Automation.PSCredential]
        $Credential
    )
    
    if ($ComputerName) { $tempComputerName = $ComputerName }
    else { $tempComputerName = ([ReportingServicesTools.ConnectionHost]::ComputerName) }
    if ($ReportServerInstance) { $tempInstanceName = $ReportServerInstance }
    else { $tempInstanceName = ([ReportingServicesTools.ConnectionHost]::Instance) }
    
    if ($PSCmdlet.ShouldProcess("$tempComputerName \ $tempInstanceName", "Configure to use $Authentication authentication"))
    {
        #region Connect to Report Server using WMI
        try
        {
            $splat = @{ }
            if ($PSBoundParameters.ContainsKey('ReportServerInstance')) { $splat['ReportServerInstance'] = $ReportServerInstance }
            if ($PSBoundParameters.ContainsKey('ReportServerVersion')) { $splat['ReportServerVersion'] = $ReportServerVersion }
            if ($PSBoundParameters.ContainsKey('ComputerName')) { $splat['ComputerName'] = $ComputerName }
            if ($PSBoundParameters.ContainsKey('Credential')) { $splat['Credential'] = $Credential }
            $rsWmiObject = New-RsConfigurationSettingObject @splat
        }
        catch
        {
            throw
        }
        #endregion Connect to Report Server using WMI
        
        #region Validating authentication and normalizing credentials
        $username = ''
        $password = $null
        if ($Authentication -like 'serviceaccount')
        {
            $username = $wmi.WindowsServiceIdentityActual
            $password = ''
        }
        
        else
        {
            if ($DatabaseCredential -eq $null)
            {
                throw "No Database Credential specified! Database credential must be specified when configuring $Authentication authentication."
            }
            $username = $DatabaseCredential.UserName
            $password = $DatabaseCredential.GetNetworkCredential().Password
        }
        #endregion Validating authentication and normalizing credentials
        
        $databaseName = $rsWmiObject.DatabaseName
        $databaseServerName = $rsWmiObject.DatabaseServerName
        $isWindowsAccount = ($Authentication -like "Windows") -or ($Authentication -like "ServiceAccount")
        
        #region Configuring Database rights
        # Step 1 - Generate database rights script
        Write-Verbose "Generating database rights script..."
        $isWindowsAccount = ($Authentication -like "Windows") -or ($Authentication -like "ServiceAccount")
        $result = $wmi.GenerateDatabaseRightsScript($username, $Name, $IsRemoteDatabaseServer, $isWindowsAccount)
        if ($result.HRESULT -ne 0)
        {
            Write-Verbose "Generating database rights script... Failed!"
            throw "Failed to generate the database rights script from the report server using WMI. Errorcode: $($result.HRESULT)"
        }
        else
        {
            $SQLscript = $result.Script
            Write-Verbose "Generating database rights script... Complete!"
        }
        
        # Step 2 - Run Database rights script
        Write-Verbose "Executing database rights script..."
        try { Invoke-Sqlcmd -ServerInstance $DatabaseServerName -Query $SQLscript -ErrorAction Stop }
        catch
        {
            Write-Verbose "Executing database rights script... Failed!"
            throw
        }
        Write-Verbose "Executing database rights script... Complete!"
        #endregion Configuring Database rights
        
        #region Update Reporting Services database configuration
        # Step 3 - Update Reporting Services to connect to new database now
        Write-Verbose "Updating Reporting Services to connect to new database..."
        $result = $wmi.SetDatabaseConnection($DatabaseServerName, $Name, $Authentication.Value__, $username, $password)
        if ($result.HRESULT -ne 0)
        {
            Write-Verbose "Updating Reporting Services to connect to new database... Failed!"
            throw "Failed to update the reporting services to connect to the new database using WMI! Errorcode: $($result.HRESULT)"
        }
        else
        {
            Write-Verbose "Updating Reporting Services to connect to new database... Complete!"
        }
        #endregion Update Reporting Services database configuration
    }
}