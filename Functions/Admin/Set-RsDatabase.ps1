# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsDatabase
{
    <#
        .SYNOPSIS 
            This script configures the database settings used by SQL Server Reporting Services.

        .DESCRIPTION
            This script configures SQL Server Reporting Services to either create and use a new RS database or use an existing RS database. You must be an admin in RS and SQL Server in order to perform this operation successfully.
            
        .PARAMETER ReportServerInstance (optional)
            Specify the name of the SQL Server Reporting Services Instance.

        .PARAMETER ReportServerVersion (optional)
            Specify the version of the SQL Server Reporting Services Instance.

        .PARAMETER DatabaseServerName
            Specify the database server name. (e.g. localhost, MyMachine\Sql2016, etc.) 

        .PARAMETER IsRemoteDatabaseServer
            Specify this switch if the database server is on a different machine than the machine Reporting Services is running on.

        .PARAMETER DatabaseName
            Specify the name of the RS Database.

        .PARAMETER IsExistingDatabase
            Specify this switch if the database to use already exists.

        .PARAMETER DatabaseCredentialType
            Indicate what type of credentials to use when connecting to the database: Windows, SQL, or Service Account. 

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
        $IsRemoteDatabaseServer,

        [Parameter(Mandatory=$True)]
        [string]
        $DatabaseName,

        [switch]
        $IsExistingDatabase,

        [Parameter(Mandatory=$True)]
        [ValidateSet('Windows','SQL','ServiceAccount')]
        [string]
        $DatabaseCredentialType,

        [System.Management.Automation.PSCredential]
        $DatabaseCredential
    )

    $wmi = New-RsConfigurationSettingObject -SqlServerInstance $ReportServerInstance -SqlServerVersion $ReportServerVersion 

    # converting database credential type into its appropriate number
    $databaseCredentialTypeInt = 0
    $username = ''
    $password = $null
    switch ($DatabaseCredentialType.ToLower())
    {
        'windows' { $databaseCredentialTypeInt = 0 }
        'sql' { $databaseCredentialTypeInt = 1}
        'serviceaccount' 
        {
            $databaseCredentialTypeInt = 2
            $username = $wmi.WindowsServiceIdentityActual
            $password = ''
        }
        default 
        { 
            Write-Error "Invalid Database Credential Type specified! Valid database credential types are: Windows, SQL or Service Account." 
            Exit 1 
        }
    }

    if ($databaseCredentialTypeInt -ne 2)
    {
        if ($DatabaseCredential -eq $null)
        {
            Write-Error "No Database Credential specified! Database credential must be specified."
            Exit 1
        }
        $username = $DatabaseCredential.UserName
        $password = $DatabaseCredential.GetNetworkCredential().Password
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
            Exit 1
        }
        else
        {
            $script = $result.Script
            Write-Verbose "###### Complete!"
        }
        
        # Step 2 - Run Database creation script
        Write-Verbose "###### Executing database creation script..."
        Invoke-Sqlcmd -ServerInstance $DatabaseServerName -Query $script
        Write-Verbose "###### Complete!"
    }
    
    # Step 3 - Generate database rights script
    Write-Verbose "###### Generating database rights script..."
    $isWindowsAccount = ($databaseCredentialTypeInt -eq 0) -or ($databaseCredentialTypeInt -eq 2)
    $result = $wmi.GenerateDatabaseRightsScript($username, $DatabaseName, $IsRemoteDatabaseServer, $isWindowsAccount)
    if ($result.HRESULT -ne 0) 
    {
        Write-Error "###### Fail!"
        Exit 1
    }
    else
    {
        $script = $result.Script
        Write-Verbose "###### Complete!"
    }

    # Step 4 - Run Database rights script
    Write-Verbose "###### Executing database rights script..."
    Invoke-Sqlcmd -ServerInstance $DatabaseServerName -Query $script
    Write-Verbose "###### Complete!"

    # Step 5 - Update Reporting Services to connect to new database now
    Write-Verbose "###### Updating Reporting Services to connect to new database..."
    $result = $wmi.SetDatabaseConnection($DatabaseServerName, $DatabaseName, $databaseCredentialTypeInt, $username, $password)
    if ($result.HRESULT -ne 0) 
    {
        Write-Error "###### Fail!"
        Exit 1
    }
    else
    {
        Write-Verbose "###### Complete!"
    }
}
