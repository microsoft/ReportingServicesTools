# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Backup-RsEncryptionKey
{
    <#
        .SYNOPSIS
            This script creates a back up of the SQL Server Reporting Services encryption key.
        
        .DESCRIPTION
            This script creates a back up of the encryption key for SQL Server Reporting Services. This key is needed in order to read all the encrypted content stored in the Reporting Services Catalog database.
        
        .PARAMETER Password
            Specify the password to be used for backing up the encryption key. This password will be required when restoring the encryption key.
        
        .PARAMETER KeyPath
            Specify the path to where the encryption key should be stored.
        
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
            Backup-RSEncryptionKey -Password 'Enter Your Password' -KeyPath 'C:\ReportingServices\Default.snk'
            Description
            -----------
            This command will back up the encryption key against default instance from SQL Server 2016 Reporting Services
        
        .EXAMPLE
            Backup-RSEncryptionKey -ReportServerInstance 'SQL2012' -ReportServerVersion '11' -Password 'Enter Your Password' -KeyPath 'C:\ReportingServices\Default.snk'
            Description
            -----------
            This command will back up the encryption key against named instance (SQL2012) from SQL Server 2012 Reporting Services
        
        .EXAMPLE
            Backup-RSEncryptionKey -ComputerName "sql2012a243" -Credential (Get-Credential) -ReportServerInstance 'SQL2012' -ReportServerVersion 'SQLServer2012' -Password 'Enter Your Password' -KeyPath 'C:\ReportingServices\Default.snk'
            Description
            -----------
            This command will back up the encryption key against named instance (SQL2012) from SQL Server 2012 Reporting Services.
            To do so, it will not use the default connection, but rather connect to the computer "sql2012a243", prompting the user for connection credentials.
        
        .NOTES
            Author:      ???
            Editors:     Friedrich Weinmann
            Created on:  ???
            Last Change: 31.01.2017
            Version:     1.1
            
            Release 1.1 (26.01.2017, Friedrich Weinmann)
            - Fixed Parameter help (Don't poison the name with "(optional)", breaks Get-Help)
            - Implemented ShouldProcess (-WhatIf, -Confirm)
            - Replaced calling exit with throwing a terminating error (exit is a bit of an overkill when failing a simple execution)
            - Improved error message on failure.
            - Standardized the parameters governing the Report Server connection for consistent user experience.
            
            Release 1.0 (???, ???)
            - Initial Release
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(Mandatory = $True)]
        [string]
        $Password,
        
        [Parameter(Mandatory = $True)]
        [string]
        $KeyPath,
        
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
        
    if ($PSCmdlet.ShouldProcess("$tempComputerName \ $tempInstanceName", "Retrieve encryption key and create backup in $KeyPath"))
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
        
        Write-Verbose "Retrieving encryption key..."
        $encryptionKeyResult = $rsWmiObject.BackupEncryptionKey($Password)
        
        if ($encryptionKeyResult.HRESULT -eq 0)
        {
            Write-Verbose "Retrieving encryption key... Success!"
        }
        else
        {
            throw "Failed to create backup of the encryption key. Errors: $($encryptionKeyResult.ExtendedErrors)"
        }
        
        try
        {
            Write-Verbose "Writing key to file..."
            [System.IO.File]::WriteAllBytes($KeyPath, $encryptionKeyResult.KeyFile)
            Write-Verbose "Writing key to file... Success!"
        }
        catch
        {
            throw
        }
    }
}
