# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsDatabase
{
    <#
        .SYNOPSIS 
            This script configures the database settings used by SQL Server Reporting Services.

        .DESCRIPTION
            This script configures SQL Server Reporting Services to either create and use a new RS database or use an existing RS database.
            
        .PARAMETER ReportServerInstance (optional)
            Specify the name of the SQL Server Reporting Services Instance.

        .PARAMETER ReportServerVersion (optional)
            Specify the version of the SQL Server Reporting Services Instance.

        .PARAMETER DatabaseServerName
            Specify the database server name. (e.g. localhost, MyMachine\Sql2016, etc.) 

        .PARAMETER IsDatabaseServerRemote
            Specify this switch if the database server is on a different machine than the machine Reporting Services is running on.

        .PARAMETER DatabaseName
            Specify the name of the RS Database.

        .PARAMETER IsExistingDatabase
            Specify this switch if the database to use already exists.

        .PARAMETER DatabaseCredentialType
            Indicate what type of credentials to use when connecting to the database. 0 for Windows, 1 for SQL, and 2 for Service Account. 

        .PARAMETER DatabaseCredential
            Specify the credentials to use when connecting to the SQL Server. 
            Note: This parameter will be ignored whenever DatabaseCredentialType is set to 2!

        .EXAMPLE
            Set-RsDatabase -DatabaseServerName localhost -DatabaseName ReportServer -DatabaseCredentialType 2
            Description
            ----------- 
            This command will create a new RS database (ReportServer) and configure Reporting Services to connect to it using Service Account credentials.

        .EXAMPLE
            Set-RsDatabase -DatabaseServerName localhost -DatabaseName ExistingReportServer -IsExistingDatabase -DatabaseCredentialType 0 -DatabaseCredential $myCredentials
            Description
            ----------- 
            This command will configure Reporting Services to connect to an existing RS database (ExistingReportServer) using Windows credentials ($myCredentials).
    #>

    [cmdletbinding()]
    param(
        [string]
        $ReportServerInstance='MSSQLSERVER',

        [string]
        $ReportServerVersion ='13',

        [Parameter(Mandatory=$True)]
        [string]
        $DatabaseServerName,

        [switch]
        $IsDatabaseServerRemote,

        [Parameter(Mandatory=$True)]
        [string]
        $DatabaseName,

        [switch]
        $IsExistingDatabase,

        [Parameter(Mandatory=$True)]
        [ValidateRange(0, 2)]
        [int]
        $DatabaseCredentialType,

        [System.Management.Automation.CredentialAttribute()]
        $DatabaseCredential
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

    if (-not $IsExistingDatabase)
    {
        # Step 1 - Generate Database Script  
        Write-Verbose "###### Generating database creation script..."
        $EnglishLocaleId = 1033
        $IsSharePointMode = $false
        $result = $wmi.GenerateDatabaseCreationScript($DatabaseName, $EnglishLocaleId, $IsSharePointMode)
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
        
        # Step 2 - Run Database creation script
        Write-Verbose "###### Executing database creation script..."
        Invoke-Sqlcmd -Query $script
        Write-Verbose "###### Complete!"
    }
    
    # Step 3 - Generate database rights script
    Write-Verbose "###### Generating database rights script..."
    $isWindowsAccount = ($DatabaseCredentialType -eq 0) -or ($DatabaseCredentialType -eq 2)
    $result = $wmi.GenerateDatabaseRightsScript($username, $databaseName, $IsDatabaseServerRemote, $isWindowsAccount)
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

    # Step 4 - Run Database rights script
    Write-Verbose "###### Executing database rights script..."
    Invoke-Sqlcmd -Query $script
    Write-Verbose "###### Complete!"

    # Step 5 - Update Reporting Services to connect to new database now
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
