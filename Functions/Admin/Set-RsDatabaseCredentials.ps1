# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsDatabaseCredentials
{
    <#
        .SYNOPSIS 
            This script configures the credentials used to connect to the database used by SQL Server Reporting Services.

        .DESCRIPTION
            This script configures the credentials used to connect to the database used by SQL Server Reporting Services.
            
        .PARAMETER ReportServerInstance (optional)
            Specify the name of the SQL Server Reporting Services Instance.

        .PARAMETER ReportServerVersion (optional)
            Specify the version of the SQL Server Reporting Services Instance.

        .PARAMETER DatabaseCredentialType
            Indicate what type of credentials to use when connecting to the database. 0 for Windows, 1 for SQL, and 2 for Service Account. 

        .PARAMETER DatabaseCredential
            Specify the credentials to use when connecting to the SQL Server. 
            Note: This parameter will be ignored whenever DatabaseCredentialType is set to 2!

        .PARAMETER IsDatabaseServerRemote
            Specify this parameter when the database server is on a different machine than the machine Reporting Services is on.

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
    #>
    [cmdletbinding()]
    param(
        [string]
        $ReportServerInstance='MSSQLSERVER',

        [string]
        $ReportServerVersion ='13',

        [Parameter(Mandatory=$True)]
        [ValidateRange(0, 2)]
        [int]
        $DatabaseCredentialType,

        [System.Management.Automation.CredentialAttribute()]
        $DatabaseCredential,

        [switch]
        $IsDatabaseServerRemote
    )

    $wmi = New-RsConfigurationSettingObject -SqlServerInstance $ReportServerInstance -SqlServerVersion $ReportServerVersion 

    $username = ''
    $password = $null
    if ($DatabaseCredentialType -eq 2)
    {
        $username = $wmi.WindowsServiceIdentityActual
        $password = ''
    }
    else
    {
        if ($DatabaseCredential -eq $null)
        {
            Write-Error "No Database Credential specified! Database credential must be specified."
            Exit -1 
        }
        $username = $DatabaseCredential.UserName
        $password = $DatabaseCredential.GetNetworkCredential().password
    }

    $databaseName = $wmi.DatabaseName
    $databaseServerName = $wmi.DatabaseServerName
    $isWindowsAccount = ($DatabaseCredentialType -eq 0) -or ($DatabaseCredentialType -eq 2)

    # Step 1 - Generate database rights script
    Write-Verbose "###### Generating database rights script..."
    $result = $wmi.GenerateDatabaseRightsScript($username, $databaseName, $IsDatabaseServerRemote, $isWindowsAccount)
    $script = ''
    if ($result.HRESULT -ne 0) 
    {
        Write-Error "###### Fail!"
        Exit -1
    }
    else
    {
        $script = $result.Script
        Write-Verbose "###### Complete!"
    }

    # Step 2 - Run Database rights script
    Write-Verbose "###### Executing database rights script..."
    Invoke-Sqlcmd -Query $script
    Write-Verbose "###### Complete!"

    # Step 3 -  Update Reporting Services to connect to new database now
    Write-Verbose "###### Updating Reporting Services to connect to new database..."
    $result = $wmi.SetDatabaseConnection($databaseServerName, $databaseName, $DatabaseCredentialType, $username, $password)
    if ($result.HRESULT -ne 0) 
    {
        Write-Error "###### Fail!"
        Exit -1
    }
    else
    {
        Write-Verbose "###### Complete!"
    }
}