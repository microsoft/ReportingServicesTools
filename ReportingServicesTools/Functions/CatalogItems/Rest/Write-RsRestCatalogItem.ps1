# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Write-RsRestCatalogItem
{
    <#
        .SYNOPSIS
            This command uploads an item from disk to a report server (using the REST Endpoint).

        .DESCRIPTION
            This command uploads an item from disk to a report server (using the REST Endpoint).

        .PARAMETER Path
            Path to item to upload on disk.

        .PARAMETER RsFolder
            Folder on reportserver to upload the item to.

        .PARAMETER Description
            Specify the description to be added to the report.

        .PARAMETER Overwrite
            Overwrite the old entry, if an existing catalog item with same name exists at the specified destination.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v1.0", "v2.0".
            NOTE:
                - v1.0 of REST Endpoint is not supported by Microsoft and is for SSRS 2016.
                - v2.0 of REST Endpoint is supported by Microsoft and is for SSRS 2017, PBIRS October 2017 and newer releases.

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .PARAMETER MaxFileSizeInMb
            Specify the maximum file size for the PBIX report.

        .PARAMETER MinLargeFileSizeInMb
            Specify the smallest possible size for a large PBIX report.

        .EXAMPLE
            Write-RsRestCatalogItem -Path 'c:\reports\monthlyreport.rdl' -RsFolder '/monthlyreports'

            Description
            -----------
            Uploads the report 'monthlyreport.rdl' to folder '/monthlyreports' using v2.0 REST Endpoint to Report Server located at http://localhost/reports/.

        .EXAMPLE
            Write-RsRestCatalogItem -Path 'c:\reports\monthlyreport.rdl' -RsFolder '/monthlyreports' -RestApiVersion 'v1.0'

            Description
            -----------
            Uploads the report 'monthlyreport.rdl' to folder '/monthlyreports' to v1.0 REST Endpoint to Report Server located at http://localhost/reports/.

        .EXAMPLE
            Write-RsRestCatalogItem -WebSession $mySession -Path 'c:\reports\monthlyreport.rdl' -RsFolder '/monthlyreports'

            Description
            -----------
            Uploads the report 'monthlyreport.rdl' to folder '/monthlyreports' to v2.0 REST Endpoint to Report Server located at the specified WebSession object.

        .EXAMPLE
            Write-RsRestCatalogItem -ReportPortalUri 'http://myserver/reports' -Path 'c:\reports\monthlyreport.rdl' -RsFolder '/monthlyreports'

            Description
            -----------
            Uploads the report 'monthlyreport.rdl' to folder '/monthlyreports' using v2.0 REST Endpoint to Report Server located at http://myserver/reports.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,

        [Alias('DestinationFolder')]
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,

        [string]
        $Description,

        [Alias('Override')]
        [switch]
        $Overwrite,

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
        $WebSession,

        [float]
        $MaxFileSizeInMb = 2000,

        [float]
        $MinLargeFileSizeInMb = 25
    )
    Begin
    {
        $WebSession = New-RsRestSessionHelper -BoundParameters $PSBoundParameters
        $ReportPortalUri = Get-RsPortalUriHelper -WebSession $WebSession
        $catalogItemsUri = $ReportPortalUri + "api/$RestApiVersion/CatalogItems"
        if ($RestApiVersion -eq "v1.0")
        {
            $catalogItemsByPathApi = $ReportPortalUri + "api/$RestApiVersion/CatalogItemByPath(path=@path)?@path=%27{0}%27"
        }
        else
        {
            $catalogItemsByPathApi = $ReportPortalUri + "api/$RestApiVersion/CatalogItems(Path='{0}')"
            $powerBIReportsByPathApi = $ReportPortalUri + "api/$RestApiVersion/PowerBIReports(Path='{0}')/Model.Upload"
        }
        $catalogItemsUpdateUri = $ReportPortalUri + "api/$RestApiVersion/CatalogItems({0})"
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

            if ($itemType -eq "Resource" -or $itemType -eq "ExcelWorkbook")
            {
                # preserve the extension for resources and excel workbooks
                $itemName = $item.Name
            }
            else
            {
                $itemName = $item.BaseName
            }

            $itemPath = ""
            if ($RsFolder -eq "/")
            {
                $itemPath = "/$itemName"
            }
            else
            {
                $itemPath = "$RsFolder/$itemName"
            }

            Write-Verbose "Reading file $item content..."
            if ($itemType -eq 'DataSource')
            {
                [xml] $dataSourceXml = Get-Content -Path $EntirePath
                if ($item.Extension -eq '.rsds')
                {
                    if ($dataSourceXml -eq $null -or
                        $dataSourceXml.DataSourceDefinition -eq $null -or
                        $dataSourceXml.DataSourceDefinition.Extension -eq $null -or
                        $dataSourceXml.DataSourceDefinition.ConnectString -eq $null)
                    {
                        throw 'Invalid data source file!'
                    }

                    $connectionString = $dataSourceXml.DataSourceDefinition.ConnectString
                    $dataSourceType = $dataSourceXml.DataSourceDefinition.Extension
                    $credentialRetrieval = "none"
                    $enabled = "true" -like $content.DataSourceDefinition.Enabled
                }
                elseif ($item.Extension -eq '.rds')
                {
                    if ($dataSourceXml -eq $null -or
                        $dataSourceXml.RptDataSource -eq $null -or
                        $dataSourceXml.RptDataSource.Name -eq $null -or
                        $dataSourceXml.RptDataSource.ConnectionProperties -eq $null -or
                        $dataSourceXml.RptDataSource.ConnectionProperties.ConnectString -eq $null -or
                        $dataSourceXml.RptDataSource.ConnectionProperties.Extension -eq $null)
                    {
                        throw 'Invalid data source file!'
                    }

                    $itemName = $dataSourceXml.RptDataSource.Name
                    $itemPath = $itemPath.Substring(0, $itemPath.LastIndexOf('/') + 1) + $itemName
                    $enabled = $true
                    $connectionProperties = $dataSourceXml.RptDataSource.ConnectionProperties
                    $connectionString = $connectionProperties.ConnectString
                    $dataSourceType = $connectionProperties.Extension
                    $credentialRetrieval = "none"
                    if ($connectionProperties.Prompt -ne $null)
                    {
                        $credentialRetrieval = "prompt"
                        $prompt = $connectionProperties.Prompt
                    }
                    elseif ($connectionProperties.IntegratedSecurity -eq $true)
                    {
                        $credentialRetrieval = "integrated"
                    }
                }

                $payload = @{
                    "@odata.type" = "#Model.$itemType";
                    "Path" = $itemPath;
                    "Name" = $itemName;
                    "Description" = "";
                    "DataSourceType" = $dataSourceType;
                    "ConnectionString" = $connectionString;
                    "CredentialRetrieval" = $credentialRetrieval;
                    "CredentialsByUser" = $null;
                    "CredentialsInServer" = $null;
                    "Hidden" = $false;
                    "IsConnectionStringOverridden" = $true;
                    "IsEnabled" = $enabled;
                }

                if ($credentialRetrieval -eq "Prompt")
                {
                    $payload["CredentialsByUser"] = @{
                        "DisplayText" = $prompt;
                        "UseAsWindowsCredentials" = $true;
                    }
                }
            }
            elseif ($itemType -eq "Kpi")
            {
                $content = [System.IO.File]::ReadAllText($EntirePath)
                $payload = ConvertFrom-Json $content
                $payload.Path = $itemPath
            }
            else
            {
                $fileBytes = [System.IO.File]::ReadAllBytes($EntirePath)
                $fileSizeInMb = (Get-Item $EntirePath).length/1MB

                if ($itemType -eq "PowerBIReport" -and $fileSizeInMb -ge $MinLargeFileSizeInMb)
                {
                    $maxServerFileSizeInMb = Get-RsRestPublicServerSetting -Property "MaxFileSizeMb" -ReportPortalUri $ReportPortalUri -WebSession $WebSession
                    if ($fileSizeInMb -gt $MaxFileSizeInMb)
                    {
                        throw "This file is too large to be uploaded. Files larger than $MaxFileSizeInMb MB are not currently supported: $item!"
                    }
                    elseif ($maxServerFileSizeInMb -gt 0 -and $fileSizeInMb -gt $maxServerFileSizeInMb) {
                        throw "This file is too large to be uploaded. Files larger than $maxServerFileSizeInMb MB are not currently supported: $item!"
                    }

                    Write-Verbose "PowerBIReport $item is a large"

                    $isLargePowerBIReport = $true
                    $pbixPayload = [System.Text.Encoding]::GetEncoding('ISO-8859-1').GetString($fileBytes)
                    $boundary = [System.Guid]::NewGuid().ToString()
                    $LF = "`r`n"

                    $bodyLines = (
                        # Name
                        "--$boundary",
                        "Content-Disposition: form-data; name=`"Name`"$LF",
                        $itemName,
                        # ContentType
                        "--$boundary",
                        "Content-Disposition: form-data; name=`"ContentType`"$LF",
                        "",
                        # Content
                        "--$boundary",
                        "Content-Disposition: form-data; name=`"Content`"$LF",
                        "undefined",
                        # Path
                        "--$boundary",
                        "Content-Disposition: form-data; name=`"Path`"$LF",
                        $itemPath,
                        # @odata.type
                        "--$boundary",
                        "Content-Disposition: form-data; name=`"@odata.type`"$LF",
                        "#Model.PowerBIReport",
                        # File
                        "--$boundary",
                        "Content-Disposition: form-data; name=`"File`"; filename=`"$itemName`"",
                        "Content-Type: application/octet-stream$LF",
                        $pbixPayload,
                        "--$boundary--"
                    ) -join $LF
                }
                else {
                    Write-Verbose "$item is a small"

                    $isLargePowerBIReport = $false
                    $payload = @{
                        "@odata.type" = "#Model.$itemType";
                        "Content" = [System.Convert]::ToBase64String($fileBytes);
                        "ContentType"="";
                        "Name" = $itemName;
                        "Description" = $Description
                        "Path" = $itemPath;
                    }
                }
            }

            try
            {
                if ($itemType -eq "PowerBIReport" -and $isLargePowerBIReport -eq $true)
                {
                    Write-Verbose "Uploading $EntirePath to $RsFolder via endpoint for large files..."
                    $endpointUrl = [String]::Format($powerBIReportsByPathApi, $itemPath)
                    $contentType = "multipart/form-data; boundary=$boundary"
                    $requestBody = $bodyLines
                }
                else
                {
                    Write-Verbose "Uploading $EntirePath to $RsFolder..."
                    $endpointUrl = $catalogItemsUri
                    $contentType = "application/json"
                    $payloadJson = ConvertTo-Json $payload
                    $requestBody = ([System.Text.Encoding]::UTF8.GetBytes($payloadJson))
                }

                if ($Credential -ne $null)
                {
                    Invoke-WebRequest -Uri $endpointUrl -Method Post -WebSession $WebSession -Body $requestBody -ContentType $contentType -Credential $Credential -Verbose:$false | Out-Null
                }
                else
                {
                    Invoke-WebRequest -Uri $endpointUrl -Method Post -WebSession $WebSession -Body $requestBody -ContentType $contentType -UseDefaultCredentials -Verbose:$false | Out-Null
                }

                Write-Verbose "$EntirePath was uploaded to $RsFolder successfully!"
            }
            catch
            {
                if ($isLargePowerBIReport -ne $true -and $_.Exception.Response -ne $null -and $_.Exception.Response.StatusCode -eq 409 -and $Overwrite)
                {
                    try
                    {
                        Write-Verbose "$itemName already exists at $RsFolder. Retrieving id in order to overwrite it..."
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
                            Invoke-WebRequest -Uri $uri -Method Put -WebSession $WebSession -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -Credential $Credential -Verbose:$false | Out-Null
                        }
                        else
                        {
                            Invoke-WebRequest -Uri $uri -Method Put -WebSession $WebSession -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -UseDefaultCredentials -Verbose:$false | Out-Null
                        }
                        Write-Verbose "$EntirePath was uploaded to $RsFolder successfully!"
                    }
                    catch
                    {
                        Write-Error (New-Object System.Exception("Failed to create catalog item: $($_.Exception.Message)", $_.Exception))
                    }
                }
                else
                {
                    Write-Error (New-Object System.Exception("Failed to create catalog item: $($_.Exception.Message)", $_.Exception))
                }
            }
        }
    }
}
