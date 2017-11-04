# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Out-RsRestFolderContent
{
    <#
        .SYNOPSIS
            This command downloads catalog items from a folder in report server to disk (using REST endpoint). It is for SQL Server Reporting Service 2016 and later.
        
        .DESCRIPTION
            This command downloads catalog items from a folder in report server to disk (using REST endpoint). It is for SQL Server Reporting Service 2016 and later.
        
        .PARAMETER RsFolder
            Path to folder on report server to download catalog items from.
        
        .PARAMETER Destination
            Folder to download catalog item to.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v1.0". 
            NOTE: v1.0 of REST Endpoint is not supported by Microsoft.

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Out-RsRestFolderContent -RsFolder /folder -Destination 'C:\reports'
            
            Description
            -----------
            Downloads all items found under '/folder' folder to 'C:\reports' using v2.0 REST Endpoint located at http://localhost/reports.

        .EXAMPLE
            Out-RsRestFolderContent -RsFolder '/folder' -Destination 'C:\reports' -RestApiVersion 'v1.0'
            
            Description
            -----------
            Downloads all items found under '/folder' folder to 'C:\reports' using v1.0 REST Endpoint located at http://localhost/reports.

        .EXAMPLE
            Out-RsRestFolderContent -WebSession $mySession -RsFolder '/folder' -Destination 'C:\reports'
            
            Description
            -----------
            Downloads all items found under '/folder' folder to 'C:\reports' using v2.0 REST Endpoint.

        .EXAMPLE
            Out-RsRestFolderContent -ReportPortalUri 'http://myserver/reports' -RsFolder '/folder' -Destination 'C:\reports'
            
            Description
            -----------
            Downloads all items found under '/folder' folder to 'C:\reports' using v2.0 REST Endpoint located at http://myserver/reports.
    #>

    [CmdletBinding()]
    param (
        [Alias('ItemPath', 'Path')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string]
        $RsFolder,
        
        [ValidateScript({ Test-Path $_ -PathType Container})]
        [Parameter(Mandatory = $True)]
        [string]
        $Destination,

        [Switch]
        $Recurse,

        [string]
        $ReportPortalUri,

        [Alias('ApiVersion')]
        [ValidateSet("v1.0", "v2.0")]
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
        $catalogItemsByPathApiV1 = $ReportPortalUri + "api/v1.0/CatalogItemByPath(path=@path)?@path=%27{0}%27"
        $folderCatalogItemsApiV1 = $ReportPortalUri + "api/v1.0/CatalogItems({0})/Model.Folder/CatalogItems"
        $folderCatalogItemsApiLatest = $ReportPortalUri + "api/$RestApiVersion/Folders(Path='{0}')/CatalogItems"
    }
    Process
    {
        if ($RestApiVersion -eq 'v1.0')
        {
            try
            {
                Write-Verbose "Fetching $RsFolder info from server..."
                $url = [string]::Format($catalogItemsByPathApiV1, $RsFolder)
                if ($Credential -ne $null)
                {
                    $response = Invoke-WebRequest -Uri $url -Method Get -Credential $Credential -Verbose:$false
                }
                else
                {
                    $response = Invoke-WebRequest -Uri $url -Method Get -UseDefaultCredentials -Verbose:$false
                }
            }
            catch
            {
                throw (New-Object System.Exception("Error while trying to fetch $RsFolder info! Exception: $($_.Exception.Message)", $_.Exception))
            }

            $folder = ConvertFrom-Json $response.Content

            try
            {
                Write-Verbose "Fetching catalog items under $RsFolder from server..."
                $url = [string]::Format($folderCatalogItemsApiV1, $folder.Id)
                if ($Credential -ne $null)
                {
                    $response = Invoke-WebRequest -Uri $url -Method Get -Credential $Credential -Verbose:$false
                }
                else
                {
                    $response = Invoke-WebRequest -Uri $url -Method Get -UseDefaultCredentials -Verbose:$false
                }
            }
            catch
            {
                throw (New-Object System.Exception("Error while trying to fetch catalog items under $RsFolder! Exception: $($_.Exception.Message)", $_.Exception))
            }
        }
        else
        {
            try
            {
                Write-Verbose "Fetching catalog items under $RsFolder from server..."
                $url = [string]::Format($folderCatalogItemsApiLatest, $RsFolder)
                if ($Credential -ne $null)
                {
                    $response = Invoke-WebRequest -Uri $url -Method Get -Credential $Credential -Verbose:$false
                }
                else
                {
                    $response = Invoke-WebRequest -Uri $url -Method Get -UseDefaultCredentials -Verbose:$false
                }
            }
            catch
            {
                throw (New-Object System.Exception("Error while trying to fetch catalog items under $RsFolder! Exception: $($_.Exception.Message)", $_.Exception))
            }
        }

        $catalogItems = (ConvertFrom-Json $response.Content).value
        foreach ($catalogItem in $catalogItems)
        {
            if ($catalogItem.Type -eq "Report" -or
                $catalogItem.Type -eq "DataSet" -or
                $catalogItem.Type -eq "DataSource" -or
                $catalogItem.Type -eq "MobileReport" -or
                $catalogItem.Type -eq "PowerBIReport")
            {
                Write-Verbose "Parsing metadata for $($catalogItem.Name)..."
                Out-RsRestCatalogItemId -RsItemInfo $catalogItem -Destination $Destination -ReportPortalUri $ReportPortalUri -RestApiVersion $RestApiVersion -Credential $Credential -WebSession $WebSession
            }
            elseif ($catalogItem.Type -eq "Folder" -and $Recurse)
            {
                $subFolderPath = "$Destination\$($catalogItem.Name)"
                Write-Verbose "Creating folder $($catalogItem.Name)..."
                New-Item -Path $subFolderPath -ItemType Directory

                Out-RsRestFolderContent -RsFolder $catalogItem.Path -Destination $subFolderPath -ReportPortalUri $ReportPortalUri -RestApiVersion $RestApiVersion -Credential $Credential -WebSession $WebSession
            }
        }
    }
}