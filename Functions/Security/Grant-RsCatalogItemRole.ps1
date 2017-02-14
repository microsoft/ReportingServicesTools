# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Grant-RsCatalogItemRole
{
    <#
        .SYNOPSIS
            This script grants access to catalog items to users/groups.
        
        .DESCRIPTION
            This script grants the specified role access to the specified user/group on the specified catalog item using either current user's credentials or specified credentials.
        
        .PARAMETER Identity
            Specify the user or group name to grant access to.
        
        .PARAMETER RoleName
            Specify the name of the role you want to grant on the catalog item.
        
        .PARAMETER Path
            Specify the path to catalog item on the server.
    
        .PARAMETER Strict
            Setting this parameter causes the function to replace all soft terminations with exceptions.
            When trying to grant permissions already assigned, this will cause a terminating error.
    
        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Credential
            Specify the password to use when connecting to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.
        
        .EXAMPLE
            Grant-RsCatalogItemRole -Identity 'johnd' -RoleName 'Browser' -Path '/My Folder/SalesReport'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and then grant Browser access to user 'johnd' on catalog item found at '/My Folder/SalesReport'.
        
        .EXAMPLE
            Grant-RsCatalogItemRole -ReportServerUri 'http://localhost/reportserver_sql2012' -Identity 'johnd' -RoleName 'Browser' -Path '/My Folder/SalesReport'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver_2012 using current user's credentials and then grant Browser access to user 'johnd' on catalog item found at '/My Folder/SalesReport'.
        
        .EXAMPLE
            Grant-RsCatalogItemRole -Credential 'CaptainAwesome' -Identity 'johnd' -RoleName 'Browser' -Path '/My Folder/SalesReport'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using CaptainAwesome's credentials and then grant Browser access to user 'johnd' on catalog item found at '/My Folder/SalesReport'.
    #>
    
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Alias('UserOrGroupName')]
        [Parameter(Mandatory = $True)]
        [string]
        $Identity,
        
        [Parameter(Mandatory = $True)]
        [string]
        $RoleName,
        
        [Alias('ItemPath')]
        [Parameter(Mandatory = $True)]
        [string]
        $Path,
        
        [switch]
        $Strict,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetweb -BoundParameters $PSBoundParameters), "Grant $RoleName on $Path to $Identity"))
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        
        #region Retrieving and checking roles and policies
        # retrieving roles from the proxy 
        Write-Verbose "Retrieving valid roles for Catalog items..."
        try
        {
            $roles = $proxy.ListRoles("Catalog", $null)
        }
        catch
        {
            throw (New-Object System.Exception("Error retrieving roles for catalog items! $($_.Exception.Message)", $_.Exception))
        }
        
        # validating the role name provided by user
        if ($roles.Name -notcontains $RoleName)
        {
            throw "Role name is not valid. Valid options are: $($roles.Name -join ", ")"
        }
        
        # retrieving existing policies for the current item
        try
        {
            Write-Verbose "Retrieving policies for $Path..."
            $inheritsParentPolicy = $false
            $originalPolicies = $proxy.GetPolicies($Path, [ref]$inheritsParentPolicy)
        }
        catch
        {
            throw (New-Object System.Exception("Error retrieving existing policies for $Path! $($_.Exception.Message)", $_.Exception))
        }
        Write-Verbose "Policies retrieved: $($originalPolicies.Length)!"
        
        # checking if the specified role already exists on the specified user/group name for specified catalog item
        if (($originalPolicies | Where-Object { $_.GroupUserName -eq $Identity }).Roles.Name -contains $RoleName)
        {
            if ($Strict)
            {
                throw "$($Identity) already has $($RoleName) privileges"
            }
            else
            {
                Write-Warning "$($Identity) already has $($RoleName) privileges"
                return
            }
        }
        #endregion Retrieving and checking roles and policies
        
        #region Assign Permissions
        # determining namespace of the proxy and the names of needed data types 
        $namespace = $proxy.GetType().Namespace
        $policyDataType = $namespace + '.Policy'
        $roleDataType = $namespace + '.Role'
        
        # copying all the original policies so that we don't lose them
        $numPolicies = $originalPolicies.Length + 1
        $policies = New-Object -TypeName "$policyDataType[]" -ArgumentList $numPolicies
        $index = 0
        foreach ($originalPolicy in $originalPolicies)
        {
            $policies[$index++] = $originalPolicy
        }
        
        # creating new policy
        $policy = New-Object -TypeName $policyDataType
        $policy.GroupUserName = $Identity
        
        # creating new role
        $role = New-Object -TypeName $roleDataType
        $role.Name = $RoleName
        
        # associating role to the policy
        $numRoles = 1
        $policy.Roles = New-Object -TypeName "$roleDataType[]" -ArgumentList $numRoles
        $policy.Roles[0] = $role
        
        # adding new policy to the policies array
        $policies[$originalPolicies.Length] = $policy
        
        # updating policies on the item
        try
        {
            Write-Verbose "Granting $($role.Name) to $($policy.GroupUserName) on $Path..."
            $proxy.SetPolicies($Path, $policies)
            Write-Verbose "Granted $($role.Name) to $($policy.GroupUserName) on $Path!"
        }
        catch
        {
            throw (New-Object System.Exception("Error occurred while granting $($role.Name) to $($policy.GroupUserName) on $Path! $($_.Exception.Message)", $_.Exception))
        }
        #endregion Assign Permissions
    }
}
New-Alias -Name "Grant-AccessOnCatalogItem" -Value Grant-RsCatalogItemRole -Scope Global
