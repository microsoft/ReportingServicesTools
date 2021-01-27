# Copyright (c) 2020 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)
function Get-RsRestFolderContent
{
    <#
        .SYNOPSIS
            This function fetches data sources related to a catalog item from the Report Server.

        .DESCRIPTION
            This function fetches data sources related to a catalog item from the Report Server, using the REST API.

        .PARAMETER RsFolder
            Specify the location of the catalog item whose data sources should be fetched.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Get-RsRestFolderContent -ReportPortalUri 'http://localhost/reportserver_sql2012' -RsFolder /
            
            Description
            -----------
            List all items directly under the root folder
    
        .EXAMPLE
            Get-RsRestFolderContent -ReportServerUri http://localhost/ReportServer -RsFolder / -Recurse

            Description
            -----------
            Lists all items directly under the root of the SSRS instance and recursively under all sub-folders.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [Alias('ItemPath','Path')]
        [string]
        $RsFolder,
        
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
        $catalogItemsUri = $ReportPortalUri + "api/$RestApiVersion/Folders(Path='{0}')/CatalogItems?`$expand=Properties"
    }
    Process
    {
        try
        {
            Write-Verbose "Fetching metadata for $RsFolder..."
            $url = [String]::Format($catalogItemsUri, $RsFolder)
            if ($Credential -ne $null)
            {
                $response = Invoke-WebRequest -Uri $url -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
            }
            else
            {
                $response = Invoke-WebRequest -Uri $url -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
            }

            $catalogItems = (ConvertFrom-Json $response.Content).value
            foreach ($catalogItem in $catalogItems)
            {
                if ($catalogItem.Type -eq "Folder")
                {
                    if ($Recurse)
                    {
                        # check for subfolders
                        $subFolderPath = "$RsFolder/$($catalogItem.Name)"
                        Write-Verbose "Searching folder $($subFolderPath)"
    
                        # get contents of the subfolders
                        Get-RsRestFolderContent -RsFolder $catalogItem.Path -ReportPortalUri $ReportPortalUri -RestApiVersion $RestApiVersion -Credential $Credential -WebSession $WebSession -Recurse
                        
                        [pscustomobject]@{
                            Type = $catalogItem.Type
                            Name = $catalogItem.Name
                            Size = $catalogItem.Size
                            ModifiedBy = $catalogItem.ModifiedBy
                            ModifiedDate = $catalogItem.ModifiedDate
                            Hidden = $catalogItem.Hidden
                            Path = $catalogItem.Path
                            Id   = $catalogItem.Id
                            Description = $catalogItem.Description
                        }
                    }
                    else
                    {
                        [pscustomobject]@{
                            Type = $catalogItem.Type
                            Name = $catalogItem.Name
                            Size = $catalogItem.Size
                            ModifiedBy = $catalogItem.ModifiedBy
                            ModifiedDate = $catalogItem.ModifiedDate
                            Hidden = $catalogItem.Hidden
                            Path = $catalogItem.Path
                            Id   = $catalogItem.Id
                            Description = $catalogItem.Description
                        }
                    }    
                }
                else
                {
                    #display contents of $catalogItem
                    Write-Verbose "Parsing metadata for child item $($catalogItem.Name)..."

                    [pscustomobject]@{
                        Type = $catalogItem.Type
                        Name = $catalogItem.Name
                        Size = $catalogItem.Size
                        ModifiedBy = $catalogItem.ModifiedBy
                        ModifiedDate = $catalogItem.ModifiedDate
                        Hidden = $catalogItem.Hidden
                        Path = $catalogItem.Path
                        Id   = $catalogItem.Id
                        Description = $catalogItem.Description
                    }
                }
            }
        }
        catch
        {
            Write-Warning "Failed to get content for '$RsFolder': $($_.Exception.Message)"
        }
    }
}
