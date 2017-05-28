# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Get-RsItemReference" {
        Context "Get-RsItemReference with min parameters"{

                $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
                Write-RsCatalogItem -Path $localResourcesPath -RsFolder $folderPath
                $report = (Get-RsFolderContent -RsFolder $folderPath )| Where-Object TypeName -eq 'Report'
                $reportReferences = Get-RsItemReference -Path $report.Path

                It "Should found a reference to a RsDataSet with min parameters" {
                   $dataSetReference = $reportReferences | Where-Object ReferenceType -eq 'DataSet'
                   $dataSetReference.Name | Should Be 'reportReferenceUnDataset'
                }

                It "Should found a reference to a RsDataSource with min parameters" {
                   $dataSourceReference = $reportReferences | Where-Object ReferenceType -eq 'DataSource'
                   $dataSourceReference.Name | Should Be 'reportReferenceDataSource'
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }

        Context "Get-RsItemReference with Proxy parameter"{

                $folderName = 'SutGetRsItemReferenceProxynParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
                Write-RsCatalogItem -Path $localResourcesPath -RsFolder $folderPath
                $report = (Get-RsFolderContent -RsFolder $folderPath )| Where-Object TypeName -eq 'Report'
                $proxy = New-RsWebServiceProxy
                $reportReferences = Get-RsItemReference -Path $report.Path -Proxy $proxy

                It "Should found a reference to a RsDataSource of a report with Proxy Parameter" {
                   $dataSourceReference = $reportReferences | Where-Object ReferenceType -eq 'DataSource'
                   $dataSourceReference.Name | Should Be 'reportReferenceDataSource'
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }

        Context "Get-RsItemReference with ReportServerUri Parameter"{

                $folderName = 'SutGetRsItemReference_ReportServerUriParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
                Write-RsCatalogItem -Path $localResourcesPath -RsFolder $folderPath
                $report = (Get-RsFolderContent -RsFolder $folderPath )| Where-Object TypeName -eq 'Report'
                $reportServerUri = 'http://localhost/reportserver'
                $reportReferences = Get-RsItemReference -Path $report.Path -ReportServerUri $reportServerUri

                It "Should found a reference to a RsDataSource of a report with ReportServerUri Parameter" {
                   $dataSourceReference = $reportReferences | Where-Object ReferenceType -eq 'DataSource'
                   $dataSourceReference.Name | Should Be 'reportReferenceDataSource'
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }

        Context "Get-RsItemReference with ReportServerUri and Proxy Parameter"{

                $folderName = 'SutGetRsItemReference_ReportServerUriProxyParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $folderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
                Write-RsCatalogItem -Path $localResourcesPath -RsFolder $folderPath
                $report = (Get-RsFolderContent -RsFolder $folderPath )| Where-Object TypeName -eq 'Report'
                $proxy = New-RsWebServiceProxy
                $reportServerUri = 'http://localhost/reportserver'
                $reportReferences = Get-RsItemReference -Path $report.Path -ReportServerUri $reportServerUri -Proxy $proxy

                It "Should found a reference to a RsDataSource of a report with ReportServerUri and Proxy Parameters" {
                   $dataSourceReference = $reportReferences | Where-Object ReferenceType -eq 'DataSource'
                   $dataSourceReference.Name | Should Be 'reportReferenceDataSource'
                }
                Remove-RsCatalogItem -RsFolder $folderPath
        }
}