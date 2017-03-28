# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Write-RsFolderContent" {
    Context "Write-RsFolderContent with min parameters"{
        # Create a local folder to upload
        $localFolderName = 'SutTestWrite_RsFolderContent' + [guid]::NewGuid()
        $localPathFolder = './' + $localFolderName 
        New-Item -Path '.' -Name $localFolderName  -ItemType "directory"
        $rsFolderName = 'SutWrite-RsFolderContentMinParameters' + [guid]::NewGuid()
        $rsFolderPath = '/' + $rsFolderName 
        $folderInsideRsFolderPath = $rsFolderPath + '/' + $localFolderName 
        New-RsFolder -Path / -FolderName $rsFolderName
        Write-RsFolderContent -Path $localPathFolder -RsFolder $rsFolderName
        $foundFolder = Get-RsFolderContent -RsFolder / | Where-Object path -eq $folderInsideRsFolderPath
        It "Should write a local folder in an RSFolder" {
            
        }
        # Removing folders used for testing
        #Remove-RsCatalogItem -RsFolder $rsFolderPath
        #Remove-Item $localPathFolder
    }
}