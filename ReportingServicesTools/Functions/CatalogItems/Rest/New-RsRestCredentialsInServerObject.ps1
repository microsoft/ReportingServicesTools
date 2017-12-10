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
            New-RsRestCredentialsInServerObject -Username "domain\\user" -Password "password"

            Description
            -----------
            Creates a CredentialsInServer object with specified username and password.

        .EXAMPLE
            New-RsRestCredentialsInServerObject -Username "domain\\user" -Password "password" -WindowsCredentials 

            Description
            -----------
            Creates a CredentialsInServer object with UseAsWindowsCredentials set to true and specified username and password.

        .EXAMPLE
            New-RsRestCredentialsInServerObject -Username "domain\\user" -Password "password" -ImpersonateUser

            Description
            -----------
            Creates a CredentialsInServer object with ImpersonateAuthenticatedUser set to true and specified username and password.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $Username,

        [Parameter(Mandatory = $True)]
        [string]
        $Password,

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
            "UserName" = $Username;
            "Password" = $Password;
            "UseAsWindowsCredentials" = $WindowsCredentials;
            "ImpersonateAuthenticatedUser" = $ImpersonateUser;
        }
    }
}