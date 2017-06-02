# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsCatalogItemRole
{
    <#
        .SYNOPSIS
            This script retrieves access to SQL Server Reporting Services Instance from users/groups.
        
        .DESCRIPTION
            This script retrieves all access on the SQL Server Reporting Services Instance located at the specified Report Server URI from the specified user/group.
        
        .PARAMETER Identity
            Specify the user or group name to retrieve access for.

        .PARAMETER Path
            Specify the path to catalog item on the server.

       .PARAMETER Recurse
            Recursively list subfolders with content.
        
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
            Get-RsCatalogItemRole -Identity 'jmcgee'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and then retrieves all access for user 'jmcgee'.
        
        .EXAMPLE
            Get-RsCatalogItemRole -ReportServerUri 'http://localhost/reportserver_sql2012' -Identity 'jmcgee'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver_2012 using current user's credentials and then retrieves all access for user 'jmcgee'.

        .EXAMPLE
            Get-RsCatalogItemRole -ReportServerUri 'http://localhost/reportserver_sql2012' -path '/Path/Human Resources/'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver_2012 using current user's credentials and then retrieves all access on catalog items found at '/Path/Human Resources/'.
        
        .EXAMPLE
            Get-RsCatalogItemRole -Credential 'CaptainAwesome' -Identity 'jmcgee' -Recurse
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using CaptainAwesome's credentials and then retrieves all access for user 'jmcgee' recursively.
    #>

    [CmdletBinding()]
    param
    (
        [string]
        $Identity,
        
        [string]
        $Path = "/",

        [switch]
        $Recurse,
        
        [string]
        $ReportServerUri,
        
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    Begin
    {

        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters

        $GetRsFolderContentParam = @{
            Proxy = $Proxy
            RsFolder = $Path
            Recurse = $Recurse
            ErrorAction = 'Stop'
        }

        try
        {
            $items = Get-RsFolderContent @GetRsFolderContentParam
        }
        catch
        {
            throw (New-Object System.Exception("Failed to retrieve items in '$RsFolder': $($_.Exception.Message)", $_.Exception))
        }

    }
        
    Process
    {

        $inheritParent = $true
        $catalogItemRoles = @()

        foreach($item in $items)
        {
            $policies = $Proxy.GetPolicies($item.path, [ref]$inheritParent)

            # Filter Polices by Identity
            if($Identity) {
                $policies = $policies | Where-Object { $_.GroupUserName -eq $Identity }
            }

            foreach($policy in $policies)
            {
                # Creating an object to merge data from both sources. 
                $catalogItemRole = New-Object –TypeName PSCustomObject
                $catalogItemRole | Add-Member –MemberType NoteProperty –Name Identity –Value $policy.GroupUserName
                $catalogItemRole | Add-Member –MemberType NoteProperty –Name Path –Value $($item.Path + "/" + $item.Name)
                $catalogItemRole | Add-Member –MemberType NoteProperty –Name TypeName –Value $item.TypeName
                $catalogItemRole | Add-Member –MemberType NoteProperty –Name Roles –Value $policy.Roles

                $catalogItemRoles += $catalogItemRole
            }
        }

        return $catalogItemRoles
    }
}