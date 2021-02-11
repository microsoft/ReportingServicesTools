# Copyright (c) 2021 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Grant-RsRestItemAccessPolicy
{
    <#
        .SYNOPSIS
            This function grants access policies to SQL Server Reporting Services Instance or Power BI Report Server Instance from users/groups.

        .DESCRIPTION
            This function grants all access policies on the SQL Server Reporting Services Instance or Power BI Report Server Instance located at the specified Report Server URI to the specified user/group.

        .PARAMETER RsItem
            Specify the path to catalog item (folder or report) on the server.

        .PARAMETER Identity
            Specify the user or group name to grant access to.

        .PARAMETER Role
            Specify the name of the role you want to grant on the catalog item.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services  or Power BI Report Server Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Grant-RsRestItemAccessPolicy -Identity 'johnd' -Role 'Browser' -Path '/My Folder/SalesReport'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reports using current user's credentials and then grant Browser access to user 'johnd' on catalog item found at '/My Folder/SalesReport'.

        .EXAMPLE
            Grant-RsRestItemAccessPolicy -ReportPortalUri 'http://localhost/reports_sql2012' -Identity 'johnd' -Role 'Browser' -Path '/My Folder/SalesReport'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reports_sql2012 using current user's credentials and then grant Browser access to user 'johnd' on catalog item found at '/My Folder/SalesReport'.

        .EXAMPLE
            Grant-RsRestItemAccessPolicy -Credential 'CaptainAwesome' -Identity 'johnd' -Role 'Browser' -Path '/My Folder/SalesReport'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reports using CaptainAwesome's credentials and then grant Browser access to user 'johnd' on catalog item found at '/My Folder/SalesReport'.

        .EXAMPLE
            Grant-RsRestItemAccessPolicy -Identity 'CONTOSO\Report_Developers' -Role 'Browser' -RsItem '/Finance' -ReportPortalUri https://UATPBIRS/reports
            Description
            -----------
            This command will grant Browser access to members of the 'Report_Developers' domain group to catalog items found under the '/Finance' folder.  It will do this by establishing a connection to the Report Server located at https://UATPBIRS/reports using current user's credentials. 
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true)]
        [Alias('ItemPath','Path', 'RsReport')]
        [string]
        $RsItem,

        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true)]
        [string]
        $Identity,

        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true)]
        [Alias('RoleName')]
        [ValidateSet("Browser","Content Manager","My Reports","Publisher","Report Builder")]
        [string]
        $Role,

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

            if($Item.Type -in 'Report', 'PowerBIReport'){
                Write-Verbose "Fetching Policies for $Item..."
                $PolicyUri = $ReportPortalUri + "api/$RestApiVersion/CatalogItems({0})/Policies"
                $PolicyUri = [String]::Format($PolicyUri, $Item.Id)
                if ($Credential -ne $null)
                {
                    $response = Invoke-RestMethod -Uri $PolicyUri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
                }
                else
                {
                    $response = Invoke-RestMethod -Uri $PolicyUri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
                }
            }
            elseif ($Item.Type -eq 'Folder') {
                Write-Verbose "Fetching Policies for $Item..."
                $PolicyUri = $ReportPortalUri + "api/$RestApiVersion/Folders({0})/Policies"
                $PolicyUri = [String]::Format($PolicyUri, $Item.Id)
                if ($Credential -ne $null)
                {
                    $response = Invoke-RestMethod -Uri $PolicyUri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
                }
                else
                {
                    $response = Invoke-RestMethod -Uri $PolicyUri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
                }
            }
            
            $o=[PSCustomObject]@{
                GroupUserName=$Identity
                Roles=@([PSCustomObject]@{
                    Name=$Role
                    Description=''
                })
            }
            
            $response.Policies=$response.Policies+$o
            $response.InheritParentPolicy=$false

            $payloadJson = $response | ConvertTo-Json -Depth 15
            Write-Verbose "$payloadJson"
            $response = Invoke-RestMethod -Uri $PolicyUri -Method Put -WebSession $WebSession -UseDefaultCredentials -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -Verbose:$false

            return $response
        }
        catch
        {
            throw (New-Object System.Exception("Failed to grant access policies for '$RsItem': $($_.Exception.Message)", $_.Exception))
        }
    }
}