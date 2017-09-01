# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Write-RsRestCatalogItem
{
    <#
        .SYNOPSIS
            This command uploads an item from disk to a report server.
        
        .DESCRIPTION
            This command uploads an item from disk to a report server.
            Currently, we are only supporting Report, DataSource, DataSet and Mobile Report for uploads
        
        .PARAMETER Path
            Path to item to upload on disk.
        
        .PARAMETER RsFolder
            Folder on reportserver to upload the item to.

        .PARAMETER Overwrite
            Overwrite the old entry, if an existing catalog item with same name exists at the specified destination.
        
        .PARAMETER ApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v1.0". 
            NOTE: v1.0 of REST Endpoint is not supported by Microsoft.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.
        
        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
        
        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.
        
        .EXAMPLE
            Write-RsRestCatalogItem -WebSession $mySession -Path 'c:\reports\monthlyreport.rdl' -RsFolder '/monthlyreports' -ApiVersion 'v1.0'
            
            Description
            -----------
            Uploads the report 'monthlyreport.rdl' to folder '/monthlyreports'

        .EXAMPLE
            Write-RsRestCatalogItem -ReportPortalUri 'http://localhost/reports_sql2016' -Path 'c:\reports\monthlyreport.rdl' -RsFolder '/monthlyreports' -ApiVersion 'v1.0'
            
            Description
            -----------
            Uploads the report 'monthlyreport.rdl' to folder '/monthlyreports'
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,
        
        [Alias('DestinationFolder')]
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,

        [Alias('Override')]
        [switch]
        $Overwrite,
        
        [Parameter(Mandatory = $True)]
        [ValidateSet("v1.0")]
        [string]
        $ApiVersion,
        
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
        $catalogItemsUri = $ReportPortalUri + "api/$ApiVersion/CatalogItems"
        $catalogItemsByPathApi = $ReportPortalUri + "api/$ApiVersion/CatalogItemByPath(path=@path)?@path=%27{0}%27"
        $catalogItemsUpdateUri = $ReportPortalUri + "api/$ApiVersion/CatalogItems({0})"
    }
    
    Process
    {
        foreach ($item in $Path)
        {
            if (!(Test-Path $item))
            {
                throw "No item found at the specified path: $item!"
            }

            $EntirePath = Convert-Path $item
            $item = Get-Item $EntirePath
            $itemType = Get-ItemType $item.Extension
            $itemName = $item.BaseName

            if ($itemType -eq "DataSource")
            {
                throw "Data Source creation is currently not supported!"
            }

            $itemPath = ""
            if ($RsFolder -eq "/")
            {
                $itemPath = "/$itemName"
                Write-Verbose "Uploading $EntirePath to $itemPath"
            }
            else
            {
                $itemPath = "$RsFolder/$itemName"
                Write-Verbose "Uploading $EntirePath to $itemPath"
            }

            Write-Verbose "Reading file content..."
            $bytes = [System.IO.File]::ReadAllBytes($EntirePath)
            $payload = @{
                "@odata.type" = "#Model.$itemType";
                "Content" = [System.Convert]::ToBase64String($bytes);
                "ContentType"="";
                "Name" = $itemName;
                "Path" = $itemPath;
            }

            try
            {
                Write-Verbose "Uploading $iteName to $itemPath..."

                $payloadJson = ConvertTo-Json $payload

                if ($Credential -ne $null)
                {
                    Invoke-WebRequest -Uri $catalogItemsUri -Method Post -WebSession $WebSession -Body $payloadJson -ContentType "application/json" -Credential $Credential -Verbose:$false | Out-Null
                }
                else
                {
                    Invoke-WebRequest -Uri $catalogItemsUri -Method Post -WebSession $WebSession -Body $payloadJson -ContentType "application/json" -UseDefaultCredentials -Verbose:$false | Out-Null
                }

                Write-Verbose "$EntirePath was uploaded to $RsFolder successfully!"
            }
            catch
            {
                if ($_.Exception.Response -ne $null -and $_.Exception.Response.StatusCode -eq 409 -and $Overwrite)
                {
                    try
                    {
                        Write-Verbose "$itemName already exists at $itemPath. Retrieving id in order to overwrite it..."
                        $uri = [String]::Format($catalogItemsByPathApi, $itemPath)
                        if ($Credential -ne $null)
                        {
                            $response = Invoke-WebRequest -Uri $uri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
                        }
                        else
                        {
                            $response = Invoke-WebRequest -Uri $uri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
                        }

                        # parsing response to get Id
                        $itemInfo = ConvertFrom-Json $response.Content
                        $itemId = $itemInfo.Id

                        Write-Verbose "Overwriting $itemName at $itemPath..."
                        $uri = [String]::Format($catalogItemsUpdateUri, $itemId)
                        if ($Credential -ne $null)
                        {
                            Invoke-WebRequest -Uri $uri -Method Put -WebSession $WebSession -Body $payloadJson -ContentType "application/json" -Credential $Credential -Verbose:$false | Out-Null
                        }
                        else
                        {
                            Invoke-WebRequest -Uri $uri -Method Put -WebSession $WebSession -Body $payloadJson -ContentType "application/json" -UseDefaultCredentials -Verbose:$false | Out-Null
                        }
                        Write-Verbose "$EntirePath was uploaded to $RsFolder successfully!"
                    }
                    catch
                    {
                        throw (New-Object System.Exception("Failed to create catalog item: $($_.Exception.Message)", $_.Exception))
                    }
                    return
                }

                throw (New-Object System.Exception("Failed to create catalog item: $($_.Exception.Message)", $_.Exception))
            }
        }
    }
}
