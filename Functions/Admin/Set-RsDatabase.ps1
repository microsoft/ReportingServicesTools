# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Set-RsDatabase
{
    <#
        .SYNOPSIS
            This script configures the database settings used by SQL Server Reporting Services.
        
        .DESCRIPTION
            This script configures SQL Server Reporting Services to either create and use a new RS database or use an existing RS database.
            You must be an admin in RS and SQL Server in order to perform this operation successfully.
        
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
        
        .PARAMETER DatabaseServerName
            Specify the database server name. (e.g. localhost, MyMachine\Sql2016, etc.)
        
        .PARAMETER IsRemoteDatabaseServer
            Specify this switch if the database server is on a different machine than the machine Reporting Services is running on.
        
        .PARAMETER Name
            Specify the name of the RS Database.
        
        .PARAMETER IsExistingDatabase
            Specify this switch if the database to use already exists.
        
        .PARAMETER Authentication
            Indicate what type of credentials to use when connecting to the database: Windows, SQL, or Service Account.
        
        .PARAMETER DatabaseCredential
            Specify the credentials to use when connecting to the SQL Server.
            Note: This parameter will be ignored whenever Authentication is set to Service Account!
        
        .EXAMPLE
            Set-RsDatabase -DatabaseServerName localhost -Name ReportServer -Authentication 2
            Description
            -----------
            This command will create a new RS database (ReportServer) and configure Reporting Services to connect to it using Service Account credentials.
        
        .EXAMPLE
            Set-RsDatabase -DatabaseServerName localhost -Name ExistingReportServer -IsExistingDatabase -Authentication 0 -DatabaseCredential $myCredentials
            Description
            -----------
            This command will configure Reporting Services to connect to an existing RS database (ExistingReportServer) using Windows credentials ($myCredentials).
        
        .NOTES
            Author:      ???
            Editors:     Friedrich Weinmann
            Created on:  ???
            Last Change: 31.01.2017
            Version:     1.1
            
            Release 1.1 (26.01.2017, Friedrich Weinmann)
            - Fixed Parameter help (Don't poison the name with "(optional)", breaks Get-Help)
            - Standardized the parameters governing the Report Server connection for consistent user experience.
            - Renamed the parameter 'DatabaseCredentialType' to 'Authentication', in order to maintain parameter naming conventions. Added the previous name as an alias, for backwards compatiblity.
            - Replaced the parametertype of -Authentication to the new enumeration ReportingServicesTools.SqlServerAuthentication.
            - Removed the parameter validation on Authentication: ValidateSet serves no purpose with an enumerated type.
            - Renamed the parameter 'DatabaseName' to 'Name', in order to maintain parameter naming conventions. Added the previous name as an alias, for backwards compatiblity.
            - Altered the way "New-RsConfigurationSettingObject" is called to the default template. This offers a consistent experience across all WMI-based functions.
            - Replaced calling exit with throwing a terminating error (exit is a bit of an overkill when failing a simple execution)
            - Improved error message on failure.
            - Implemented ShouldProcess (-WhatIf, -Confirm)
            
            Release 1.0 (???, ???)
            - Initial Release
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $True)]
        [string]
        $DatabaseServerName,

        [switch]
        $IsRemoteDatabaseServer,
        
        [Parameter(Mandatory = $True)]
        [Alias('DatabaseName')]
        [string]
        $Name,

        [switch]
        $IsExistingDatabase,
        
        [Parameter(Mandatory = $true)]
        [Alias('DatabaseCredentialType')]
        [ReportingServicesTools.SqlServerAuthentication]
        $Authentication,
        
        [System.Management.Automation.PSCredential]
        $DatabaseCredential,
        
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
    
    if ($PSCmdlet.ShouldProcess("$tempComputerName \ $tempInstanceName", "Configure to use $DatabaseServerName as database, using $Authentication authentication"))
    {
        #region Connect to Report Server using WMI
        try
        {
            $splat = @{ }
            if ($PSBoundParameters.ContainsKey('ReportServerInstance')) { $splat['ReportServerInstance'] = $ReportServerInstance }
            if ($PSBoundParameters.ContainsKey('ReportServerVersion')) { $splat['ReportServerVersion'] = $ReportServerVersion }
            if ($PSBoundParameters.ContainsKey('ComputerName')) { $splat['ComputerName'] = $ComputerName }
            if ($PSBoundParameters.ContainsKey('Credential')) { $splat['Credential'] = $Credential }
            $wmi = New-RsConfigurationSettingObject @splat
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
        
        #region Create Database if necessary
        if (-not $IsExistingDatabase)
        {
            # Step 1 - Generate Database Script  
            Write-Verbose "Generating database creation script..."
            $EnglishLocaleId = 1033
            $IsSharePointMode = $false
            $result = $wmi.GenerateDatabaseCreationScript($Name, $EnglishLocaleId, $IsSharePointMode)
            if ($result.HRESULT -ne 0)
            {
                Write-Verbose "Generating database creation script... Failed!"
                throw "Failed to generate the database creation script from the report server using WMI. Errorcode: $($result.HRESULT)"
            }
            else
            {
                $SQLScript = $result.Script
                Write-Verbose "Generating database creation script... Complete!"
            }
            
            # Step 2 - Run Database creation script
            Write-Verbose "Executing database creation script..."
            try { Invoke-Sqlcmd -ServerInstance $DatabaseServerName -Query $SQLScript -ErrorAction Stop }
            catch
            {
                Write-Verbose "Executing database creation script... Failed!"
                throw
            }
            Write-Verbose "Executing database creation script... Complete!"
        }
        #endregion Create Database if necessary
        
        #region Configuring Database rights
        # Step 3 - Generate database rights script
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
        
        # Step 4 - Run Database rights script
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
        # Step 5 - Update Reporting Services to connect to new database now
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
