# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = 'http://pashah-1013/reports'
$reportServerUri = 'http://pashah-1013/reportserver'

function VerifyCatalogItemDoesNotExists()
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

    $item = (Get-RsFolderContent -ReportServerUri $reportServerUri -RsFolder $folderPath) | Where-Object { $_.TypeName -eq $itemType -and $_.Name -eq $itemName }
    $item | Should BeNullOrEmpty
}

Describe "Remove-RsRestCatalogItem" {
    Context "ReportPortalUri parameter" {
        # Upload the catalog items that are going to be downloaded
        $folderName = 'SUT_RemoveRsCatalogItem_' + [guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localResourcesPath -RsFolder $folderPath

        It "Should delete a RDL item" {
            Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem "$folderPath/emptyReport"
            VerifyCatalogItemDoesNotExists -itemType "Report" -itemName "emptyReport" -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should delete a RSDS item" {
            Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem "$folderPath/SutWriteRsFolderContent_DataSource"
            VerifyCatalogItemDoesNotExists -itemType "DataSource" -itemName "SutWriteRsFolderContent_DataSource" -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should delete a RSD item" {
            Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem "$folderPath/UnDataset"
            VerifyCatalogItemDoesNotExists -itemType 'DataSet' -itemName 'UnDataset' -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should delete a RSMOBILE item" {
            Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem "$folderPath/SimpleMobileReport"
            VerifyCatalogItemDoesNotExists -itemType 'MobileReport' -itemName 'SimpleMobileReport' -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should delete a PBIX item" {
            Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem "$folderPath/SimplePowerBIReport"
            VerifyCatalogItemDoesNotExists -itemType 'PowerBIReport' -itemName 'SimplePowerBIReport' -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should delete a folder" {
            Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $folderPath
            VerifyCatalogItemDoesNotExists -itemType 'Folder' -itemName $folderName -folderPath "/" -reportServerUri $reportServerUri
        }
    }

    Context "WebSession parameter" {
        # Upload the catalog items that are going to be downloaded
        $folderName = 'SUT_RemoveRsCatalogItem_' + [guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localResourcesPath -RsFolder $folderPath

        $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri

        It "Should delete a RDL item" {
            Remove-RsRestCatalogItem -WebSession $webSession -RsItem "$folderPath/emptyReport"
            VerifyCatalogItemDoesNotExists -itemType "Report" -itemName "emptyReport" -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should delete a RSDS item" {
            Remove-RsRestCatalogItem -WebSession $webSession -RsItem "$folderPath/SutWriteRsFolderContent_DataSource"
            VerifyCatalogItemDoesNotExists -itemType "DataSource" -itemName "SutWriteRsFolderContent_DataSource" -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should delete a RSD item" {
            Remove-RsRestCatalogItem -WebSession $webSession -RsItem "$folderPath/UnDataset"
            VerifyCatalogItemDoesNotExists -itemType 'DataSet' -itemName 'UnDataset' -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should delete a RSMOBILE item" {
            Remove-RsRestCatalogItem -WebSession $webSession -RsItem "$folderPath/SimpleMobileReport"
            VerifyCatalogItemDoesNotExists -itemType 'MobileReport' -itemName 'SimpleMobileReport' -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should delete a PBIX item" {
            Remove-RsRestCatalogItem -WebSession $webSession -RsItem "$folderPath/SimplePowerBIReport"
            VerifyCatalogItemDoesNotExists -itemType 'PowerBIReport' -itemName 'SimplePowerBIReport' -folderPath $folderPath -reportServerUri $reportServerUri
        }

        It "Should delete a folder" {
            Remove-RsRestCatalogItem -WebSession $webSession -RsItem $folderPath
            VerifyCatalogItemDoesNotExists -itemType 'Folder' -itemName $folderName -folderPath "/" -reportServerUri $reportServerUri
        }
    }
}