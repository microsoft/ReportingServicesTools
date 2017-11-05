# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = 'http://localhost/reports'
$reportServerUri = 'http://localhost/reportserver'

function VerifyFileWasDownloaded()
{
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $folderPath,

        [Parameter(Mandatory = $True)]
        [string]
        $fileName
    )
    # Test if the report was downloaded
    $localReportDownloaded = Get-ChildItem  $folderPath | Where-Object { $_.Name -eq $fileName }
    $localReportDownloaded | Should Not BeNullOrEmpty
    $localReportDownloadedPath = $folderPath +'\' + $fileName
}

Describe "Out-RsRestCatalogItem" {
    $rsFolderPath = ""
    $localFolderPath = ""

    BeforeEach {
        # create new folder in RS
        $folderName = 'SUT_OutRsRestCatalogItem_' + [guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -RsFolder / -FolderName $folderName
        $rsFolderPath = '/' + $folderName

        # Upload the catalog items that are going to be downloaded
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localResourcesPath -RsFolder $rsFolderPath

        # Create a local folder to download the catalog items
        $localFolderName = 'SutOutRsRestCatalogItemTest' + [guid]::NewGuid()
        $currentLocalPath = (Get-Item -Path ".\" ).FullName
        $localFolderPath = $currentLocalPath + '\' + $localFolderName
        New-Item -Path $localFolderPath -type "directory"
    }

    AfterEach {
        Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsFolder $rsFolderPath
        Remove-Item -Path $localFolderPath -Recurse
    }

    Context "ReportPortalUri parameter" {
        It "Should download a RDL file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath emptyReport
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'emptyReport.rdl'
        }

        It "Should download a RSD file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath UnDataset
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'UnDataset.rsd'
        }

        It "Should download a RSDS file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath SutWriteRsFolderContent_DataSource
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'SutWriteRsFolderContent_DataSource.rsds'
        }

        It "Should download a RSMOBILE file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath SimpleMobileReport
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'SimpleMobileReport.rsmobile'
        }

        It "Should download a PBIX file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath SimplePowerBIReport
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'SimplePowerBIReport.pbix'
        }
    }

    Context "WebSession parameter" {
        $webSession = $null

        BeforeEach {
            $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri
        }

        It "Should download a RDL file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath emptyReport
            Out-RsRestCatalogItem -WebSession $webSession -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'emptyReport.rdl'
        }

        It "Should download a RSD file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath UnDataset
            Out-RsRestCatalogItem -WebSession $webSession -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'UnDataset.rsd'
        }

        It "Should download a RSDS file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath SutWriteRsFolderContent_DataSource
            Out-RsRestCatalogItem -WebSession $webSession -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'SutWriteRsFolderContent_DataSource.rsds'
        }

        It "Should download a RSMOBILE file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath SimpleMobileReport
            Out-RsRestCatalogItem -WebSession $webSession -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'SimpleMobileReport.rsmobile'
        }

        It "Should download a PBIX file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath SimplePowerBIReport
            Out-RsRestCatalogItem -WebSession $webSession -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'SimplePowerBIReport.pbix'
        }
    }
}