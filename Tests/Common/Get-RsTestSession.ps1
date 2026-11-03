# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsTestSession
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Fixture,

        [Parameter(Mandatory = $true)]
        [string]$ReportPortalUri,

        [ValidateSet('v1.0', 'v2.0')]
        [string]$RestApiVersion = 'v2.0',

        [AllowNull()]
        [System.Management.Automation.PSCredential]$Credential = ([Microsoft.ReportingServicesTools.ConnectionHost]::Credential)
    )

    # The caller owns this fixture; never cache authentication across files or identities.
    if ($Fixture.ContainsKey('Session'))
    {
        if ($Fixture.ReportPortalUri -cne $ReportPortalUri -or
            $Fixture.RestApiVersion -cne $RestApiVersion -or
            -not [object]::ReferenceEquals($Fixture.Credential, $Credential))
        {
            throw 'REST test session identity changed. Use a separate fixture for each server, API version and credential.'
        }
        return $Fixture.Session
    }

    $session = New-RsRestSession -ReportPortalUri $ReportPortalUri -RestApiVersion $RestApiVersion -Credential $Credential -ErrorAction Stop
    if ($null -eq $session)
    {
        throw 'REST test session creation returned no session.'
    }
    $Fixture.ReportPortalUri = $ReportPortalUri
    $Fixture.RestApiVersion = $RestApiVersion
    $Fixture.Credential = $Credential
    $Fixture.Session = $session
    return $session
}
