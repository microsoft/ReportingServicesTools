# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsFolder
{
    <#
    .SYNOPSIS
        This script creates a new folder in the Report Server

    .DESCRIPTION
        This script creates a new folder in the Report Server

    .PARAMETER Path
        Specify the location where the folder should be created 

    .PARAMETER FolderName
        Specify the name of the the new folder

    .PARAMETER ReportServerUri
        Specify the Report Server URL to your SQL Server Reporting Services Instance.

    .PARAMETER Credential
        Specify the credentials to use when connecting to your SQL Server Reporting Services Instance.

    .PARAMETER Proxy
        Specify the Proxy to use when communicating with Reporting Services server. If Proxy is not specified, connection to Report Server will be created using ReportServerUri, ReportServerUsername and ReportServerPassword.

    .EXAMPLE 
        New-RsFolder -Path '/' -FolderName 'My new folder'
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new folder 'My new folder' at the root folder.

    .EXAMPLE 
        New-RsFolder -ReportServerUri 'http://remoteServer/reportserver' -Path '/existingfolder' -FolderName 'My new folder'	
        Description
        -----------
        This command will establish a connection to the Report Server located at http://remoteServer/reportserver using current user's credentials and create a new folder 'My new folder' at the folder existingfolder in the root.	

    #>

    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$True)]
        [Alias('ItemPath')]
        [string]
        $Path,

        [Parameter(Mandatory=$True)]
        [Alias('Name')]
        [string]
        $FolderName,

        [string]
        $ReportServerUri = 'http://localhost/reportserver',

        [System.Management.Automation.PSCredential]
        $ReportServerCredentials,

        $Proxy
    )

    if (-not $Proxy)
    {
        $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Credentials $ReportServerCredentials
    }

    try
    {
        Write-Verbose "Creating folder..."
        $Proxy.CreateFolder($FolderName, $Path, $null)
        Write-Information "Folder created successfully!"
    }
    catch
    {
       throw (New-Object System.Exception("Exception occurred while creating folder! $($_.Exception.Message)", $_.Exception))
    }
}
