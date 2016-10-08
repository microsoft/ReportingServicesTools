# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Revoke-AccessOnCatalogItem
{
    <#
    .SYNOPSIS
        This script revokes access to catalog items from users/groups.

    .DESCRIPTION
        This script revokes all access on the specified catalog item from the specified user/group. 

    .PARAMETER ReportServerUri (optional)
        Specify the Report Server URL to your SQL Server Reporting Services Instance.

    .PARAMETER ReportServerUsername (optional)
        Specify the user name to use when connecting to your SQL Server Reporting Services Instance.

    .PARAMETER ReportServerPassword (optional)
        Specify the password to use when connecting to your SQL Server Reporting Services Instance.

    .PARAMETER UserOrGroupName
        Specify the user or group name to revoke access from.

    .PARAMETER ItemPath
        Specify the path to catalog item on the server.

    .EXAMPLE
        Revoke-AccessOnCatalogItem -UserOrGroupName 'johnd' -ItemPath '/My Folder/SalesReport'
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and then revoke all access granted to user 'johnd' on catalog item found at '/My Folder/SalesReport'.
    
    .EXAMPLE
        Revoke-AccessOnCatalogItem -ReportServerUri 'http://localhost/reportserver_sql2012' -UserOrGroupName 'johnd' -ItemPath '/My Folder/SalesReport'
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver_2012 using current user's credentials and then revoke all access granted to user 'johnd' on catalog item found at '/My Folder/SalesReport'.

    .EXAMPLE
        Revoke-AccessOnCatalogItem -ReportServerUsername 'CaptainAwesome' -ReportServerPassword 'CaptainAwesomesPassword' -UserOrGroupName 'johnd' -ItemPath '/My Folder/SalesReport'
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using CaptainAwesome's credentials and then revoke all access to user 'johnd' on catalog item found at '/My Folder/SalesReport'.
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
        $ItemPath
    )

    # creating proxy
    $proxy = New-RsWebServiceProxy -ReportServerUri $ReportServerUri -Username $ReportServerUsername -Password $ReportServerPassword

    # retrieving existing policies for the current item
    try
    {
        Write-Verbose "Retrieving policies for $ItemPath..."
        $inheritsParentPolicy = $false
        $originalPolicies = $proxy.GetPolicies($ItemPath, [ref] $inheritsParentPolicy)
        
        Write-Verbose "Policies retrieved: $($originalPolicies.Length)!"
    }
    catch [System.Web.Services.Protocols.SoapException]
    {
        Write-Error "Error retrieving existing policies for $ItemPath! `n$($_.Exception.Message)"
        Exit 1
    }

    # determining namespace of the proxy and the names of needed data types 
    $namespace = $proxy.GetType().Namespace
    $policyDataType = ($namespace + '.Policy')

    # keeping only those policies where userOrGroupName is not explicitly mentioned
    $policyList = New-Object ("System.Collections.Generic.List[$policyDataType]")
    foreach ($originalPolicy in $originalPolicies)
    {
        if ($originalPolicy.GroupUserName.Equals($UserOrGroupName, [StringComparison]::OrdinalIgnoreCase))
        {
            continue
        }
        $policyList.Add($originalPolicy)
    }

    # updating policies on the item
    try
    {
        Write-Verbose "Revoking all access from $UserOrGroupName on $ItemPath..." 
        $proxy.SetPolicies($ItemPath, $policyList.ToArray())
        Write-Verbose "Revoked all access from $UserOrGroupName on $ItemPath!"
    }
    catch [System.Web.Services.Protocols.SoapException]
    {
        Write-Error "Error occurred while revoking all access from $UserOrGroupName on $ItemPath! `n$($_.Exception.Message)"
        Exit 2
    }
}
