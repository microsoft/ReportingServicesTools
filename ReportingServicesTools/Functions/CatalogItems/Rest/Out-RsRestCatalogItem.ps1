# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Out-RsRestCatalogItem
{
    <#
        .SYNOPSIS
            This command downloads catalog items from a report server to disk.
        
        .DESCRIPTION
            This command downloads catalog items from a report server to disk.
        
        .PARAMETER RsFolder
            Path to catalog item to download.
        
        .PARAMETER Destination
            Folder to download catalog item to.
        
        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.
        
        .PARAMETER Credential
            Specify the password to use when connecting to your SQL Server Reporting Services Instance.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Out-RsCatalogItem -WebSession $mySession -RsFolder /Report -Destination C:\reports
            
            Description
            -----------
            Download catalog item 'Report' to folder 'C:\reports'.

        .EXAMPLE
            Out-RsCatalogItem -ReportPortalUri 'http://localhost/reports_sql2016' -RsFolder '/Report' -Destination 'C:\reports'
            
            Description
            -----------
            Downloads catalog item found at '/Report' to folder 'C:\reports'.

        .EXAMPLE 
            Out-RsCatalogItem -WebSession $mySession -RsFolder '/Report' -Destination 'C:\reports'
            
            Description
            -----------
            Downloads catalog item found at '/Report' to folder 'C:\reports'.
    #>

    [CmdletBinding()]
    param (
        [Alias('ItemPath', 'Path')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $RsFolder,
        
        [ValidateScript({ Test-Path $_ -PathType Container})]
        [Parameter(Mandatory = $True)]
        [string]
        $Destination,
        
        [string]
        $ReportPortalUri,
        
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
        $DestinationFullPath = Convert-Path $Destination
        $catalogItemsByPathApi = $ReportPortalUri + 'api/v1.0/CatalogItemByPath(path=@path)?@path=%27{0}%27'
        $catalogItemContentApi = $ReportPortalUri + 'api/v1.0/CatalogItems({0})/Content/$value'
    }
    Process
    {
        foreach ($item in $RsFolder)
        {
            try
            {
                Write-Verbose "Fetching item metadata from server..."
                $url = [string]::Format($catalogItemsByPathApi, $item)
                if ($Credential -ne $null)
                {
                    $response = Invoke-WebRequest -Uri $url -Method Get -WebSession $WebSession -Credential $Credential
                }
                else
                {
                    $response = Invoke-WebRequest -Uri $url -Method Get -WebSession $WebSession -UseDefaultCredentials
                }
            }
            catch
            {
                throw (New-Object System.Exception("Error while trying to fetch metadata for $item! Exception: $($_.Exception.Message)", $_.Exception))
            }

            Write-Verbose "Parsing item metadata..."
            $itemInfo = ConvertFrom-Json $response.Content
            if ($itemInfo.Type -ne 'MobileReport')
            {
                $itemId = $itemInfo.Id
                $fileName = $itemInfo.Name + (Get-FileExtension -TypeName $itemInfo.Type)
            }
            else
            {
                $packageIdProperty = $itemInfo.Properties | Where-Object { $_.Name -eq 'PackageId' }
                if ($packageIdProperty -ne $null)
                {
                    $itemId = $packageIdProperty.Value
                }
                else
                {
                    throw "Unable to determine Id for $item!"
                }

                $packageNameProperty = $itemInfo.Properties | Where-Object { $_.Name -eq 'PackageName' }
                if ($packageNameProperty -ne $null)
                {
                    $fileName = $packageNameProperty.Value
                }
                else
                {
                    $fileName = $itemInfo.Name + '.rsmobile'
                }
            }

            try
            {
                Write-Verbose "Downloading item from server..."
                $url = [string]::Format($catalogItemContentApi, $itemId)
                if ($Credential -ne $null)
                {
                    $response = Invoke-WebRequest -Uri $url -Method Get -WebSession $WebSession -Credential $Credential -ErrorAction Stop
                }
                else
                {
                    $response = Invoke-WebRequest -Uri $url -Method Get -WebSession $WebSession -UseDefaultCredentials -ErrorAction Stop
                }
            }
            catch
            {
                throw (New-Object System.Exception("Error while downloading $item! Exception: $($_.Exception.Message)", $_.Exception))
            }

            Write-Verbose "Writing content to $destinationFilePath..."
            $destinationFilePath = Join-Path -Path $DestinationFullPath -ChildPath $fileName
            [System.IO.File]::WriteAllBytes($destinationFilePath, $response.Content)
            Write-Verbose "$item was downloaded to $destinationFilePath successfully!"
        }
    }
}