# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Function Get-ExistingDataExtension
{
        $proxy = New-RsWebServiceProxy
        return $proxy.ListExtensions("Data")[0].Name
}

Describe "Out-RsCatalogItem" {
        Context "Out-RsCatalogItem with min parameters"{
                # Upload the catalog items that are going to be downloaded
                $folderName = 'SutOutRsCatalogItemMinParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
                Write-RsFolderContent -Path $localResourcesPath -RsFolder $folderPath
                # Create a local folder to download the catalog items
                $localFolderName = 'SutOutRsFolderContentTest' + [guid]::NewGuid()
                $currentLocalPath = (Get-Item -Path ".\" ).FullName
                $destinationPath = $currentLocalPath + '\' + $localFolderName
                New-Item -Path $destinationPath -type "directory"

                It "Should download a Report from Reporting Services with min parameters" {
                $report = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
                $reportPath = $folderPath + '/' + $report.Name 
                Out-RsCatalogItem -RsFolder $reportPath -Destination $destinationPath
                $localReportName = $report.Name + '.rdl'
                $localReportPath = $destinationPath + '\' + $localReportName
                $localReportFile = Get-Item $localReportPath
                $localReportFile.Name | Should Be $localReportName
                Remove-Item $localReportPath
                }

                It "Should download a DataSet from Reporting Services with min parameters" {
                $dataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
                $dataSetPath = $folderPath + '/' + $dataSet.Name 
                Out-RsCatalogItem -RsFolder $dataSetPath -Destination $destinationPath
                $localDataSetName = $dataSet.Name + '.rsd'
                $localDataSetPath = $destinationPath + '\' + $localDataSetName
                $localDataSetFile = Get-Item $localDataSetPath
                $localDataSetFile.Name | Should Be $localDataSetName
                Remove-Item $localDataSetPath
                }
               
                It "Should download a RsDataSource from Reporting Services with min parameters" {
                $dataSource = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSource'
                $dataSourcePath = $folderPath + '/' + $dataSource.Name 
                Out-RsCatalogItem -RsFolder $dataSourcePath -Destination $destinationPath
                $localDataSourceName = $dataSource.Name + '.rsds'
                $localDataSourcePath = $destinationPath + '\' + $localDataSourceName
                $localDataSourceFile = Get-Item $localDataSourcePath
                $localDataSourceFile.Name | Should Be $localDataSourceName
                  }
                Remove-Item $destinationPath -Confirm:$false -Recurse
                Remove-RsCatalogItem -RsFolder $folderPath
        }

        Context "Download a dataSource with ReportServerUri Parameter"{   
                $dataSourceName = 'SutGetDataSourceReportServerUri' + [guid]::NewGuid()
                $extension = Get-ExistingDataExtension
                $credentialRetrieval = 'None'
                $dataSourcePath = '/' + $dataSourceName
                New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
                $reportServerUri = 'http://localhost/reportserver'
                $currentLocalPath = (Get-Item -Path ".\" ).FullName
                Out-RsCatalogItem -RsFolder $dataSourcePath -Destination $currentLocalPath -ReportServerUri $reportServerUri
                # Search if the catalog item was downloaded
                $localDataSourceFullName = $dataSourceName + '.rsds'
                $localDataSourcePath = $currentLocalPath + '\' + $localDataSourceFullName
                $localDataSourceFile = Get-Item $localDataSourcePath

                It "Should download a Report from Reporting Services with min parameters" {
                $localDataSourceFile.Name | Should Be $localDataSourceFullName
                }
                Remove-Item $localDataSourcePath
        }

        Context "Download a dataSource with Proxy Parameter"{
                $dataSourceName = 'SutGetDataSourceReportServerUri' + [guid]::NewGuid()
                $extension = Get-ExistingDataExtension
                $credentialRetrieval = 'None'
                $dataSourcePath = '/' + $dataSourceName
                New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
                $currentLocalPath = (Get-Item -Path ".\" ).FullName
                $proxy = New-RsWebServiceProxy
                Out-RsCatalogItem -RsFolder $dataSourcePath -Destination $currentLocalPath -Proxy $proxy
                # Search if the catalog item was downloaded
                $localDataSourceFullName = $dataSourceName + '.rsds'
                $localDataSourcePath = $currentLocalPath + '\' + $localDataSourceFullName
                $localDataSourceFile = Get-Item $localDataSourcePath

                It "Should download a Report from Reporting Services with min parameters" {
                $localDataSourceFile.Name | Should Be $localDataSourceFullName
                }
                Remove-Item $localDataSourcePath
        }

        Context "Download a dataSource with Proxy and Report ServerUri Parameter"{
                $dataSourceName = 'SutGetDataSourceReportServerUri' + [guid]::NewGuid()
                $extension = Get-ExistingDataExtension
                $credentialRetrieval = 'None'
                $dataSourcePath = '/' + $dataSourceName
                New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
                $currentLocalPath = (Get-Item -Path ".\" ).FullName
                $reportServerUri = 'http://localhost/reportserver'
                $proxy = New-RsWebServiceProxy
                Out-RsCatalogItem -RsFolder $dataSourcePath -Destination $currentLocalPath -Proxy $proxy -ReportServerUri $reportServerUri
                # Search if the catalog item was downloaded
                $localDataSourceFullName = $dataSourceName + '.rsds'
                $localDataSourcePath = $currentLocalPath + '\' + $localDataSourceFullName
                $localDataSourceFile = Get-Item $localDataSourcePath

                It "Should download a Report from Reporting Services with min parameters" {
                $localDataSourceFile.Name | Should Be $localDataSourceFullName
                }
                Remove-Item $localDataSourcePath
        } 
}