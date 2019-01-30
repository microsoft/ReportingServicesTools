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
}

Describe "Out-RsRestFolderContent" {
    $rsFolderPath = ""
    $destinationPath = ""

    BeforeEach {
        $session = New-RsRestSession -ReportPortalUri $reportPortalUri

        # Create a folder on Report Server to upload some files to
        $folderName = 'SUT_OutRsRestCatalogItem_' + [guid]::NewGuid()
        $rsFolderPath = "/$folderName"
        New-RsRestFolder -WebSession $session -RsFolder "/" -FolderName $folderName

        # Upload the catalog items that are going to be downloaded
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsRestFolderContent -WebSession $session -RsFolder $rsFolderPath -Path $localResourcesPath -Recurse

        # Create a local folder to download the catalog items
        $localFolderName = 'SutOutRsRestFolderContentTest' + [guid]::NewGuid()
        $currentLocalPath = (Get-Item -Path ".\" ).FullName
        $destinationPath = $currentLocalPath + '\' + $localFolderName
        New-Item -Path $destinationPath -type "directory"
    }

    AfterEach {
        Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsFolder $rsFolderPath -Confirm:$false
        if ($destinationPath -ne $null -and $destinationPath.Length -ne 0 -and (Test-Path $destinationPath))
        {
            Remove-Item -Path $destinationPath -Recurse
        }
    }

    Context "ReportPortalUri parameter" {
        It "Downloads all resources from a folder" {
            Out-RsRestFolderContent -ReportPortalUri $reportPortalUri -RsFolder $rsFolderPath -Destination $destinationPath -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "emptyFile.txt"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "emptyReport.rdl"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "NewExcelWorkbook.xlsx"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "NewKPI.kpi"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "OldExcelWorkbook.xls"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SimpleMobileReport.rsmobile"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SimplePowerBIReport.pbix"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SqlPowerBIReport.pbix"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SutWriteRsFolderContent_DataSource.rsds"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "UnDataset.rsd"
        }

        It "Downloads all resources from subfolders of a folder" {
            Out-RsRestFolderContent -ReportPortalUri $reportPortalUri -RsFolder $rsFolderPath -Destination $destinationPath -Recurse -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "emptyFile.txt"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "emptyReport.rdl"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "NewExcelWorkbook.xlsx"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "NewKPI.kpi"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "OldExcelWorkbook.xls"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SimpleMobileReport.rsmobile"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SimplePowerBIReport.pbix"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SqlPowerBIReport.pbix"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SutWriteRsFolderContent_DataSource.rsds"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "UnDataset.rsd"
            VerifyFileWasDownloaded -folderPath "$destinationPath\testResources2" -fileName "emptyReport2.rdl"
        }
    }

    Context "WebSession parameter" {
        $webSession = $null

        BeforeEach {
            $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri
        }

        It "Downloads all resources from a folder" {
            Out-RsRestFolderContent -WebSession $webSession -RsFolder $rsFolderPath -Destination $destinationPath -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "emptyFile.txt"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "emptyReport.rdl"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "NewExcelWorkbook.xlsx"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "NewKPI.kpi"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "OldExcelWorkbook.xls"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SimpleMobileReport.rsmobile"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SimplePowerBIReport.pbix"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SqlPowerBIReport.pbix"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SutWriteRsFolderContent_DataSource.rsds"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "UnDataset.rsd"
        }

        It "Downloads all resources from subfolders of a folder" {
            Out-RsRestFolderContent -WebSession $webSession -RsFolder $rsFolderPath -Destination $destinationPath -Recurse -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "emptyFile.txt"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "emptyReport.rdl"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "NewExcelWorkbook.xlsx"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "NewKPI.kpi"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "OldExcelWorkbook.xls"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SimpleMobileReport.rsmobile"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SimplePowerBIReport.pbix"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SqlPowerBIReport.pbix"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "SutWriteRsFolderContent_DataSource.rsds"
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "UnDataset.rsd"
            VerifyFileWasDownloaded -folderPath "$destinationPath\testResources2" -fileName "emptyReport2.rdl"
        }
    }
}
