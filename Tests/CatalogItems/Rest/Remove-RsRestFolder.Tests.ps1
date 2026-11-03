# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

. "$PSScriptRoot\..\..\Common\Get-RsTestSession.ps1"

$reportPortalUri = if ($env:PesterPortalUrl -eq $null) { 'http://localhost/reports' } else { $env:PesterPortalUrl }
$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

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
    $restSessionFixture = @{}
    $rsFolderPath = ""

    BeforeEach {
        $fixtureSession = Get-RsTestSession -Fixture $restSessionFixture -ReportPortalUri $reportPortalUri
        # creating a new folder
        $folderName = "SUT_RemoveRsRestFolder_" + [Guid]::NewGuid()
        New-RsRestFolder -WebSession $fixtureSession -FolderName $folderName -RsFolder /
        $rsFolderPath = "/$folderName"

        # uploading resources to the folder
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsRestFolderContent -WebSession $fixtureSession -Path $localResourcesPath -RsFolder $rsFolderPath
    }

    Context "ReportPortalUri parameter" {
        It "Should delete a folder" {
            Remove-RsRestFolder -ReportPortalUri $reportPortalUri -RsFolder $rsFolderPath -Verbose -Confirm:$false
            VerifyCatalogItemDoesNotExists -itemType "Folder" -itemName $folderName -folderPath "/" -reportServerUri $reportServerUri
        }
    }

    Context "WebSession parameter" {
        $webSession = $null

        BeforeEach {
            $webSession = $fixtureSession
        }

        It "Should delete a folder" {
            Remove-RsRestFolder -WebSession $webSession -RsFolder $rsFolderPath -Verbose -Confirm:$false
            VerifyCatalogItemDoesNotExists -itemType "Folder" -itemName $folderName -folderPath "/" -reportServerUri $reportServerUri
        }
    }
}