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

    $item = (Get-RsFolderContent -ReportServerUri $reportServerUri -RsFolder $folderPath) | Where { $_.TypeName -eq $itemType -and $_.Name -eq $itemName }
    $item | Should Not BeNullOrEmpty
}

Describe "New-RsRestFolder" {
    Context "ReportPortalUri parameter" {
        It "Should create a folder" {
            $folderName = "SUTNewRsRestFolder_ReportPortalUri" + [Guid]::NewGuid()
            New-RsRestFolder -ReportPortalUri $reportPortalUri -FolderName $folderName -RsFolder /
            VerifyCatalogItemExists -itemType "Folder" -itemName $folderName -folderPath "/" -reportServerUri $reportServerUri
        }
    }

    Context "WebSession parameter" {
        $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri

        It "Should create a folder" {
            $folderName = "SUTNewRsRestFolder_ReportPortalUri" + [Guid]::NewGuid()
            New-RsRestFolder -WebSession $webSession -FolderName $folderName -RsFolder /
            VerifyCatalogItemExists -itemType "Folder" -itemName $folderName -folderPath "/" -reportServerUri $reportServerUri
        }
    }
}