# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = 'http://localhost/reports'

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
    $localReportDownloaded = Get-ChildItem  $folderPath
    $localReportDownloaded.Name | Should Be $fileName
    $localReportDownloadedPath = $folderPath +'\' + $fileName
    Remove-Item $localReportDownloadedPath
}

Describe "Out-RsRestCatalogItem" {
    Context "ReportPortalUri parameter" {
        # Upload the catalog items that are going to be downloaded
        $folderName = 'SutOutRsCatalogItem_ReportPortalUri' + [guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localResourcesPath -RsFolder $folderPath

        # Create a local folder to download the catalog items
        $localFolderName = 'SutOutRsFolderContentTest' + [guid]::NewGuid()
        $currentLocalPath = (Get-Item -Path ".\" ).FullName
        $destinationPath = $currentLocalPath + '\' + $localFolderName
        New-Item -Path $destinationPath -type "directory"

        It "Should download a RDL file" {
            $itemPath = Join-Path -Path $folderPath -ChildPath emptyReport
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $destinationPath -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName 'emptyReport.rdl'
        }

        It "Should download a RSD file" {
            $itemPath = Join-Path -Path $folderPath -ChildPath UnDataset
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $destinationPath -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName 'UnDataset.rsd'
        }

        It "Should download a RSDS file" {
            $itemPath = Join-Path -Path $folderPath -ChildPath SutWriteRsFolderContent_DataSource
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $destinationPath -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName 'SutWriteRsFolderContent_DataSource.rsds'
        }

        It "Should download a RSMOBILE file" {
            $itemPath = Join-Path -Path $folderPath -ChildPath SimpleMobileReport
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $destinationPath -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName 'SimpleMobileReport.rsmobile'
        }

        It "Should download a PBIX file" {
            $itemPath = Join-Path -Path $folderPath -ChildPath SimplePowerBIReport
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $destinationPath -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName 'SimplePowerBIReport.pbix'
        }
    }

    Context "WebSession parameter" {
        # Upload the catalog items that are going to be downloaded
        $folderName = 'SutOutRsCatalogItem_ReportPortalUri' + [guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localResourcesPath -RsFolder $folderPath

        # Create a local folder to download the catalog items
        $localFolderName = 'SutOutRsFolderContentTest' + [guid]::NewGuid()
        $currentLocalPath = (Get-Item -Path ".\" ).FullName
        $destinationPath = $currentLocalPath + '\' + $localFolderName
        New-Item -Path $destinationPath -type "directory"

        $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri

        It "Should download a RDL file" {
            $itemPath = Join-Path -Path $folderPath -ChildPath emptyReport
            Out-RsRestCatalogItem -WebSession $webSession -RsItem $itemPath -Destination $destinationPath -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName 'emptyReport.rdl'
        }

        It "Should download a RSD file" {
            $itemPath = Join-Path -Path $folderPath -ChildPath UnDataset
            Out-RsRestCatalogItem -WebSession $webSession -RsItem $itemPath -Destination $destinationPath -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName 'UnDataset.rsd'
        }

        It "Should download a RSDS file" {
            $itemPath = Join-Path -Path $folderPath -ChildPath SutWriteRsFolderContent_DataSource
            Out-RsRestCatalogItem -WebSession $webSession -RsItem $itemPath -Destination $destinationPath -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName 'SutWriteRsFolderContent_DataSource.rsds'
        }

        It "Should download a RSMOBILE file" {
            $itemPath = Join-Path -Path $folderPath -ChildPath SimpleMobileReport
            Out-RsRestCatalogItem -WebSession $webSession -RsItem $itemPath -Destination $destinationPath -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName 'SimpleMobileReport.rsmobile'
        }

        It "Should download a PBIX file" {
            $itemPath = Join-Path -Path $folderPath -ChildPath SimplePowerBIReport
            Out-RsRestCatalogItem -WebSession $webSession -RsItem $itemPath -Destination $destinationPath -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName 'SimplePowerBIReport.pbix'
        }
    }
}