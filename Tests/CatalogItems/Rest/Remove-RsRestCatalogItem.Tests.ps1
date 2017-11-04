# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = 'http://localhost/reports'
$reportServerUri = 'http://localhost/reportserver'

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
    $rsFolderPath = ""
    $rsFolderPaths = @()

    BeforeEach {
        # creating a new folder
        $folderName = 'SUT_RemoveRsCatalogItem_' + [guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -Path / -FolderName $folderName
        $rsFolderPath = '/' + $folderName
        $rsFolderPaths.Add($rsFolderPath)

        # uploading resources to the folder
        $localResourcesPath = (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localResourcesPath -RsFolder $rsFolderPath
    }

    AfterAll {
        foreach ($path in $rsFolderPaths)
        {
            Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsFolder $path
        }
    }

    Context "ReportPortalUri parameter" {
        It "Should delete a RDL item" {
            Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem "$rsFolderPath/emptyReport" -Verbose
            VerifyCatalogItemDoesNotExists -itemType "Report" -itemName "emptyReport" -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should delete a RSDS item" {
            Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem "$rsFolderPath/SutWriteRsFolderContent_DataSource" -Verbose
            VerifyCatalogItemDoesNotExists -itemType "DataSource" -itemName "SutWriteRsFolderContent_DataSource" -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should delete a RSD item" {
            Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem "$rsFolderPath/UnDataset" -Verbose
            VerifyCatalogItemDoesNotExists -itemType 'DataSet' -itemName 'UnDataset' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should delete a RSMOBILE item" {
            Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem "$rsFolderPath/SimpleMobileReport" -Verbose
            VerifyCatalogItemDoesNotExists -itemType 'MobileReport' -itemName 'SimpleMobileReport' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should delete a PBIX item" {
            Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem "$rsFolderPath/SimplePowerBIReport" -Verbose
            VerifyCatalogItemDoesNotExists -itemType 'PowerBIReport' -itemName 'SimplePowerBIReport' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should delete a folder" {
            Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $rsFolderPath -Verbose
            VerifyCatalogItemDoesNotExists -itemType 'Folder' -itemName $folderName -folderPath "/" -reportServerUri $reportServerUri
        }
    }

    Context "WebSession parameter" {
        $webSession = $null

        BeforeEach {
            $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri
        }

        It "Should delete a RDL item" {
            Remove-RsRestCatalogItem -WebSession $webSession -RsItem "$rsFolderPath/emptyReport" -Verbose
            VerifyCatalogItemDoesNotExists -itemType "Report" -itemName "emptyReport" -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should delete a RSDS item" {
            Remove-RsRestCatalogItem -WebSession $webSession -RsItem "$rsFolderPath/SutWriteRsFolderContent_DataSource" -Verbose
            VerifyCatalogItemDoesNotExists -itemType "DataSource" -itemName "SutWriteRsFolderContent_DataSource" -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should delete a RSD item" {
            Remove-RsRestCatalogItem -WebSession $webSession -RsItem "$rsFolderPath/UnDataset" -Verbose
            VerifyCatalogItemDoesNotExists -itemType 'DataSet' -itemName 'UnDataset' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should delete a RSMOBILE item" {
            Remove-RsRestCatalogItem -WebSession $webSession -RsItem "$rsFolderPath/SimpleMobileReport" -Verbose
            VerifyCatalogItemDoesNotExists -itemType 'MobileReport' -itemName 'SimpleMobileReport' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should delete a PBIX item" {
            Remove-RsRestCatalogItem -WebSession $webSession -RsItem "$rsFolderPath/SimplePowerBIReport" -Verbose
            VerifyCatalogItemDoesNotExists -itemType 'PowerBIReport' -itemName 'SimplePowerBIReport' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should delete a folder" {
            Remove-RsRestCatalogItem -WebSession $webSession -RsItem $rsFolderPath -Verbose
            VerifyCatalogItemDoesNotExists -itemType 'Folder' -itemName $folderName -folderPath "/" -reportServerUri $reportServerUri
        }
    }
}