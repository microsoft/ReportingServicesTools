# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<#
.SYNOPSIS
    List all item references associated with a report or a dataset.

.DESCRIPTION
    List all item references associated with a report or a dataset.
    For a paginated report, it lists all references to shared datasets and shared data sources.
    For a dataset, it lists all references to shared data sources.

.PARAMETER ReportServerUri
    Specify the Report Server URL to your SQL Server Reporting Services Instance.
    Has to be provided if proxy is not provided.

.PARAMETER ReportServerCredentials
    Specify the credentials to use when connecting to your SQL Server Reporting Services Instance.

.PARAMETER Proxy
    Report server proxy to use. 
    Has to be provided if ReportServerUri is not provided.

.PARAMETER ItemPath
    Path to item.

.EXAMPLE
    Get-RsItemReferences -ReportServerUri 'http://localhost/reportserver_sql2012' -Path /Report1
   
    Description
    -----------
    List all item references associated with report /Report1
#>


function Get-RsItemReferences
{
    param(
        [string]
        $ReportServerUri = 'http://localhost/reportserver',
                
        [System.Management.Automation.PSCredential]
        $ReportServerCredentials,
        $Proxy,
        
        [Parameter(Mandatory=$True)]
        [string]
        $ItemPath
    )

    if(-not $Proxy)
    {
        $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Credentials $ReportServerCredentials 
    }

    $itemType = $Proxy.GetItemType($ItemPath)
    if($itemType -eq "Report")
    {
        return ($Proxy.GetItemReferences($ItemPath, "DataSet") + $Proxy.GetItemReferences($ItemPath, "DataSource"))        
    }
    elseif ($itemType -eq "DataSet") 
    {
        return $Proxy.GetItemReferences($ItemPath, "DataSource")        
    }
    elseif ($itemType -eq "Unknown") 
    {
        throw "Cannot find item with path $ItemPath"
    }
    else
    {
        throw "ItemType '$itemType' is not supported by this method."
    }
}