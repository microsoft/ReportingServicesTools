# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Grant-AccessToRs
{
    <#
    .SYNOPSIS
        This script grants access to SQL Server Reporting Services Instance to users/groups.

    .DESCRIPTION
        This script grants the specified role access to the specified user/group to the SQL Server Reporting Services Instance located at the specified Report Server URI. 

    .PARAMETER ReportServerUri (optional)
        Specify the Report Server URL to your SQL Server Reporting Services Instance.

    .PARAMETER ReportServerUsername (optional)
        Specify the user name to use when connecting to your SQL Server Reporting Services Instance.

    .PARAMETER ReportServerPassword (optional)
        Specify the password to use when connecting to your SQL Server Reporting Services Instance.

    .PARAMETER UserOrGroupName
        Specify the user or group name to grant access to.
        
    .PARAMETER RoleName
        Specify the name of the role you want to grant on the catalog item.

    .EXAMPLE
        Grant-AccessToRs -UserOrGroupName 'johnd' -RoleName 'System User'
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and then grant 'System User' access to user 'johnd'.
    
    .EXAMPLE
        Grant-AccessToRs -ReportServerUri 'http://localhost/reportserver_sql2012' -UserOrGroupName 'johnd' -RoleName 'System User'
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver_2012 using current user's credentials and then grant 'System User' access to user 'johnd'.

    .EXAMPLE
        Grant-AccessToRs -ReportServerUsername 'CaptainAwesome' -ReportServerPassword 'CaptainAwesomesPassword' -UserOrGroupName 'johnd' -RoleName 'System User'
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using CaptainAwesome's credentials and then grant 'System User' access to user 'johnd'.  
    #>

    [cmdletbinding()]
    param
    (
        [string]
        $ReportServerUri = 'http://localhost/reportserver',
        
        [string]
        $ReportServerUsername,

        [string]
        $ReportServerPassword,
        
        [Parameter(Mandatory=$True)]
        [string]
        $UserOrGroupName,
        
        [Parameter(Mandatory=$True)]
        [string]
        $RoleName
    )

    # creating proxy
    $proxy = New-RsWebServiceProxy -ReportServerUri $ReportServerUri -Username $ReportServerUsername -Password $ReportServerPassword 

    # retrieving roles from the proxy 
    Write-Verbose 'Retrieving valid roles for System Policies...'
    $roles = $proxy.ListRoles("System", $null)

    # validating the role name provided by user
    Write-Verbose "Validating role name specified: $RoleName..."
    $isRoleValid = $false
    foreach ($role in $roles)
    {
        if ($role.Name.Equals($RoleName, [StringComparison]::OrdinalIgnoreCase))
        {
            $isRoleValid = $true
            break
        }
    }

    if (!$isRoleValid)
    {
        $errorMessage = 'Role name is not valid. Valid options are: '
        foreach ($role in $roles)
        {
            $errorMessage = $errorMessage + $role.Name + ', ' 
        }

        Write-Error $errorMessage
        Exit 1
    }

    Write-verbose 'retrieving existing system policies'
    try
    {
        Write-Verbose "Retrieving system policies..."
        $originalPolicies = $proxy.GetSystemPolicies()
        
        Write-Verbose "Policies retrieved: $($originalPolicies.Length)!"

        Write-Verbose 'checking if the specified role already exists for the specified user/group name'
        foreach ($policy in $originalPolicies)
        {
            if ($policy.GroupUserName.Equals($UserOrGroupName, [StringComparison]::OrdinalIgnoreCase))
            {
                foreach ($role in $policy.Roles)
                {
                    if ($role.Name.Equals($RoleName, [StringComparison]::OrdinalIgnoreCase))
                    {
                        Write-Warning "$($UserOrGroupName) already has $($RoleName) privileges"
                        return
                    }
                }
            }

            Write-Debug "Policy: $($policy.GroupUserName) is $($policy.Roles[0].Name)" 
        }
    }
    catch [System.Web.Services.Protocols.SoapException]
    {
        Write-Error "Error retrieving existing system policies! `n$($_.Exception.Message)"
        Exit 2
    }

    # determining namespace of the proxy and the names of needed data types 
    $namespace = $proxy.GetType().Namespace
    $policyDataType = ($namespace + '.Policy')
    $roleDataType = ($namespace + '.Role')

    # copying all the original policies so that we don't lose them
    $numPolicies = $originalPolicies.Length + 1
    $policies = New-Object ($policyDataType + '[]')$numPolicies
    $index = 0
    foreach ($originalPolicy in $originalPolicies)
    {
        $policies[$index++] = $originalPolicy
    }

    # creating new policy
    $policy = New-Object ($policyDataType)
    $policy.GroupUserName = $UserOrGroupName

    # creating new role
    $role = New-Object ($roleDataType)
    $role.Name = $RoleName

    # associating role to the policy
    $numRoles = 1
    $policy.Roles = New-Object($roleDataType + '[]')$numRoles
    $policy.Roles[0] = $role

    # adding new policy to the policies array
    $policies[$originalPolicies.Length] = $policy

    # updating policies on the item
    try
    {
        Write-Verbose "Granting $($role.Name) to $($policy.GroupUserName)..." 
        $proxy.SetSystemPolicies($policies)
        Write-Verbose "Granted $($role.Name) to $($policy.GroupUserName)!"
    }
    catch [System.Web.Services.Protocols.SoapException]
    {
        Write-Error "Error occurred while granting $($role.Name) to $($policy.GroupUserName)! `n$($_.Exception.Message)"
        Exit 3
    }
}
