# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Write-RsFolderContent" {
    Context "Write-RsFolderContent with min parameters"{
        $dataSourceName = 'SutDataSourceMinParameters' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval

        #$contentRsPath =  '/' + $localFolderName 
        Out-RsCatalogItem -RsFolder $dataSourcePath -Destination $currentLocalPath
        It "Should write a local folder in an RSFolder" {
            $foundFolder.Count | Should Be 1 
        }
        # Removing folders used for testing
        #Remove-RsCatalogItem -RsFolder $rsFolderPath
        #Remove-Item $localPathFolder
    }
}