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
    $rsFolderPath = ""

    BeforeEach {
        # creating a new folder
        $folderName = "SUT_RemoveRsRestFolder_" + [Guid]::NewGuid()
        New-RsRestFolder -ReportPortalUri $reportPortalUri -FolderName $folderName -RsFolder /
        $rsFolderPath = "/$folderName"

        # uploading resources to the folder
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsRestFolderContent -ReportPortalUri $reportPortalUri -Path $localResourcesPath -RsFolder $rsFolderPath
    }

    Context "ReportPortalUri parameter" {
        It "Should delete a folder" {
            Remove-RsRestFolder -ReportPortalUri $reportPortalUri -RsFolder $rsFolderPath
            VerifyCatalogItemDoesNotExists -itemType "Folder" -itemName $folderName -folderPath "/" -reportServerUri $reportServerUri
        }
    }

    Context "WebSession parameter" {
        $webSession = $null

        BeforeEach {
            $webSession = New-RsRestSession -ReportPortalUri $reportPortalUri
        }

        It "Should delete a folder" {
            Remove-RsRestFolder -WebSession $webSession -RsFolder $rsFolderPath
            VerifyCatalogItemDoesNotExists -itemType "Folder" -itemName $folderName -folderPath "/" -reportServerUri $reportServerUri
        }
    }
}