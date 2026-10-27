# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-RsRestPolicyUri
{
    <#
        .SYNOPSIS
            Returns the REST policy endpoint for a catalog item.

        .DESCRIPTION
            Uses the typed entity set (for example Reports or Folders) because some report server
            versions return 404 for CatalogItems({Id})/Policies. Unknown types fall back to CatalogItems.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ReportPortalUri,

        [Parameter(Mandatory = $true)]
        [string]
        $RestApiVersion,

        [Parameter(Mandatory = $true)]
        $Item
    )

    $entitySet = switch ([string]$Item.Type)
    {
        'Folder' { 'Folders' }
        'Report' { 'Reports' }
        'PowerBIReport' { 'PowerBIReports' }
        'LinkedReport' { 'LinkedReports' }
        'DataSource' { 'DataSources' }
        'DataSet' { 'DataSets' }
        'Kpi' { 'Kpis' }
        'Resource' { 'Resources' }
        'ExcelWorkbook' { 'ExcelWorkbooks' }
        'Component' { 'Components' }
        default { 'CatalogItems' }
    }

    return $ReportPortalUri + "api/$RestApiVersion/$entitySet($($Item.Id))/Policies"
}
