# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Restore-RSEncryptionKey
{
    <#
    .SYNOPSIS
        This script restores the SQL Server Reporting Services encryption key.

    .DESCRIPTION
        This script restores encryption key for SQL Server Reporting Services. This key is needed in order to read all the encrypted content stored in the Reporting Services Catalog database.

    .PARAMETER SqlServerInstance (optional)
        Specify the name of the SQL Server Reporting Services Instance.

    .PARAMETER SqlServerVersion (optional)
        Specify the version of the SQL Server Reporting Services Instance. 13 for SQL Server 2016, 12 for SQL Server 2014, 11 for SQL Server 2012

    .PARAMETER Password
        Specify the password that was used when the encryption key was backed up.
        
    .PARAMETER KeyPath
        Specify the path to where the encryption key is stored.

    .EXAMPLE
        Restore-RSEncryptionKey -Password 'Enter Your Password' -KeyPath 'C:\ReportingServices\Default.snk'
        Description
        -----------
        This command will restore the encryption key to the default instance from SQL Server 2016 Reporting Services
    
    .EXAMPLE
        Restore-RSEncryptionKey -SqlServerInstance 'SQL2012' -SqlServerVersion '11' -Password 'Enter Your Password' -KeyPath 'C:\ReportingServices\Default.snk'
        Description
        -----------
        This command will restore the encryption key to the named instance (SQL2012) from SQL Server 2012 Reporting Services 
    #>

    [cmdletbinding()]
    param
    (
        [string]
        $SqlServerInstance='MSSQLSERVER',

        [string]
        $SqlServerVersion='13',
        
        [Parameter(Mandatory=$True)]
        [string]
        $Password,
        
        [Parameter(Mandatory=$True)]
        [string]
        $KeyPath    
    )

    $rsWmiObject = New-RsConfigurationSettingObject -SqlServerInstance $SqlServerInstance -SqlServerVersion $SqlServerVersion
    $reportServerService = 'ReportServer'

    if (![String]::IsNullOrEmpty($sqlServerInstance))
    {
        $reportServerService = $reportServerService + '$' + $sqlServerInstance
    }

    Write-Verbose "Checking if key file path is valid..."
    if (![System.IO.File]::Exists($KeyPath)) 
    {
        Write-Error "No key was found at the specified location: $path"
        Exit 1
    }

    $keyBytes = [System.IO.File]::ReadAllBytes($KeyPath)

    Write-Verbose "Restoring encryption key..."
    $restoreKeyResult = $rsWmiObject.RestoreEncryptionKey($keyBytes, $keyBytes.Length, $Password)

    if ($restoreKeyResult.HRESULT -eq 0)
    {
        Write-Verbose "Success!"
    }
    else
    {
        Write-Error "Fail! `n Errors: $($restoreKeyResult.ExtendedErrors)"
        Exit 2
    }

    Write-Verbose "Stopping Reporting Services Service..."
    Stop-Service $reportServerService -ErrorAction Stop

    Write-Verbose "Starting Reporting Services Service..."
    Start-Service $reportServerService -ErrorAction Stop
}
