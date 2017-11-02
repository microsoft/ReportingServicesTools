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

    $item = (Get-RsFolderContent -ReportServerUri $reportServerUri -RsFolder $folderPath) | Where { $_.TypeName -eq $itemType -and $_.Name -eq $itemName }
    $item | Should BeNullOrEmpty
}

Describe "Remove-RsRestFolder" {
    Context "ReportPortalUri parameter" {
        $folderName = "SUT_RemoveRsRestFolder_" + [Guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -FolderName $folderName -RsFolder /
        $folderPath = "/$folderName"

        It "Should delete a folder" {
            Remove-RsRestFolder -ReportPortalUri $reportPortalUri -RsFolder $folderPath
            VerifyCatalogItemDoesNotExists -itemType "Folder" -itemName $folderName -folderPath "/" -reportServerUri $reportServerUri
        }
    }

    Context "WebSession parameter" {
        $folderName = "SUT_RemoveRsRestFolder_" + [Guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -FolderName $folderName -RsFolder /
        $folderPath = "/$folderName"

        $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri

        It "Should delete a folder" {
            Remove-RsRestFolder -WebSession $webSession -RsFolder $folderPath
            VerifyCatalogItemDoesNotExists -itemType "Folder" -itemName $folderName -folderPath "/" -reportServerUri $reportServerUri
        }
    }
}