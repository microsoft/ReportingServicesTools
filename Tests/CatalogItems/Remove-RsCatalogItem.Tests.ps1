# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Write-RsFolderContent" {

    Context "Write-RsFolderContent with min parameters"{
        $folderName = 'SutWriteRsFolderContentMinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        #$folderPath = '/' + $folderName
        #$localReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        #Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath
        
        It "Should remove a DataSource" {
            #$uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            #$uploadedReport.Name | Should Be 'emptyReport'
            $folderList = Get-RsFolderContent -RsFolder /
            $folderCount = ($folderList | Where-Object name -eq $folderName).Count
            $folderPath = '/' + $folderName
            $folderCount | Should Be 1

            Remove-RsCatalogItem -RsFolder $folderPath
            $folderList = Get-RsFolderContent -RsFolder /
            $folderCount = ($folderList | Where-Object name -eq $folderName).Count
            $folderPath = '/' + $folderName
            $folderCount | Should Be 0
        }


        It "Should remove a RsFolder" {
            $folderList = Get-RsFolderContent -RsFolder /
            $folderCount = ($folderList | Where-Object name -eq $folderName).Count
            $folderPath = '/' + $folderName
            $folderCount | Should Be 1

            Remove-RsCatalogItem -RsFolder $folderPath
            $folderList = Get-RsFolderContent -RsFolder /
            $folderCount = ($folderList | Where-Object name -eq $folderName).Count
            $folderPath = '/' + $folderName
            $folderCount | Should Be 0
        }
    }
}