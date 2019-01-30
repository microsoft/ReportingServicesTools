# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Out-RsCatalogItem" {
        Context "Out-RsCatalogItem with min parameters"{
                 # Upload the catalog items that are going to be downloaded
                $folderName = 'SutOutRsCatalogItem_MinParameters' + [guid]::NewGuid()
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
                        # Download Report        
                        $report = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
                        $reportPath = $folderPath + '/' + $report.Name 
                        Out-RsCatalogItem -RsFolder $reportPath -Destination $destinationPath
                        # Test if the report was downloaded
                        $localReportDownloaded = Get-ChildItem  $localFolderName
                        $localReportDownloaded.Name | Should Be 'emptyReport.rdl'
                        $localReportDownloadedPath = $currentLocalPath + '\' + $localFolderName +'\' + 'emptyReport.rdl'
                        Remove-Item $localReportDownloadedPath
                }

                It "Should download a DataSet from Reporting Services with min parameters" {
                        $dataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
                        $dataSetPath = $folderPath + '/' + $dataSet.Name 
                        Out-RsCatalogItem -RsFolder $dataSetPath -Destination $destinationPath
                        # Test if the dataset was downloaded
                        $localDataSetDownloaded = Get-ChildItem  $localFolderName
                        $localDataSetDownloaded.Name | Should Be 'UnDataset.rsd'
                        $localDataSetDownloadedPath = $currentLocalPath + '\' + $localFolderName +'\' + 'UnDataset.rsd'
                        Remove-Item $localDataSetDownloadedPath
                }
               
                It "Should download a RsDataSource from Reporting Services with min parameters" {
                        $dataSource = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSource'
                        $dataSourcePath = $folderPath + '/' + $dataSource.Name 
                        Out-RsCatalogItem -RsFolder $dataSourcePath -Destination $destinationPath
                        $localDataSourceDownloaded = Get-ChildItem  $localFolderName
                        $localDataSourceDownloaded.Name | Should Be 'SutWriteRsFolderContent_DataSource.rsds'
                        $localDataSourceDownloadedPath = $currentLocalPath + '\' + $localFolderName +'\' +  'SutWriteRsFolderContent_DataSource.rsds'
                  }
                Remove-Item $destinationPath -Confirm:$false -Recurse
                Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
        }

        Context "Download a report with ReportServerUri Parameter"{
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

                It "Should download a Report from Reporting Services with ReportServerUri Parameter" {
                        # Download Report        
                        $report = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
                        $reportServerUri = 'http://localhost/reportserver'
                        $reportPath = $folderPath + '/' + $report.Name 
                        Out-RsCatalogItem -RsFolder $reportPath -Destination $destinationPath -ReportServerUri $reportServerUri
                        # Test if the report was downloaded
                        $localReportDownloaded = Get-ChildItem  $localFolderName
                        $localReportDownloaded.Name | Should Be 'emptyReport.rdl'
                        $localReportDownloadedPath = $currentLocalPath + '\' + $localFolderName +'\' + 'emptyReport.rdl'
                        Remove-Item $localReportDownloadedPath
                }
                Remove-Item $destinationPath -Confirm:$false -Recurse
                Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
        }

        Context "Download a report with Proxy and ReportServerUr Parameter"{
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

                It "Should download a Report from Reporting Services with ReportServerUri and Proxy Parameter" {
                        # Download Report        
                        $report = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
                        $reportServerUri = 'http://localhost/reportserver'
                        $proxy = New-RsWebServiceProxy
                        $reportPath = $folderPath + '/' + $report.Name 
                        Out-RsCatalogItem -RsFolder $reportPath -Destination $destinationPath -ReportServerUri $reportServerUri -Proxy $proxy 
                        # Test if the report was downloaded
                        $localReportDownloaded = Get-ChildItem  $localFolderName
                        $localReportDownloaded.Name | Should Be 'emptyReport.rdl'
                        $localReportDownloadedPath = $currentLocalPath + '\' + $localFolderName +'\' + 'emptyReport.rdl'
                        Remove-Item $localReportDownloadedPath
                }
                Remove-Item $destinationPath -Confirm:$false -Recurse
                Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
        }

        Context "Download a report with Proxy Parameter"{
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

                It "Should download a Report from Reporting Services with Proxy Parameter" {
                        # Download Report        
                        $report = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
                        $proxy = New-RsWebServiceProxy
                        $reportPath = $folderPath + '/' + $report.Name 
                        Out-RsCatalogItem -RsFolder $reportPath -Destination $destinationPath -Proxy $proxy 
                        # Test if the report was downloaded
                        $localReportDownloaded = Get-ChildItem  $localFolderName
                        $localReportDownloaded.Name | Should Be 'emptyReport.rdl'
                        $localReportDownloadedPath = $currentLocalPath + '\' + $localFolderName +'\' + 'emptyReport.rdl'
                        Remove-Item $localReportDownloadedPath
                }
                Remove-Item $destinationPath -Confirm:$false -Recurse
                Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
        } 
}

