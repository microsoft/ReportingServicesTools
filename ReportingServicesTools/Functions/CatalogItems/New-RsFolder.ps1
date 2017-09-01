# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsFolder
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

        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
            
        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.

        .EXAMPLE 
            New-RsFolder -RsFolder '/' -FolderName 'My new folder'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new folder 'My new folder' at the root of the SSRS instance.

        .EXAMPLE 
            New-RsFolder -ReportServerUri 'http://remoteServer/reportserver' -RsFolder '/existingfolder' -FolderName 'My new sub-folder'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://remoteServer/reportserver using current user's credentials and create a new folder 'My new sub-folder' at the folder existingfolder in the root.

    #>
    
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $True)]
        [Alias('ItemPath','Path')]
        [string]
        $RsFolder,
        
        [Parameter(Mandatory = $True)]
        [Alias('Name')]
        [string]
        $FolderName,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    
    try
    {
        Write-Verbose "Creating folder $($FolderName)..."
        $Proxy.CreateFolder($FolderName, $RsFolder, $null) | Out-Null
        Write-Verbose "Folder $($FolderName) created successfully!"
    }
    catch
    {
        throw (New-Object System.Exception("Exception occurred while creating folder! $($_.Exception.Message)", $_.Exception))
    }
}