# Copyright (c) 2021 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = 'https://minint-elcedtu/Reports/'
$reportServerUri = 'https://minint-elcedtu/Reports/'

function VerifyCatalogItemExists()
{
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $itemName,

        [Parameter(Mandatory = $True)]
        [string]
        $itemType,

        [Parameter(Mandatory = $True)]
        [string]
        $folderPath,

        [string]
        $reportPortalUri
    )

    $item = (Get-RsRestItem -reportPortalUri $reportPortalUri -RsItem "$($folderPath)/$($itemName)" ) | Where-Object { $_.Type -eq $itemType -and $_.Name -eq $itemName }
    $item | Should Not BeNullOrEmpty
}

Describe "New-RsRestCacheRefreshPlan" {
    $rsFolderPath = ""
    $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'

    BeforeEach {
        $folderName = 'SUT_WriteRsRestCatalogItem_' + [guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -RsFolder / -FolderName $folderName -Verbose
        $rsFolderPath = '/' + $folderName
        $itemPath = $localPath + '\ReportCatalog.pbix'
        Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -Verbose
        VerifyCatalogItemExists -itemName 'ReportCatalog' -itemType 'PowerBIReport' -folderPath $rsFolderPath -reportPortalUri $reportPortalUri

        $dataSources = Get-RsRestItemDataSource -RsItem "$($rsFolderPath)/ReportCatalog" -ReportPortalUri $reportPortalUri
        $dataSources[0].DataModelDataSource.AuthType = 'UsernamePassword'
        $dataSources[0].DataModelDataSource.Username = 'PBIRS'
        $dataSources[0].DataModelDataSource.Secret = 'password'
        Set-RsRestItemDataSource -RsItem "$($rsFolderPath)/ReportCatalog" -ReportPortalUri $reportPortalUri -DataSources $dataSources -RsItemType 'PowerBIReport'

    }

    AfterEach {
        Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $rsFolderPath -Confirm:$false
    }

    Context "ReportPortalUri parameter" {
        
        It "Should add a CacheRefreshPlan plan for a PBIX report" {
            New-RsRestCacheRefreshPlan -RsItem "$($rsFolderPath)/ReportCatalog" -ReportPortalUri $reportPortalUri -Description 'My New Refresh Plan' -Verbose
            
            $plan = Get-RsCacheRefreshPlan -ReportPortalUri $reportPortalUri -RsReport "$($rsFolderPath)/ReportCatalog"
            $plan | Should Not BeNullOrEmpty
        }
    }
}
