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

Describe "Write-RsRestCatalogItem" {
    $rsFolderPath = ""
    $localPath = (Get-Item -Path ".\").FullName + '\Tests\CatalogItems\testResources'

    BeforeEach {
        $folderName = 'SUT_WriteRsRestCatalogItem_' + [guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -RsFolder / -FolderName $folderName
        $rsFolderPath = '/' + $folderName
    }

    AfterEach {
        Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsFolder $rsFolderPath -Confirm:$false
    }

    Context "ReportPortalUri parameter" {
        It "Should upload a local RDL file" {
            $itemPath = Join-Path -Path $localPath -ChildPath emptyReport.rdl
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'emptyReport' -itemType 'Report' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local RSDS file" {
            $itemPath = $localPath + '\SutWriteRsFolderContent_DataSource.rsds'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'SutWriteRsFolderContent_DataSource' -itemType 'DataSource' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local RSD file" {
            $itemPath = $localPath + '\UnDataset.rsd'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'UnDataset' -itemType 'DataSet' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local small PBIX file" {
            $itemPath = $localPath + '\SimplePowerBIReport.pbix'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'SimplePowerBIReport' -itemType 'PowerBIReport' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local large PBIX file" {
            $itemPath = $localPath + '\SimplePowerBIReport.pbix'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -MinLargeFileSizeInMb '0.01' -Verbose
            VerifyCatalogItemExists -itemName 'SimplePowerBIReport' -itemType 'PowerBIReport' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local large PBIX file larger than the maximum size" {
            $itemPath = $localPath + '\SimplePowerBIReport.pbix'
            { Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -MinLargeFileSizeInMb '0.001' -MaxFileSizeInMb '0.01' -Verbose } | Should Throw
        }

        It "Should upload a local XLS file" {
            $itemPath = $localPath + '\OldExcelWorkbook.xls'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'OldExcelWorkbook.xls' -itemType 'ExcelWorkbook' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local XLSX file" {
            $itemPath = $localPath + '\NewExcelWorkbook.xlsx'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'NewExcelWorkbook.xlsx' -itemType 'ExcelWorkbook' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local TXT file" {
            $itemPath = $localPath + '\emptyFile.txt'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'emptyFile.txt' -itemType 'Resource' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local KPI file" {
            $itemPath = $localPath + '\NewKPI.kpi'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'NewKPI' -itemType 'Kpi' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should overwrite a file when -Overwrite is specified" {
            $itemPath = Join-Path -Path $localPath -ChildPath emptyReport.rdl
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -Overwrite -Verbose
            VerifyCatalogItemExists -itemName 'emptyReport' -itemType 'Report' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should not overwrite a file without -Overwrite parameter" {
            $itemPath = Join-Path -Path $localPath -ChildPath emptyReport.rdl
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath
            { Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -Verbose } | Should Throw
        }

        It "Should upload a local JPG file" {
            $itemPath = $localPath + '\imagesResources\PowerShellHero.jpg'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'PowerShellHero.jpg' -itemType 'Resource' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local PNG file" {
            $itemPath = $localPath + '\imagesResources\SSRS.png'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'SSRS.png' -itemType 'Resource' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }
    }

    Context "WebSession parameter" {
        $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri

        It "Should upload a local RDL file" {
            $itemPath = Join-Path -Path $localPath -ChildPath emptyReport.rdl
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'emptyReport' -itemType 'Report' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local RSDS file" {
            $itemPath = $localPath + '\SutWriteRsFolderContent_DataSource.rsds'
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'SutWriteRsFolderContent_DataSource' -itemType 'DataSource' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local RSD file" {
            $itemPath = $localPath + '\UnDataset.rsd'
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'UnDataset' -itemType 'DataSet' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local PBIX file" {
            $itemPath = $localPath + '\SimplePowerBIReport.pbix'
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'SimplePowerBIReport' -itemType 'PowerBIReport' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local XLS file" {
            $itemPath = $localPath + '\OldExcelWorkbook.xls'
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'OldExcelWorkbook.xls' -itemType 'ExcelWorkbook' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local XLSX file" {
            $itemPath = $localPath + '\NewExcelWorkbook.xlsx'
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'NewExcelWorkbook.xlsx' -itemType 'ExcelWorkbook' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local TXT file" {
            $itemPath = $localPath + '\emptyFile.txt'
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'emptyFile.txt' -itemType 'Resource' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local KPI file" {
            $itemPath = $localPath + '\NewKPI.kpi'
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $rsFolderPath  -Verbose
            VerifyCatalogItemExists -itemName 'NewKPI' -itemType 'Kpi' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local JPG file" {
            $itemPath = $localPath + '\imagesResources\PowerShellHero.jpg'
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'PowerShellHero.jpg' -itemType 'Resource' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should upload a local PNG file" {
            $itemPath = $localPath + '\imagesResources\SSRS.png'
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $rsFolderPath -Verbose
            VerifyCatalogItemExists -itemName 'SSRS.png' -itemType 'Resource' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should overwrite a file when -Overwrite is specified" {
            $itemPath = Join-Path -Path $localPath -ChildPath emptyReport.rdl
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $rsFolderPath
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $rsFolderPath -Overwrite -Verbose
            VerifyCatalogItemExists -itemName 'emptyReport' -itemType 'Report' -folderPath $rsFolderPath -reportServerUri $reportServerUri
        }

        It "Should not overwrite a file without -Overwrite parameter" {
            $itemPath = Join-Path -Path $localPath -ChildPath emptyReport.rdl
            Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $rsFolderPath
            { Write-RsRestCatalogItem -WebSession $webSession -Path $itemPath -RsFolder $rsFolderPath -Verbose } | Should Throw
        }
    }
}
