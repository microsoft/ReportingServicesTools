# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RscatalogItemRoleObject
{
    <#
        .SYNOPSIS
            This script creates a new Catalog Item Role Object.
        
        .DESCRIPTION
            This script creates a new Catalog Item Role Object.
        
        .PARAMETER Policy
            Specify the Catalog Item Item Policy to be used
        
        .PARAMETER Path
            Specify the path of the Catalog Item.
        
        .PARAMETER TypeName
            Specity the type of the Catalog Item
        
        .PARAMETER ParentSecurity
            Specifies if the Security is set to the parent of the Catalog Item.

        .EXAMPLE
            $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
            $Policies = $Proxy.GetPolicies("/", [ref]$True)
            New-RsCatalogItemRoleObject -Policy $Policies -Path "/" -TypeName "Folder"

            Description
            -----------
            This command will retrieve and return WMI Object associated to the default instance (MSSQLSERVER) of SQL Server 2016 Reporting Services.
        

    #>

    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$True)]
        [Object[]] $Policy,

        [Parameter(Mandatory=$True)]
        [String]$Path,

        [Parameter(Mandatory=$True)]
        [String]$TypeName,

        [Parameter(Mandatory=$True)]
        [Boolean]$ParentSecurity
    )
    $catalogItemRoles = @()

    $Policy | ForEach-Object {
    
        $catalogItemRole = New-Object -TypeName PSCustomObject
        $catalogItemRole | Add-Member -MemberType NoteProperty -Name Identity -Value $_.GroupUserName
        $catalogItemRole | Add-Member -MemberType NoteProperty -Name Path -Value $Path
        $catalogItemRole | Add-Member -MemberType NoteProperty -Name TypeName -Value $TypeName
        $catalogItemRole | Add-Member -MemberType NoteProperty -Name Roles -Value $_.Roles
        $catalogItemRole | Add-Member -MemberType NoteProperty -Name ParentSecurity -Value $ParentSecurity

        $catalogItemRoles += $catalogItemRole
    }

    return $catalogItemRoles
}
