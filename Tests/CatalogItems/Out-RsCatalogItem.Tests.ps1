# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Out-RsCatalogItem" {
        Context "Out-RsFolderContent with min parameters"{

                $folderName = 'SutOutRsFolderContentMinParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
                Write-RsFolderContent -Path $localResourcesPath -RsFolder $folderPath
                $currentLocalPath = (Get-Item -Path ".\" ).FullName

                It "Should download a Report from Reporting Services with min parameters" {
                $report = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
                $reportPath = $folderPath + '/' + $report.Name 
                Out-RsCatalogItem -RsFolder $reportPath -Destination $currentLocalPath
                $localReportFile = $report.Name + '.rdl'
                $localReportPath = $currentLocalPath + '\' + $localReportFile
                (Get-Item $localReportPath).Name | Should Be $localReportFile
                # Removing local report downloaded from report server used for testing
                Remove-Item  $localReportPath
                }

                It "Should download a DataSet from Reporting Services with min parameters" {
                $dataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
                $dataSetPath = $folderPath + '/' + $dataSet.Name 
                Out-RsCatalogItem -RsFolder $dataSetPath -Destination $currentLocalPath
                $localDataSetFile = $dataSet.Name + '.rsd'
                $localDataSetPath = $currentLocalPath + '\' + $localDataSetFile
                (Get-Item $localDataSetPath).Name | Should Be $localDataSetFile
                # Removing local dataset downloaded from report server used for testing
                Remove-Item  $localDataSetPath
                }
               
                It "Should download a RsDataSource from Reporting Services with min parameters" {
                $dataSourceName = 'SutOutRsFolderContentDataSourceMinParam' + [guid]::NewGuid()
                $extension = 'SQL'
                $credentialRetrieval = 'None'
                New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
                $dataSourcePath = '/' + $dataSourceName
                Out-RsCatalogItem -RsFolder $dataSourcePath -Destination $currentLocalPath
                $localDataSourceFile = $dataSourceName + '.rsds'
                $localDataSourcePath = $currentLocalPath + '\' + $localDataSourceFile
                (Get-Item $localDataSourcePath).Name | Should Be $localDataSourceFile
                # Removing local dataSource downloaded from report server and folder un report server used for testing
                Remove-RsCatalogItem -RsFolder $dataSourcePath
                Remove-Item  $localDataSourcePath
                }
        }

        Context "Out-RsFolderContent with ReportServerUri Parameter"{   
                $dataSourceName = 'SutOutRsFolderContentReportServerUriParam' + [guid]::NewGuid()
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

                It "Should download a RsDataSource from Reporting Services with ReportServerUri to a local folder" {
                (Get-Item $localDataSourcePath).Name | Should Be $localDataSourceFile
                }
                # Removing folders used for testing
                Remove-RsCatalogItem -RsFolder $dataSourcePath
                Remove-Item  $localDataSourcePath
        }

        Context "Out-RsFolderContent with Proxy Parameter"{
            
                $dataSourceName = 'SutOutRsFolderContentProxyParam' + [guid]::NewGuid()
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

                It "Should download a RsDataSource from Reporting Services with Proxy parameters" {
                (Get-Item $localDataSourcePath).Name | Should Be $localDataSourceFile
                }
                # Removing folders used for testing
                Remove-RsCatalogItem -RsFolder $dataSourcePath
                Remove-Item  $localDataSourcePath  
        }

        Context "Out-RsFolderContent with Proxy and Report ServerUri Parameter"{
                $dataSourceName = 'SutOutRsFolderContentAllParameter' + [guid]::NewGuid()
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

                It "Should download a RsDataSource from Reporting Services with Proxy and ReportServerUri parameter" {
                (Get-Item $localDataSourcePath).Name | Should Be $localDataSourceFile
                }
                # Removing folders used for testing
                Remove-RsCatalogItem -RsFolder $dataSourcePath
                Remove-Item  $localDataSourcePath
        } 
}