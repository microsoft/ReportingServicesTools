# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
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
        $reportServerUri
    )

    $item = (Get-RsFolderContent -ReportServerUri $reportServerUri -RsFolder $folderPath) | Where-Object { $_.TypeName -eq $itemType -and $_.Name -eq $itemName }
    $item | Should Not BeNullOrEmpty
}

Describe "Write-RsRestFolderContent" {
    $rsFolderPath = ""
    $localFolderPath = (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'

    BeforeEach {
        $folderName = 'SUT_WriteRsRestFolderContent_' + [guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -RsFolder / -FolderName $folderName
        $rsFolderPath = '/' + $folderName
    }

    AfterEach {
        Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsFolder $rsFolderPath -Confirm:$false
    }

    Context "ReportPortalUri parameter" {
        It "Uploads all the resources in a folder" {
            Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localFolderPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName "emptyReport" -itemType "Report" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "emptyFile.txt" -itemType "Resource" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "NewExcelWorkbook.xlsx" -itemType "ExcelWorkbook" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "OldExcelWorkbook.xls" -itemType "ExcelWorkbook" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "SimpleMobileReport" -itemType "MobileReport" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "SimplePowerBIReport" -itemType "PowerBIReport" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "SqlPowerBIReport" -itemType "PowerBIReport" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "SutWriteRsFolderContent_DataSource" -itemType "DataSource" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "UnDataset" -itemType "DataSet" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "NewKPI" -itemType "Kpi" -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Creates subfolders and deploys resources correctly" {
            Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localFolderPath -RsFolder $rsFolderPath -Recurse -Verbose
            VerifyCatalogItemExists -itemName "testResources2" -itemType "Folder" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "emptyReport2" -itemType "Report" -folderPath "$rsFolderPath/testResources2" -reportServerUri $reportServerUri
        }

        It "Throws exception if resource already exists" {
            Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localFolderPath -RsFolder $rsFolderPath

            { Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localFolderPath -RsFolder $rsFolderPath -Verbose } | Should Throw
        }

        It "Overwrites exisiting resource if -Overwrite option is specified" {
            Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localFolderPath -RsFolder $rsFolderPath

            { Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localFolderPath -RsFolder $rsFolderPath  -Overwrite -Verbose } | Should Not Throw
        }
    }

    Context "WebSession parameter" {
        $webSession = $null

        BeforeEach {
            $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri
        }

        It "Uploads all the resources in a folder" {
            Write-RsRestFolderContent -WebSession $webSession -Path $localFolderPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName "emptyReport" -itemType "Report" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "emptyFile.txt" -itemType "Resource" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "NewExcelWorkbook.xlsx" -itemType "ExcelWorkbook" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "OldExcelWorkbook.xls" -itemType "ExcelWorkbook" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "SimpleMobileReport" -itemType "MobileReport" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "SimplePowerBIReport" -itemType "PowerBIReport" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "SqlPowerBIReport" -itemType "PowerBIReport" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "SutWriteRsFolderContent_DataSource" -itemType "DataSource" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "UnDataset" -itemType "DataSet" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "NewKPI" -itemType "Kpi" -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Creates subfolders and deploys resources correctly" {
            Write-RsRestFolderContent -WebSession $webSession -Path $localFolderPath -RsFolder $rsFolderPath -Recurse -Verbose
            VerifyCatalogItemExists -itemName "testResources2" -itemType "Folder" -folderPath $rsFolderPath -reportServerUri $reportServerUri
            VerifyCatalogItemExists -itemName "emptyReport2" -itemType "Report" -folderPath "$rsFolderPath/testResources2" -reportServerUri $reportServerUri
        }

        It "Throws exception if resource already exists" {
            Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localFolderPath -RsFolder $rsFolderPath

            { Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localFolderPath -RsFolder $rsFolderPath -Verbose } | Should Throw
        }

        It "Overwrites exisiting resource, if -Overwrite option is specified" {
            Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localFolderPath -RsFolder $rsFolderPath

            { Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localFolderPath -RsFolder $rsFolderPath -Overwrite -Verbose } | Should Not Throw
        }
    }
}