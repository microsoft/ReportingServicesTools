# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Restore-RSEncryptionKey
{
    <#
        .SYNOPSIS
            This script restores the SQL Server Reporting Services encryption key.

        .DESCRIPTION
            This script restores encryption key for SQL Server Reporting Services. This key is needed in order to read all the encrypted content stored in the Reporting Services Catalog database.

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
            Restore-RSEncryptionKey -ReportServerInstance 'SQL2012' -ReportServerVersion '11' -Password 'Enter Your Password' -KeyPath 'C:\ReportingServices\Default.snk'
            Description
            -----------
            This command will restore the encryption key to the named instance (SQL2012) from SQL Server 2012 Reporting Services
    
        .NOTES
            Author:      ???
            Editors:     Friedrich Weinmann
            Created on:  ???
            Last Change: 26.01.2017
            Version:     1.1
    
            Release 1.1 (26.01.2017, Friedrich Weinmann)
            - Fixed Parameter help (Don't poison the name with "(optional)", breaks Get-Help)
            - Implemented ShouldProcess (-WhatIf, -Confirm)
            - Replaced calling exit with throwing a terminating error (exit is a bit of an overkill when failing a simple execution)
            - Improved error message on failure.
            - Standardized the parameters governing the Report Server connection for consistent user experience.
            - Try/Catch when reading from file. No special logic involved, but shows that the possibility of failure was considered
    
            Release 1.0 (???, ???)
            - Initial Release
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,
        
        [Alias('SqlServerVersion')]
        [ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion,
        
        [string]
        $ComputerName,
        
        [System.Management.Automation.PSCredential]
        $Credential,
        
        [Parameter(Mandatory = $True)]
        [string]
        $Password,
        
        [Parameter(Mandatory = $True)]
        [string]
        $KeyPath    
    )
    
    if (-not $ReportServerInstance) { $ReportServerInstance = [ReportingServicesTools.ConnectionHost]::Instance }
    
    if ($PSCmdlet.ShouldProcess($ReportServerInstance, "Restore encryptionkey from file $KeyPath"))
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
        
        $reportServerService = 'ReportServer'
        
        if ($ReportServerInstance)
        {
            $reportServerService = $reportServerService + '$' + $ReportServerInstance
        }
        
        Write-Verbose "Checking if key file path is valid..."
        if (-not (Test-Path $KeyPath))
        {
            throw "No key was found at the specified location: $path"
        }
        
        try { $keyBytes = [System.IO.File]::ReadAllBytes($KeyPath) }
        catch { throw }
        
        Write-Verbose "Restoring encryption key..."
        $restoreKeyResult = $rsWmiObject.RestoreEncryptionKey($keyBytes, $keyBytes.Length, $Password)
        
        if ($restoreKeyResult.HRESULT -eq 0)
        {
            Write-Verbose "Success!"
        }
        else
        {
            throw "Failed to restore the encryption key! Errors: $($restoreKeyResult.ExtendedErrors)"
        }
        
        try
        {
            $splat = @{
                Name = $reportServerService
                ComputerName = $rsWmiObject.PSComputerName
                ErrorAction = 'Stop'
            }
            
            $service = Get-Service -Name $reportServerService -ComputerName $rsWmiObject.PSComputerName -ErrorAction Stop
            Write-Verbose "Stopping Reporting Services Service..."
            $service.Stop()
            
            Write-Verbose "Starting Reporting Services Service..."
            $service.Start()
        }
        catch
        {
            throw (New-Object System.Exception("Failed to restart Report Server database service. Manually restart it for the change to take effect! $($_.Exception.Message)", $_.Exception))
        }
    }
}
