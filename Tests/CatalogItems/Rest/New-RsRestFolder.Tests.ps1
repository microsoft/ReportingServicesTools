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

    $item = (Get-RsFolderContent -ReportServerUri $reportServerUri -RsFolder $folderPath) | Where { $_.TypeName -eq $itemType -and $_.Name -eq $itemName }
    $item | Should Not BeNullOrEmpty
}

Describe "New-RsRestFolder" {
    Context "ReportPortalUri parameter" {
        It "Should create a folder" {
            $folderName = "SUT_NewRsRestFolder_" + [Guid]::NewGuid()
            New-RsRestFolder -ReportPortalUri $reportPortalUri -FolderName $folderName -RsFolder / -Verbose
            VerifyCatalogItemExists -itemType "Folder" -itemName $folderName -folderPath "/" -reportServerUri $reportServerUri
            Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsFolder "/$folderName" -Confirm:$false
        }
    }

    Context "WebSession parameter" {
        $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri

        It "Should create a folder" {
            $folderName = "SUT_NewRsRestFolder_" + [Guid]::NewGuid()
            New-RsRestFolder -WebSession $webSession -FolderName $folderName -RsFolder / -Verbose
            VerifyCatalogItemExists -itemType "Folder" -itemName $folderName -folderPath "/" -reportServerUri $reportServerUri
            Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsFolder "/$folderName" -Confirm:$false
        }
    }
}