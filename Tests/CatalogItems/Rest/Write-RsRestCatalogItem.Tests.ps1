# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = 'http://localhost/reports'
$reportServerUri = 'http://localhost/reportserver'

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
        $reportServerUri
    )

    $item = (Get-RsFolderContent -ReportServerUri $reportServerUri -RsFolder $folderPath) | Where-Object TypeName -eq $itemType
    $item.Name | Should Be $itemName
}

Describe "Write-RsRestCatalogItem" {
    Context "ReportPortalUri parameter" {
        $folderName = 'SutWriteRsRestCatalogItem_ReportPortalUri' + [guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -Path / -FolderName $folderName -Verbose
        $folderPath = '/' + $folderName
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'

        It "Should upload a local RDL file" {
            $itemPath = Join-Path -Path $localPath -ChildPath emptyReport.rdl
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $folderPath
            VerifyCatalogItemExists -itemName 'emptyReport' -itemType 'Report' -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local RSDS file" {
            $itemPath = $localPath + '\SutWriteRsFolderContent_DataSource.rsds'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $folderPath
            VerifyCatalogItemExists -itemName 'SutWriteRsFolderContent_DataSource' -itemType 'DataSource' -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local RSD file" {
            $itemPath = $localPath + '\UnDataset.rsd'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $folderPath
            VerifyCatalogItemExists -itemName 'UnDataset' -itemType 'DataSet' -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local RSMOBILE file" {
            $itemPath = $localPath + '\SimpleMobileReport.rsmobile'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $folderPath
            VerifyCatalogItemExists -itemName 'SimpleMobileReport' -itemType 'MobileReport' -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local PBIX file" {
            $itemPath = $localPath + '\SimplePowerBIReport.pbix'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $folderPath
            VerifyCatalogItemExists -itemName 'SimplePowerBIReport' -itemType 'PowerBIReport' -folderPath $folderPath -reportServerUri $reportServerUri
        }
    }

    Context "WebSession parameter" {
        $folderName = 'SutWriteRsRestCatalogItem_WebSession' + [guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -Path / -FolderName $folderName -Verbose
        $folderPath = '/' + $folderName
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri

        It "Should upload a local RDL file" {
            $itemPath = Join-Path -Path $localPath -ChildPath emptyReport.rdl
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $folderPath
            VerifyCatalogItemExists -itemName 'emptyReport' -itemType 'Report' -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local RSDS file" {
            $itemPath = $localPath + '\SutWriteRsFolderContent_DataSource.rsds'
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $folderPath
            VerifyCatalogItemExists -itemName 'SutWriteRsFolderContent_DataSource' -itemType 'DataSource' -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local RSD file" {
            $itemPath = $localPath + '\UnDataset.rsd'
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $folderPath
            VerifyCatalogItemExists -itemName 'UnDataset' -itemType 'DataSet' -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local RSMOBILE file" {
            $itemPath = $localPath + '\SimpleMobileReport.rsmobile'
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $folderPath
            VerifyCatalogItemExists -itemName 'SimpleMobileReport' -itemType 'MobileReport' -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local PBIX file" {
            $itemPath = $localPath + '\SimplePowerBIReport.pbix'
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $folderPath
            VerifyCatalogItemExists -itemName 'SimplePowerBIReport' -itemType 'PowerBIReport' -folderPath $folderPath -reportServerUri $reportServerUri
        }
    }
}