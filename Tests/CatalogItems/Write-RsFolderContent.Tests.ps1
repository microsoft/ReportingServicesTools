# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Write-RsFolderContent" {
    Context "Write-RsFolderContent with min parameters"{
        # First Local Folder
        $localFolderName = 'SutLocalWrite_RsFolderContent' + [guid]::NewGuid()
        $localPathFolder = (Get-Item -Path ".\" -Verbose).FullName + '\' + $localFolderName + '\' 
        New-Item -Path '.' -Name $localFolderName  -ItemType "directory"
        # RsFolder
        #$rsFolderName = 'SutWrite-RsFolderContentMinParameters' + [guid]::NewGuid()
        #$rsFolderPath = '/' + $rsFolderName 
        #New-RsFolder -Path / -FolderName $rsFolderName
        $contentRsPath =  '/' + $localFolderName 
        Write-RsFolderContent -Path $localPathFolder -RsFolder /
        Get-RsFolderContent -RsFolder / -Recurse
        $foundFolder = (Get-RsFolderContent -RsFolder / ) | Where-Object path -eq $contentRsPath
        It "Should write a local folder in an RSFolder" {
            $foundFolder.Count | Should Be 1 
        }
        # Removing folders used for testing
        #Remove-RsCatalogItem -RsFolder $rsFolderPath
        #Remove-Item $localPathFolder
    }
}
