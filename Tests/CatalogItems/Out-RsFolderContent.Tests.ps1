# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Out-RsFolderContent" {
    Context "Out-RsFolderContent with min parameters"{

        It "Should download a RsDataSource from Reporting Services with min parameters to a local folder" {
            
            $dataSourceName = 'SutOutRsFolderContentDataSourceMinParam' + [guid]::NewGuid()
            $extension = 'SQL'
            $credentialRetrieval = 'None'
            New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
            $dataSourcePath = '/' + $dataSourceName
            $currentLocalPath = (Get-Item -Path ".\" -Verbose).FullName
            Out-RsCatalogItem -RsFolder $dataSourcePath -Destination $currentLocalPath
            $localDataSourceFile = $dataSourceName + '.rsds'
            $localDataSourcePath = $currentLocalPath + '\' + $localDataSourceFile
            Get-Item $localDataSourcePath

            (Get-Item $localDataSourcePath).Name | Should Be $localDataSourceFile

             # Removing folders used for testing
            Remove-RsCatalogItem -RsFolder $dataSourcePath
            Remove-Item  $localDataSourcePath
        }
    }

    Context "Out-RsFolderContent with ReportServerUri Parameter"{
        
        It "Should download a RsDataSource from Reporting Services with ReportServerUri to a local folder" {
            
            $dataSourceName = 'SutOutRsFolderContentDataSourceRsUriParam' + [guid]::NewGuid()
            $extension = 'SQL'
            $credentialRetrieval = 'None'
            New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
            $dataSourcePath = '/' + $dataSourceName
            $currentLocalPath = (Get-Item -Path ".\" -Verbose).FullName
            $reportServerUri = 'http://localhost/reportserver'
            Out-RsCatalogItem -RsFolder $dataSourcePath -Destination $currentLocalPath -ReportServerUri $reportServerUri
            $localDataSourceFile = $dataSourceName + '.rsds'
            $localDataSourcePath = $currentLocalPath + '\' + $localDataSourceFile
            Get-Item $localDataSourcePath

            (Get-Item $localDataSourcePath).Name | Should Be $localDataSourceFile

            # Removing folders used for testing
            Remove-RsCatalogItem -RsFolder $dataSourcePath
            Remove-Item  $localDataSourcePath
        }
        
    }

    Context "Out-RsFolderContent with Proxy Parameter"{
        
        It "Should download a RsDataSource from Reporting Services with Proxy parameters" {
            
            $dataSourceName = 'SutOutRsFolderContentDataSourceProxyParam' + [guid]::NewGuid()
            $extension = 'SQL'
            $credentialRetrieval = 'None'
            New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
            $dataSourcePath = '/' + $dataSourceName
            $currentLocalPath = (Get-Item -Path ".\" -Verbose).FullName
            $proxy = New-RsWebServiceProxy
            Out-RsCatalogItem -RsFolder $dataSourcePath -Destination $currentLocalPath -Proxy $proxy
            $localDataSourceFile = $dataSourceName + '.rsds'
            $localDataSourcePath = $currentLocalPath + '\' + $localDataSourceFile
            Get-Item $localDataSourcePath

            # Test if the downloaded datasource is found in the local folder
            (Get-Item $localDataSourcePath).Name | Should Be $localDataSourceFile

             # Removing folders used for testing
            Remove-RsCatalogItem -RsFolder $dataSourcePath
            Remove-Item  $localDataSourcePath
        }  
    }

     Context "Out-RsFolderContent with Proxy and Report ServerUri Parameter"{
        
        It "Should download a RsDataSource from Reporting Services with Proxy and ReportServerUri parameter" {
            $dataSourceName = 'SutOutRsFolderContentDataSourceAllParam' + [guid]::NewGuid()
            $extension = 'SQL'
            $credentialRetrieval = 'None'
            New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
            $dataSourcePath = '/' + $dataSourceName
            $currentLocalPath = (Get-Item -Path ".\" -Verbose).FullName
            $proxy = New-RsWebServiceProxy
            $reportServerUri = 'http://localhost/reportserver'
            Out-RsCatalogItem -RsFolder $dataSourcePath -Destination $currentLocalPath -Proxy $proxy -ReportServerUri $reportServerUri
            $localDataSourceFile = $dataSourceName + '.rsds'
            $localDataSourcePath = $currentLocalPath + '\' + $localDataSourceFile
            Get-Item $localDataSourcePath

            # Test if the downloaded datasource is found in the local folder
            (Get-Item $localDataSourcePath).Name | Should Be $localDataSourceFile

            # Removing folders used for testing
            Remove-RsCatalogItem -RsFolder $dataSourcePath
            Remove-Item  $localDataSourcePath
        }
        
    }

}