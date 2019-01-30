# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = if ($env:PesterPortalUrl -eq $null) { 'http://localhost/reports' } else { $env:PesterPortalUrl }
$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

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
        Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsFolder $rsFolderPath -Confirm:$false
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

        It "Should download a XLS file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath 'OldExcelWorkbook.xls'
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'OldExcelWorkbook.xls'
        }

        It "Should download a XLSX file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath 'NewExcelWorkbook.xlsx'
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'NewExcelWorkbook.xlsx'
        }

        It "Should download a Resource file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath emptyFile.txt
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'emptyFile.txt'
        }

        It "Should download a KPI" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath NewKPI
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'NewKPI.kpi'
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

        It "Should download a XLS file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath 'OldExcelWorkbook.xls'
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'OldExcelWorkbook.xls'
        }

        It "Should download a XLSX file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath 'NewExcelWorkbook.xlsx'
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'NewExcelWorkbook.xlsx'
        }

        It "Should download a Resource file" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath emptyFile.txt
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'emptyFile.txt'
        }

        It "Should download a KPI" {
            $itemPath = Join-Path -Path $rsFolderPath -ChildPath NewKPI
            Out-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $itemPath -Destination $localFolderPath -Verbose
            VerifyFileWasDownloaded -folderPath $localFolderPath -fileName 'NewKPI.kpi'
        }
    }
}