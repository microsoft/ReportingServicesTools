# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsDatabaseConnectionParameters
{
    [CmdletBinding()]
    param (
        [object]
        $WmiObject,

        [System.Collections.IDictionary]
        $BoundParameters
    )

    if (-not $BoundParameters.ContainsKey('DatabaseEncryptMode') -and
        -not $BoundParameters.ContainsKey('DatabaseMultiSubnetFailover') -and
        -not $BoundParameters.ContainsKey('DatabaseTrustServerCertificate'))
    {
        return $null
    }

    $parameters = $WmiObject.GetMethodParameters('SetDatabaseConnection')
    if ($null -eq $parameters.Properties['Encrypt'])
    {
        throw "The connected Report Server WMI provider does not support runtime database encryption options."
    }

    if ($BoundParameters.ContainsKey('DatabaseEncryptMode'))
    {
        $mode = switch ($BoundParameters['DatabaseEncryptMode'])
        {
            'Optional' { 'False' }
            'Mandatory' { 'True' }
            'Strict' { 'Strict' }
        }

        if ($null -ne $parameters.Properties['EncryptMode'])
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
        # Changing failover or certificate trust must not reset encryption, including Strict.
        $parameters['Encrypt'] = @('True', 'Yes', 'Mandatory', 'Strict') -contains [string]$WmiObject.DatabaseEncrypt
        if ($null -ne $parameters.Properties['EncryptMode'] -and -not [string]::IsNullOrEmpty($WmiObject.DatabaseEncryptMode))
        {
            $parameters['EncryptMode'] = $WmiObject.DatabaseEncryptMode
        }
    }

    if ($BoundParameters.ContainsKey('DatabaseMultiSubnetFailover'))
    {
        if ($null -eq $parameters.Properties['MultiSubnetFailover'])
        {
            throw "The connected Report Server WMI provider does not support DatabaseMultiSubnetFailover."
        }
        $parameters['MultiSubnetFailover'] = [bool]$BoundParameters['DatabaseMultiSubnetFailover']
    }

    if ($BoundParameters.ContainsKey('DatabaseTrustServerCertificate'))
    {
        if ($null -eq $parameters.Properties['TrustServerCertificate'])
        {
            throw "The connected Report Server WMI provider does not support DatabaseTrustServerCertificate."
        }
        $parameters['TrustServerCertificate'] = [bool]$BoundParameters['DatabaseTrustServerCertificate']
    }

    return $parameters
}
