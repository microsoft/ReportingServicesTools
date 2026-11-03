# Copyright (c) 2021 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

. "$PSScriptRoot\..\..\Common\Get-RsTestSession.ps1"

$reportPortalUri = if ($env:PesterPortalUrl -eq $null) { 'http://localhost/reports' } else { $env:PesterPortalUrl }
$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }
. "$PSScriptRoot\..\..\Common\Wait-RsTestRefreshHistory.ps1"

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

Describe "Get-RsRestCacheRefreshPlanHistory" {
    $restSessionFixture = @{}
    $rsFolderPath = ""
    $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'

    BeforeEach {
        $fixtureSession = Get-RsTestSession -Fixture $restSessionFixture -ReportPortalUri $reportPortalUri
        $folderName = 'SUT_GetRsRestCacheRefreshPlanHistory_' + [guid]::NewGuid()
        New-RsRestFolder -WebSession $fixtureSession -RsFolder / -FolderName $folderName -Verbose
        $rsFolderPath = '/' + $folderName
        $itemPath = $localPath + '\ReportCatalog.pbix'
        Write-RsRestCatalogItem -WebSession $fixtureSession -Path $itemPath -RsFolder $rsFolderPath -Verbose
        VerifyCatalogItemExists -itemName 'ReportCatalog' -itemType 'PowerBIReport' -folderPath $rsFolderPath -WebSession $fixtureSession

        $dataSources = Get-RsRestItemDataSource -RsItem "$($rsFolderPath)/ReportCatalog" -WebSession $fixtureSession
        $dataSources[0].DataModelDataSource.AuthType = 'UsernamePassword'
        $dataSources[0].DataModelDataSource.Username = 'sa'
        $dataSources[0].DataModelDataSource.Secret = 'i<3ReportingServices'
        Set-RsRestItemDataSource -RsItem "$($rsFolderPath)/ReportCatalog" -WebSession $fixtureSession -DataSources $dataSources -RsItemType 'PowerBIReport'
        New-RsRestCacheRefreshPlan -RsItem "$($rsFolderPath)/ReportCatalog" -WebSession $fixtureSession -Description 'My New Refresh Plan' -Verbose

    }

    AfterEach {
        Remove-RsRestCatalogItem -WebSession $fixtureSession -RsItem $rsFolderPath -Confirm:$false
    }

    Context "ReportPortalUri parameter" {
        
        It "Should retrieve history of all CacheRefreshPlan plan for a PBIX report" {
            Start-RsRestCacheRefreshPlan -ReportPortalUri $reportPortalUri -RsReport "$($rsFolderPath)/ReportCatalog"

            $plan = Get-RsCacheRefreshPlan -ReportPortalUri $reportPortalUri -RsReport "$($rsFolderPath)/ReportCatalog"
            $plan | Should Not BeNullOrEmpty
            $plan.LastStatus | Should Not Be 'New Scheduled Refresh Plan'

            $someHistory = @(Wait-RsTestRefreshHistory -ExpectedCount 1 -GetHistory {
                Get-RsRestCacheRefreshPlanHistory -ReportPortalUri $reportPortalUri -RsReport "$($rsFolderPath)/ReportCatalog"
            })
            @($someHistory).count | Should be 1
            
            Start-RsRestCacheRefreshPlan -ReportPortalUri $reportPortalUri -RsReport "$($rsFolderPath)/ReportCatalog"
            $moreHistory = @(Wait-RsTestRefreshHistory -ExpectedCount 2 -GetHistory {
                Get-RsRestCacheRefreshPlanHistory -ReportPortalUri $reportPortalUri -RsReport "$($rsFolderPath)/ReportCatalog"
            })
            @($moreHistory).count | Should be 2
        }
    }
}
