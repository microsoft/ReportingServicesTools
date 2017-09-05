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
            Specify the credentials to use when connecting to the Report Server.
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
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }
    
    Process
    {
        #region Process each path
        foreach ($Item in $Path)
        {
            $itemType = $Proxy.GetItemType($Item)
            
            switch ($itemType)
            {
                "Report"
                {
                    return ($Proxy.GetItemReferences($Item, "DataSet") + $Proxy.GetItemReferences($Item, "DataSource")) | Add-Member -Name "ItemType" -Value $itemType -MemberType NoteProperty -PassThru
                }
                "DataSet"
                {
                    return $Proxy.GetItemReferences($Item, "DataSource") | Add-Member -Name "ItemType" -Value $itemType -MemberType NoteProperty -PassThru
                }
                "Unknown"
                {
                    throw "Cannot find item with path $Item"
                }
                default
                {
                    throw "ItemType '$itemType' is not supported by this method."
                }
            }
        }
        #endregion Process each path
    }
}
New-Alias -Name "Get-RsItemReferences" -Value Get-RsItemReference -Scope Global
