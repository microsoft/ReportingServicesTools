# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = 'http://localhost/reports_pbi'

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
    Remove-Item $localReportDownloadedPath
}

Describe "Out-RsRestFolderContent" {
    Context "ReportPortalUri parameter" {
        $rsFolderPath = ""
        $destinationPath = ""

        BeforeEach {
            # Create a folder on Report Server to upload some files to
            $folderName = 'SUT_OutRsRestCatalogItem_' + [guid]::NewGuid()
            $rsFolderPath = "/$folderName"
            New-RsRestFolder -ReportPortalUri $reportPortalUri -Path "/" -FolderName $folderName
            New-RsRestFolder -ReportPortalUri $reportPortalUri -Path $rsFolderPath -FolderName "Folder"

            # Upload the catalog items that are going to be downloaded
            $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsFolder $rsFolderPath -Path "$localResourcesPath\emptyReport.rdl"
            Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsFolder "$rsFolderPath/Folder" -Path "$localResourcesPath\testResources2\emptyReport2.rdl"

            # Create a local folder to download the catalog items
            $localFolderName = 'SutOutRsRestFolderContentTest' + [guid]::NewGuid()
            $currentLocalPath = (Get-Item -Path ".\" ).FullName
            $destinationPath = $currentLocalPath + '\' + $localFolderName
            New-Item -Path $destinationPath -type "directory"
        }

        It "Downloads all resources from a folder" {
            Out-RsRestFolderContent -ReportPortalUri $reportPortalUri -RsFolder $rsFolderPath -Destination $destinationPath -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "emptyReport.rdl"
        }

        It "Downloads all resources from subfolders of a folder" {
            Out-RsRestFolderContent -ReportPortalUri $reportPortalUri -RsFolder $rsFolderPath -Destination $destinationPath -Recurse -Verbose
            VerifyFileWasDownloaded -folderPath $destinationPath -fileName "emptyReport.rdl"
            VerifyFileWasDownloaded -folderPath "$destinationPath\Folder" -fileName "emptyReport2.rdl"
        }
    }
}
