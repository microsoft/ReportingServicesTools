# Copyright (c) 2021 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

. "$PSScriptRoot\..\..\Common\Get-RsTestSession.ps1"

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

        [object]
        $WebSession
    )

    $item = (Get-RsRestItem -WebSession $WebSession -RsItem "$($folderPath)/$($itemName)" ) | Where-Object { $_.Type -eq $itemType -and $_.Name -eq $itemName }
    $item | Should Not BeNullOrEmpty
}

Describe "Get-RsRestCacheRefreshPlan" {
    $restSessionFixture = @{}
    $rsFolderPath = ""
    $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'

    BeforeEach {
        $fixtureSession = Get-RsTestSession -Fixture $restSessionFixture -ReportPortalUri $reportPortalUri
        $folderName = 'SUT_WriteRsRestCatalogItem_' + [guid]::NewGuid()
        New-RsRestFolder -WebSession $fixtureSession -RsFolder / -FolderName $folderName -Verbose
        $rsFolderPath = '/' + $folderName
        $itemPath = $localPath + '\ReportCatalog.pbix'
        Write-RsRestCatalogItem -WebSession $fixtureSession -Path $itemPath -RsFolder $rsFolderPath -Verbose
        VerifyCatalogItemExists -itemName 'ReportCatalog' -itemType 'PowerBIReport' -folderPath $rsFolderPath -WebSession $fixtureSession

        $dataSources = Get-RsRestItemDataSource -RsItem "$($rsFolderPath)/ReportCatalog" -WebSession $fixtureSession
        $dataSources[0].DataModelDataSource.AuthType = 'UsernamePassword'
        $dataSources[0].DataModelDataSource.Username = 'PBIRS'
        $dataSources[0].DataModelDataSource.Secret = 'password'
        Set-RsRestItemDataSource -RsItem "$($rsFolderPath)/ReportCatalog" -WebSession $fixtureSession -DataSources $dataSources -RsItemType 'PowerBIReport'
        New-RsRestCacheRefreshPlan -RsItem "$($rsFolderPath)/ReportCatalog" -WebSession $fixtureSession -Description 'My New Refresh Plan' -Verbose

    }

    AfterEach {
        Remove-RsRestCatalogItem -WebSession $fixtureSession -RsItem $rsFolderPath -Confirm:$false
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
