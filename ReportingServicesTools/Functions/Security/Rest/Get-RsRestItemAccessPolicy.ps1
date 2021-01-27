# Copyright (c) 2021 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsRestItemAccessPolicy
{
    <#
        .SYNOPSIS
            This function retrieves access policies to SQL Server Reporting Services Instance or Power BI Report Server Instance from users/groups.

        .DESCRIPTION
            This function retrieves all access policies on the SQL Server Reporting Services Instance or Power BI Report Server Instance located at the specified Report Server URI from the specified user/group.

        .PARAMETER RsItem
            Specify the path to catalog item on the server.

       .PARAMETER Recurse
            Recursively list subfolders with content.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Get-RsRestItemAccessPolicy -RsItem "/MyReport"
            Description
            -----------
            Fetches Policy object for the "MyReport" catalog item found in "/" folder from the Report Server located at http://localhost/reports and returns all access for all users & groups.
        .EXAMPLE
            Get-RsRestItemAccessPolicy -RsItem "/MyReport" -Identity 'jeremymcgee'
            Description
            -----------
            Fetches Policy object the "MyReport" catalog item found in "/" folder from the Report Server located at http://localhost/reports using current user's credentials and then retrieves all access for user 'jmcgee'.
        .EXAMPLE
            Get-RsRestItemAccessPolicy -RsItem "/MyReport" -ReportPortalUri http://myserver/reports
            Description
            -----------
            Fetches Policy object for the "MyReport" catalog item found in "/" folder from the Report Server located at http://myserver/reports and returns all access for all users & groups.
        .EXAMPLE
            Get-RsRestItemAccessPolicy -RsItem "/Finance" -ReportPortalUri http://myserver/reports -Identity 'jeremymcgee' -Recurse
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reports using current user's credentials and then retrieves all access for user 'jmcgee' recursively.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true)]
        [Alias('ItemPath','Path', 'RsReport')]
        [string]
        $RsItem,

        [string]
        $Identity,

        [switch]
        $Recurse,

        [string]
        $ReportPortalUri,

        [Alias('ApiVersion')]
        [ValidateSet("v2.0")]
        [string]
        $RestApiVersion = "v2.0",

        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )
    Begin
    {
        $WebSession = New-RsRestSessionHelper -BoundParameters $PSBoundParameters
        $ReportPortalUri = Get-RsPortalUriHelper -WebSession $WebSession
        $PolicyUri = $ReportPortalUri + "api/$RestApiVersion/CatalogItems({0})/Policies"
    }
    Process
    {
        try
        {
            Write-Verbose "Fetching metadata for $RsItem..."
            if ($Credential -ne $null)
            {
                $Item = Get-RsRestItem -ReportPortalUri $ReportPortalUri -RsItem $RsItem -WebSession $WebSession -Credential $Credential -Verbose:$false
            }
            else
            {
                $Item = Get-RsRestItem -ReportPortalUri $ReportPortalUri -RsItem $RsItem -WebSession $WebSession -Verbose:$false
            }

            Write-Verbose "Fetching Policies for $RsItem..."
            $PolicyUri = [String]::Format($PolicyUri, $Item.Id)
            if ($Credential -ne $null)
            {
                $response = Invoke-RestMethod -Uri $PolicyUri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
            }
            else
            {
                $response = Invoke-RestMethod -Uri $PolicyUri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
            }

            $catalogItemRoles = @()
            $InheritParentPolicy = $response.InheritParentPolicy

            # Filter Polices by Identity
            if($Identity) {
                $response.Policies = $response.Policies | Where-Object { $_.GroupUserName -eq $Identity }
            }
            
            if($response.Policies) {
                $response.Policies | ForEach-Object {

                    $catalogItemRole = New-Object -TypeName PSCustomObject
                    $catalogItemRole | Add-Member -MemberType NoteProperty -Name Identity -Value $_.GroupUserName
                    $catalogItemRole | Add-Member -MemberType NoteProperty -Name Path -Value $Item.Path
                    $catalogItemRole | Add-Member -MemberType NoteProperty -Name TypeName -Value $Item.Type
                    $catalogItemRole | Add-Member -MemberType NoteProperty -Name Roles -Value $_.Roles.Name
                    $catalogItemRole | Add-Member -MemberType NoteProperty -Name ParentSecurity -Value $InheritParentPolicy
                
                    $catalogItemRoles += $catalogItemRole
                }
            }

            if($Recurse -and $Item.Type -eq "Folder") {

                $GetRsFolderContentParam = @{
                    WebSession = $WebSession
                    RsFolder = $Item.Path
                    Recurse = $Recurse
                    ErrorAction = 'Stop'
                }
    
                try
                {
                    $ChildItems = Get-RsRestFolderContent @GetRsFolderContentParam
                }
                catch
                {
                    throw (New-Object System.Exception("Failed to retrieve items in '$RsFolder': $($_.Exception.Message)", $_.Exception))
                }
    
                foreach($ChildItem in $ChildItems)
                {
                    $PolicyUri = $ReportPortalUri + "api/$RestApiVersion/CatalogItems({0})/Policies"
                    $PolicyUri = [String]::Format($PolicyUri, $ChildItem.Id)
            
                    $childPolicies = Invoke-RestMethod -Uri $PolicyUri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
    
                    # Filter Polices by Identity
                    if($Identity) {
                        $childPolicies.Policies = $childPolicies.Policies | Where-Object { $_.GroupUserName -eq $Identity }
                    }
    
                    if($childPolicies.Policies) {
                        $childPolicies.Policies | ForEach-Object {

                            $catalogItemRole = New-Object -TypeName PSCustomObject
                            $catalogItemRole | Add-Member -MemberType NoteProperty -Name Identity -Value $_.GroupUserName
                            $catalogItemRole | Add-Member -MemberType NoteProperty -Name Path -Value $ChildItem.Path
                            $catalogItemRole | Add-Member -MemberType NoteProperty -Name TypeName -Value $ChildItem.Type
                            $catalogItemRole | Add-Member -MemberType NoteProperty -Name Roles -Value $_.Roles.Name
                            $catalogItemRole | Add-Member -MemberType NoteProperty -Name ParentSecurity -Value $InheritParentPolicy
                        
                            $catalogItemRoles += $catalogItemRole
                        }
                    }
    
    
                }
            }            
            return $catalogItemRoles
        }
        catch
        {
            throw (New-Object System.Exception("Failed to get access policies for '$RsItem': $($_.Exception.Message)", $_.Exception))
        }
    }
}