# Copyright (c) 2017 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsRestCredentialsByUserObject
{
    <#
        .SYNOPSIS
            This script creates a new CredentialsByUser object which can be used when updating shared/embedded data sources.

        .DESCRIPTION
            This script creates a new CredentialsByUser object which can be used when updating shared/embedded data sources.

        .PARAMETER PromptMessage
            Specify the message to display when Report Server asks user for credentials

        .PARAMETER WindowsCredentials
            Specify whether Report Server should treat user's credentials as SQL credentials or Windows credentials.

        .EXAMPLE
            New-RsRestCredentialsByUserObject

            Description
            -----------
            Creates a CredentialsByUser object with all properties set to default values.

        .EXAMPLE
            New-RsRestCredentialsByUserObject -PromptMessage "Please enter your credentials"

            Description
            -----------
            Creates a CredentialsByUser object with the DisplayText property set to "Please enter your credentials"

        .EXAMPLE
            New-RsRestCredentialsByUserObject -WindowsCredentials 

            Description
            -----------
            Creates a CredentialsByUser object with the UseAsWindowsCredentials set to true.
    #>
    [CmdletBinding()]
    param(
        [Alias('DisplayText')]
        [string]
        $PromptMessage,

        [Alias('UseAsWindowsCredentials')]
        [switch]
        $WindowsCredentials
    )
    Process
    {
        return @{
            "DisplayText" = $PromptMessage;
            "UseAsWindowsCredentials" = $WindowsCredentials -eq $true;
        }
    }
}