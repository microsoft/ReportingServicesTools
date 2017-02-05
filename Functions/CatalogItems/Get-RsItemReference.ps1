# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Get-RsItemReference
{
    <#
        .SYNOPSIS
            List all item references associated with a report or a dataset.
        
        .DESCRIPTION
            List all item references associated with a report or a dataset.
            For a paginated report, it lists all references to shared datasets and shared data sources.
            For a dataset, it lists all references to shared data sources.
        
        .PARAMETER Path
            Path to Item.
        
        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Credential
            Specify the password to use when connecting to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.
        
        .EXAMPLE
            Get-RsItemReference -Path /Report1
            
            Description
            -----------
            List all item references associated with report /Report1
        
        .NOTES
            Author:      ???
            Editors:     Friedrich Weinmann
            Created on:  ???
            Last Change: 03.02.2017
            Version:     1.0
            
            Release 1.1 (03.02.2017, Friedrich Weinmann)
            - Fixed Parameter help (Don't poison the name with "(optional)", breaks Get-Help)
            - Standardized the parameters governing the Report Server connection for consistent user experience.
            - Changed type of parameter 'Path' to System.String[], to better facilitate pipeline & nonpipeline use
            - Added alias 'ItemPath' for parameter 'Path', for consistency's sake
            - Redesigned to accept pipeline input from 'Path'
            - Renamed function from "Get-RsItemReferences" to "Get-RsItemReference", in order to conform to naming standards. Introduced an alias with the old name for backwards compatibility.
    
            Release 1.0 (???, ???)
            - Initial Release
    #>
    param (
        [Alias('ItemPath')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    Begin
    {
        #region Connect to Report Server using Web Proxy
        if (-not $Proxy)
        {
            try
            {
                $splat = @{ }
                if ($PSBoundParameters.ContainsKey('ReportServerUri')) { $splat['ReportServerUri'] = $ReportServerUri }
                if ($PSBoundParameters.ContainsKey('Credential')) { $splat['Credential'] = $Credential }
                $Proxy = New-RSWebServiceProxy @splat
            }
            catch
            {
                throw
            }
        }
        #endregion Connect to Report Server using Web Proxy
    }
    
    Process
    {
        #region Process each path
        foreach ($Item in $Path)
        {
            $itemType = $Proxy.GetItemType($Item)
            
            switch ($itemType)
            {
                "Report" { return ($Proxy.GetItemReferences($Item, "DataSet") + $Proxy.GetItemReferences($Item, "DataSource")) | Add-Member -Name "Path" -Value $itemType -PassThru }
                "DataSet" { return $Proxy.GetItemReferences($Item, "DataSource") | Add-Member -Name "Path" -Value $itemType -PassThru }
                "Unknown" { throw "Cannot find item with path $Item" }
                default { throw "ItemType '$itemType' is not supported by this method." }
            }
        }
        #endregion Process each path
    }
}
New-Alias -Name "Get-RsItemReferences" -Value Get-RsItemReference -Scope Global