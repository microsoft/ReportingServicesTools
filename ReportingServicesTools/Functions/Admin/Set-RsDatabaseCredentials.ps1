# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsDatabaseCredentials
{
    <#
        .SYNOPSIS
            This script configures the credentials used to connect to the database used by SQL Server Reporting Services.

        .DESCRIPTION
            This script configures the credentials used to connect to the database used by SQL Server Reporting Services. You must be an admin in RS and SQL Server in order to perform this operation successfully.

        .PARAMETER DatabaseCredentialType
            Indicate what type of credentials to use when connecting to the database.

        .PARAMETER DatabaseCredential
            Specify the credentials to use when connecting to the SQL Server.
            Note: This parameter will be ignored whenever DatabaseCredentialType is set to ServiceAccount!

        .PARAMETER Encrypt
            Specify the encryption type for the setup connection made by Invoke-Sqlcmd, not the report server runtime connection.
            Accepted values: Mandatory, Optional, Strict.
            If supported, but not specified, the default value is Mandatory.
            Using this parameter requires PowerShell SQLServer module version 22 or higher.

        .PARAMETER TrustServerCertificate
            Specify this switch to bypass certificate validation for the setup connection made by Invoke-Sqlcmd only.
            This does not configure TrustServerCertificate on the report server runtime connection.
            Using this parameter requires PowerShell SQLServer module version 22 or higher.

        .PARAMETER HostNameInCertificate
            Specify the host name for certificate validation on the setup connection made by Invoke-Sqlcmd only.
            Using this parameter requires PowerShell SQLServer module version 22 or higher.

        .PARAMETER DatabaseEncryptMode
            Specify encryption for the report server runtime catalog connection: Optional, Mandatory, or Strict.
            Requires a WMI provider with Encrypt support; Strict also requires EncryptMode support.
            Omit this parameter to retain the existing cmdlet behavior.

        .PARAMETER DatabaseMultiSubnetFailover
            Enable MultiSubnetFailover for the report server runtime catalog connection.
            Use -DatabaseMultiSubnetFailover:$false to disable it. Omit it to leave the stored value unchanged.
            Requires a WMI provider with MultiSubnetFailover support.

        .PARAMETER DatabaseTrustServerCertificate
            Set TrustServerCertificate for the report server runtime catalog connection.
            Specify $true to trust the server certificate or $false to clear the setting.
            Omit it to preserve the stored setting. Requires a WMI provider with TrustServerCertificate support.
            Use $true only when you accept bypassing server certificate validation.
            With Encrypt=Strict, the SQL client ignores TrustServerCertificate.

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
            Specify the credentials to use when connecting to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER QueryTimeout
            Specify the setup SQL query timeout in seconds. Default value is 30.
            This does not change the report server runtime database query timeout.

        .EXAMPLE
            Set-RsDatabaseCredentials -DatabaseCredentialType Windows -DatabaseCredential $myCredentials
            Description
            -----------
            This command will configure Reporting Services to connect to the database using Windows credentials ($myCredentials).

        .EXAMPLE
            Set-RsDatabaseCredentials -DatabaseCredentialType SQL -DatabaseCredential $sqlCredentials
            Description
            -----------
            This command will configure Reporting Services to connect to the database using SQL credentials ($sqlCredentials).

        .EXAMPLE
            Set-RsDatabaseCredentials -DatabaseCredentialType ServiceAccount
            Description
            -----------
            This command will configure Reporting Services to connect to the database using Service Account credentials.

        .EXAMPLE
            Set-RsDatabaseCredentials -DatabaseCredentialType ServiceAccount -DatabaseEncryptMode Strict -DatabaseMultiSubnetFailover:$false
            Description
            -----------
            This command configures Strict runtime encryption and disables runtime multi-subnet failover.
            It does not change the encryption settings of the setup connection.

        .EXAMPLE
            Set-RsDatabaseCredentials -DatabaseCredentialType ServiceAccount -DatabaseTrustServerCertificate $false
            Description
            -----------
            This command clears certificate trust for the report server runtime connection.
    #>
    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('Authentication')]
        [Microsoft.ReportingServicesTools.SqlServerAuthenticationType]
        $DatabaseCredentialType,

        [System.Management.Automation.PSCredential]
        $DatabaseCredential,

        [ValidateSet("Mandatory", "Optional", "Strict")]
        [string]
        $Encrypt,

        [switch]
        $TrustServerCertificate,

        [string]
        $HostNameInCertificate,

        [switch]
        $IsRemoteDatabaseServer,

        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,

        [Alias('SqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion,

        [string]
        $ComputerName,

        [System.Management.Automation.PSCredential]
        $Credential,

        [int]
        $QueryTimeout = 30,

        [ValidateSet("Mandatory", "Optional", "Strict")]
        [string]
        $DatabaseEncryptMode,

        [switch]
        $DatabaseMultiSubnetFailover,

        [bool]
        $DatabaseTrustServerCertificate
    )

    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetWmi -BoundParameters $PSBoundParameters), "Configure to use $DatabaseCredentialType authentication"))
    {
        $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters
        $databaseConnectionParameters = Get-RsDatabaseConnectionParameters -WmiObject $rsWmiObject -BoundParameters $PSBoundParameters

        $supportSQLServerV22Parameters = (Get-InstalledModule -Name "SQLServer" -MinimumVersion 22.0 -ErrorAction SilentlyContinue) -ne $null
        $containsSQLServerV22Parameters = $PSBoundParameters.ContainsKey("Encrypt") -or $TrustServerCertificate -or $PSBoundParameters.ContainsKey("HostNameInCertificate")

        if ($containsSQLServerV22Parameters -and -not $supportSQLServerV22Parameters)
        {
            throw "The current version of Invoke-Sqlcmd cmdlet used in this script doesn't support -Encrypt, -TrustServerCertificate and -HostNameInCertificate parameters. Consider installing SQLServer module version 22 or higher and restarting PowerShell to use the script with these parameters."
        }

        #region Validating authentication and normalizing credentials
        $username = ''
        $password = $null
        if ($DatabaseCredentialType -like 'serviceaccount')
        {
            $username = $rsWmiObject.WindowsServiceIdentityActual
            $password = ''
        }

        else
        {
            if ($DatabaseCredential -eq $null)
            {
                throw "No Database Credential specified! Database credential must be specified when configuring $DatabaseCredentialType authentication."
            }
            $username = $DatabaseCredential.UserName
            $password = $DatabaseCredential.GetNetworkCredential().Password
        }
        #endregion Validating authentication and normalizing credentials

        $databaseName = $rsWmiObject.DatabaseName
        $databaseServerName = $rsWmiObject.DatabaseServerName

        #region Configuring Database rights
        # Step 1 - Generate database rights script
        Write-Verbose "Generating database rights script..."
        $isWindowsAccount = ($DatabaseCredentialType -like "Windows") -or ($DatabaseCredentialType -like "ServiceAccount")
        $result = $rsWmiObject.GenerateDatabaseRightsScript($username, $databaseName, $IsRemoteDatabaseServer, $isWindowsAccount)
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
        try
        {
            $parameters = @{
                ServerInstance = $DatabaseServerName
                Query = $SQLScript
                QueryTimeout = $QueryTimeout
                ErrorAction = "Stop"
            }

            if ($containsSQLServerV22Parameters)
            {
                if ($PSBoundParameters.ContainsKey("Encrypt"))
                {
                    $parameters.add("Encrypt", $Encrypt)
                }
    
                if ($TrustServerCertificate)
                {
                    $parameters.add("TrustServerCertificate", $true)
                }
    
                if ($PSBoundParameters.ContainsKey("HostNameInCertificate"))
                {
                    $parameters.add("HostNameInCertificate", $HostNameInCertificate)
                }
            }

            if ($supportSQLServerV22Parameters)
            {
                SQLServer\Invoke-Sqlcmd @parameters
            }
            else
            {
                Invoke-Sqlcmd @parameters
            }
        }
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
        if ($null -eq $databaseConnectionParameters)
        {
            $result = $rsWmiObject.SetDatabaseConnection($DatabaseServerName, $databaseName, $DatabaseCredentialType.Value__, $username, $password)
        }
        else
        {
            $databaseConnectionParameters['Server'] = $DatabaseServerName
            $databaseConnectionParameters['DatabaseName'] = $databaseName
            $databaseConnectionParameters['CredentialsType'] = $DatabaseCredentialType.Value__
            $databaseConnectionParameters['UserName'] = $username
            $databaseConnectionParameters['Password'] = $password
            $result = $rsWmiObject.InvokeMethod('SetDatabaseConnection', $databaseConnectionParameters, $null)
        }
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
