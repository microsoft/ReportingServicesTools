# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsRestFolder
{
    <#
        .SYNOPSIS
            This script creates a new folder in the Report Server

        .DESCRIPTION
            This script creates a new folder in the Report Server

        .PARAMETER RsFolder
            Specify the location where the folder should be created

        .PARAMETER FolderName
            Specify the name of the the new folder

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            New-RsRestFolder -RsFolder MyNewFolder -RsFolder /

            Description
            -----------
            Creates a new folder called "MyNewFolder" under "/" parent folder.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,

        [Parameter(Mandatory = $True)]
        [Alias('Name')]
        [string]
        $FolderName,

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
        $foldersUri = $ReportPortalUri + "api/$RestApiVersion/Folders"
    }
    Process
    {
        try
        {
            if ($RsFolder -eq '/')
            {
                $TargetFolderPath = "/$FolderName"
            }
            else
            {
                $TargetFolderPath = "$RsFolder/$FolderName"
            }
            Write-Verbose "Creating folder $TargetFolderPath..."

            $payload = @{
                "@odata.type" = "#Model.Folder";
                "Path" = $RsFolder;
                "Name" = $FolderName;
            }
            $payloadJson = ConvertTo-Json $payload

            if ($Credential -ne $null)
            {
                $response = Invoke-WebRequest -Uri $foldersUri -Method Post -WebSession $WebSession -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -Credential $Credential -Verbose:$false
            }
            else
            {
                $response = Invoke-WebRequest -Uri $foldersUri -Method Post -WebSession $WebSession -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -UseDefaultCredentials -Verbose:$false
            }

            Write-Verbose "Folder $TargetFolderPath was created successfully!"
            return ConvertFrom-Json $response.Content
        }
        catch
        {
            throw (New-Object System.Exception("Failed to create folder '$FolderName' in '$RsFolder': $($_.Exception.Message)", $_.Exception))
        }
    }
}