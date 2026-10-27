# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Test-RsWmiMethodParameter
{
    [CmdletBinding()]
    param (
        [object]
        $Parameters,

        [string]
        $Name
    )

    # A real WMI PropertyDataCollection throws ManagementException for a missing name.
    try
    {
        return $null -ne $Parameters.Properties[$Name]
    }
    catch
    {
        return $false
    }
}

function Get-RsDatabaseConnectionParameters
{
    [CmdletBinding()]
    param (
        [object]
        $WmiObject,

        [System.Collections.IDictionary]
        $BoundParameters
    )

    $runtimeOptionsSpecified = $BoundParameters.ContainsKey('DatabaseEncryptMode') -or
        $BoundParameters.ContainsKey('DatabaseMultiSubnetFailover') -or
        $BoundParameters.ContainsKey('DatabaseTrustServerCertificate')

    $parameters = $WmiObject.GetMethodParameters('SetDatabaseConnection')
    if (-not (Test-RsWmiMethodParameter -Parameters $parameters -Name 'Encrypt'))
    {
        if ($runtimeOptionsSpecified)
        {
            throw "The connected Report Server WMI provider does not support runtime database encryption options."
        }

        # Providers without Encrypt only support the original five-argument call.
        return $null
    }

    $supportsEncryptMode = Test-RsWmiMethodParameter -Parameters $parameters -Name 'EncryptMode'

    if ($BoundParameters.ContainsKey('DatabaseEncryptMode'))
    {
        $mode = switch ($BoundParameters['DatabaseEncryptMode'])
        {
            'Optional' { 'False' }
            'False' { 'False' }
            'Mandatory' { 'True' }
            'True' { 'True' }
            'Strict' { 'Strict' }
        }

        if ($supportsEncryptMode)
        {
            $parameters['EncryptMode'] = $mode
        }
        elseif ($mode -eq 'Strict')
        {
            throw "The connected Report Server WMI provider does not support DatabaseEncryptMode Strict."
        }

        $parameters['Encrypt'] = $mode -ne 'False'
    }
    else
    {
        # Encrypt is a required WMI input; omitting it means false and would downgrade
        # Mandatory or Strict. Send the stored encryption back unchanged instead.
        $parameters['Encrypt'] = @('True', '-1', 'Yes', 'Mandatory', 'Strict') -contains [string]$WmiObject.DatabaseEncrypt
        $storedMode = [string]$WmiObject.DatabaseEncryptMode
        if ($supportsEncryptMode -and
            @('False', 'No', 'True', 'Yes', 'Optional', 'Mandatory', 'Strict') -contains $storedMode)
        {
            $parameters['EncryptMode'] = $storedMode
        }
    }

    if ($BoundParameters.ContainsKey('DatabaseMultiSubnetFailover'))
    {
        if (-not (Test-RsWmiMethodParameter -Parameters $parameters -Name 'MultiSubnetFailover'))
        {
            throw "The connected Report Server WMI provider does not support DatabaseMultiSubnetFailover."
        }
        $parameters['MultiSubnetFailover'] = [bool]$BoundParameters['DatabaseMultiSubnetFailover']
    }

    if ($BoundParameters.ContainsKey('DatabaseTrustServerCertificate'))
    {
        if (-not (Test-RsWmiMethodParameter -Parameters $parameters -Name 'TrustServerCertificate'))
        {
            throw "The connected Report Server WMI provider does not support DatabaseTrustServerCertificate."
        }
        $parameters['TrustServerCertificate'] = [bool]$BoundParameters['DatabaseTrustServerCertificate']
    }

    return $parameters
}
