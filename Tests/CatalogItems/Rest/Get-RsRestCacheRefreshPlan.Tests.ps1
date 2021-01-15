# Copyright (c) 2021 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = if ($env:PesterPortalUrl -eq $null) { 'http://localhost/reports' } else { $env:PesterPortalUrl }
$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

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

Describe "Get-RsRestCacheRefreshPlan" {
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
        New-RsRestCacheRefreshPlan -RsItem "$($rsFolderPath)/ReportCatalog" -ReportPortalUri $reportPortalUri -Description 'My New Refresh Plan' -Verbose

    }

    AfterEach {
        Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $rsFolderPath -Confirm:$false
    }

    Context "ReportPortalUri parameter" {
        
        It "Should retrieve a CacheRefreshPlan for a PBIX report" {
            
            $plan = Get-RsRestCacheRefreshPlan -ReportPortalUri $reportPortalUri -RsReport "$($rsFolderPath)/ReportCatalog"
            $plan | Should Not BeNullOrEmpty
            $plan.LastStatus | Should -Be 'New Scheduled Refresh Plan'
        }
        
        It "Should retrieve two CacheRefreshPlans for a PBIX report" {
            New-RsRestCacheRefreshPlan -RsItem "$($rsFolderPath)/ReportCatalog" -ReportPortalUri $reportPortalUri -Description 'My Other Refresh Plan' -Verbose
            
            $plans = Get-RsRestCacheRefreshPlan -ReportPortalUri $reportPortalUri -RsReport "$($rsFolderPath)/ReportCatalog"
            $plans | Should Not BeNullOrEmpty
            $plans.LastStatus | Should -Be @('New Scheduled Refresh Plan', 'New Scheduled Refresh Plan')
            $plans | ft -AutoSize
        }
    }
}
