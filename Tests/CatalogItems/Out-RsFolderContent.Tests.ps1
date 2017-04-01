# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Out-RsFolderContent" {
    Context "Out-RsFolderContent with min parameters"{
        $dataSourceName = 'SutOutRsFolderContentDataSourceMin' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
        $currentLocalPath = (Get-Item -Path ".\" -Verbose).FullName
        Out-RsCatalogItem -RsFolder $dataSourcePath -Destination $currentLocalPath
        $localDataSourceFile = $dataSourceName + '.rsds'
        $localDataSourcePath = $currentLocalPath + '\' + $localDataSourceFile
        Get-Item $localDataSourcePath
        It "Should download a RsDataSource from Reporting Services with min parameters" {
            (Get-Item $localDataSourcePath).Name | Should Be $localDataSourceFile
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $dataSourcePath
        Remove-Item  $localDataSourcePath
    }
}