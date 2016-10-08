# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Grant-AccessOnCatalogItem
{
    <#
    .SYNOPSIS
        This script grants access to catalog items to users/groups.

    .DESCRIPTION
        This script grants the specified role access to the specified user/group on the specified catalog item using either current user's credentials or specified credentials. 

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

    .PARAMETER ItemPath
        Specify the path to catalog item on the server.
    
    .EXAMPLE
        Grant-AccessOnCatalogItem -UserOrGroupName 'johnd' -RoleName 'Browser' -ItemPath '/My Folder/SalesReport'
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and then grant Browser access to user 'johnd' on catalog item found at '/My Folder/SalesReport'.
    
    .EXAMPLE
        Grant-AccessOnCatalogItem -ReportServerUri 'http://localhost/reportserver_sql2012' -UserOrGroupName 'johnd' -RoleName 'Browser' -ItemPath '/My Folder/SalesReport'
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver_2012 using current user's credentials and then grant Browser access to user 'johnd' on catalog item found at '/My Folder/SalesReport'.

    .EXAMPLE
        Grant-AccessOnCatalogItem -ReportServerUsername 'CaptainAwesome' -ReportServerPassword 'CaptainAwesomesPassword' -UserOrGroupName 'johnd' -RoleName 'Browser' -ItemPath '/My Folder/SalesReport'
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using CaptainAwesome's credentials and then grant Browser access to user 'johnd' on catalog item found at '/My Folder/SalesReport'.
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
        $RoleName,
        
        [Parameter(Mandatory=$True)]
        [string]
        $ItemPath
    )

    # creating proxy
    $proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Username $ReportServerUsername -Password $ReportServerPassword

    # retrieving roles from the proxy 
    Write-Verbose "Retrieving valid roles for Catalog items..."
    $roles = $proxy.ListRoles("Catalog", $null)

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
        $errorMessage = "Role name is not valid. Valid options are: "
        foreach ($role in $roles)
        {
            $errorMessage = $errorMessage + $role.Name + ', ' 
        }
        Write-Error $errorMessage
        Exit 1
    }

    # retrieving existing policies for the current item
    try
    {
        Write-Verbose "Retrieving policies for $ItemPath..."
        $inheritsParentPolicy = $false
        $originalPolicies = $proxy.GetPolicies($ItemPath, [ref] $inheritsParentPolicy)
        
        Write-Verbose "Policies retrieved: $($originalPolicies.Length)!"
        
        # checking if the specified role already exists on the specified user/group name for specified catalog item 
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
        Write-Error "Error retrieving existing policies for $ItemPath! `n$($_.Exception.Message)"
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
        Write-Verbose "Granting $($role.Name) to $($policy.GroupUserName) on $ItemPath..." 
        $proxy.SetPolicies($ItemPath, $policies)
        Write-Verbose "Granted $($role.Name) to $($policy.GroupUserName) on $ItemPath!"
    }
    catch [System.Web.Services.Protocols.SoapException]
    {
        Write-Error "Error occurred while granting $($role.Name) to $($policy.GroupUserName) on $ItemPath! `n$($_.Exception.Message)"
        Exit 3
    }
}
