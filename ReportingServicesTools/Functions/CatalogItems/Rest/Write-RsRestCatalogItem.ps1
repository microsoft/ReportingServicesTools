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
        
        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.
        
        .PARAMETER Credential
            Specify the password to use when connecting to your SQL Server Reporting Services Instance.
        
        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.
        
        .EXAMPLE
            Write-RsRestCatalogItem -WebSession $mySession -Path c:\reports\monthlyreport.rdl -RsFolder /monthlyreports
            
            Description
            -----------
            Uploads the report monthlyreport.rdl to folder /monthlyreports

        .EXAMPLE
            Write-RsRestCatalogItem -ReportPortalUri 'http://localhost/reports_sql2016' -Path c:\reports\monthlyreport.rdl -RsFolder /monthlyreports
            
            Description
            -----------
            Uploads the report monthlyreport.rdl to folder /monthlyreports
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
    }
    
    Process
    {
        $catalogItemsUri = $ReportPortalUri + "api/v1.0/CatalogItems"

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

            if ($itemType -eq "DataSource") {
                throw "DataSource creation is currently not supported!"
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
                $payloadJson = ConvertTo-Json $payload

                if ($Credential -ne $null)
                {
                    Invoke-WebRequest -Uri $catalogItemsUri -Method Post -WebSession $WebSession -Body $payloadJson -ContentType "application/json" -Credential $Credential | Out-Null
                }
                else
                {
                    Invoke-WebRequest -Uri $catalogItemsUri -Method Post -WebSession $WebSession -Body $payloadJson -ContentType "application/json" -UseDefaultCredentials | Out-Null
                }

                Write-Verbose "$EntirePath was uploaded to $RsFolder successfully!"
            }
            catch
            {
                throw (New-Object System.Exception("Failed to create catalog item: $($_.Exception.Message)", $_.Exception))
            }
        }
    }
}
