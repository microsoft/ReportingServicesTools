# Copyright (c) 2017 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsRestCredentialsInServerObject
{
    <#
        .SYNOPSIS
            This script creates a new CredentialsInServer object which can be used when updating shared/embedded data sources.

        .DESCRIPTION
            This script creates a new CredentialsInServer object which can be used when updating shared/embedded data sources.

        .PARAMETER Username
            Specify the username to use when Report Server is connecting to database.

        .PARAMETER Password
            Specify the password to use when Report Server is connecting to database.

        .PARAMETER WindowsCredentials
            Specify whether Report Server should treat specified credentials as SQL credentials or Windows credentials.

        .PARAMETER ImpersonateUser
            Specify whether Report Server should try impersonating as current user when fetching data.

        .EXAMPLE
            New-RsRestCredentialsInServerObject -Credential (Get-Credential)

            Description
            -----------
            Creates a CredentialsInServer object with specified username and password.

        .EXAMPLE
            New-RsRestCredentialsInServerObject -Credential (Get-Credential) -WindowsCredentials 

            Description
            -----------
            Creates a CredentialsInServer object with UseAsWindowsCredentials set to true and specified username and password.

        .EXAMPLE
            New-RsRestCredentialsInServerObject -Credential (Get-Credential) -ImpersonateUser

            Description
            -----------
            Creates a CredentialsInServer object with ImpersonateAuthenticatedUser set to true and specified username and password.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Alias('UseAsWindowsCredentials')]
        [switch]
        $WindowsCredentials,

        [Alias('ImpersonateAuthenticatedUser')]
        [switch]
        $ImpersonateUser
    )
    Process
    {
        return @{
            "UserName" = $Credential.Username;
            "Password" = $Credential.GetNetworkCredential().Password;
            "UseAsWindowsCredentials" = $WindowsCredentials -eq $true;
            "ImpersonateAuthenticatedUser" = $ImpersonateUser -eq $true;
        }
    }
}