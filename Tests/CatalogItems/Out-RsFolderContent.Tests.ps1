# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Out-RsFolderContent" {

        Context "Out-RsFolderContent with min parameters"{
                $folderName = 'SutOutRsFolderContentMinParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $rsFolderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
                Write-RsFolderContent -Path $localResourcesPath -RsFolder $rsFolderPath
                $localFolderName = 'SutOutRsFolderContentTestMin' + [guid]::NewGuid()
                $currentLocalPath = (Get-Item -Path ".\" ).FullName
                $destinationPath = $currentLocalPath + '\' + $localFolderName
                New-Item -Path $destinationPath -type "directory"
                Out-RsFolderContent -RsFolder $rsFolderPath -Destination $destinationPath
                $localChildrenFolder = Get-ChildItem $destinationPath

                It "Should download a report from Reporting Services with min parameters" { 
                       $localReport = $localChildrenFolder | Where-Object Name -eq 'emptyReport.rdl'
                       $localReport.Name | Should Be 'emptyReport.rdl'
                }

                It "Should download a RsDataSource from Reporting Services with min parameters" {
                        $localDataSource = $localChildrenFolder| Where-Object Name -eq 'SutWriteRsFolderContent_DataSource.rsds'
                        $localDataSource.Name | Should Be 'SutWriteRsFolderContent_DataSource.rsds'
                }

                It "Should download a RsDataSet from Reporting Services with min parameters" {
                        $localDataSource = $localChildrenFolder | Where-Object Name -eq 'UnDataSet.rsd'
                        $localDataSource.Name | Should Be 'UnDataSet.rsd'
                }
                # Removing local folder content downloaded from report server used for testing
                Remove-Item  $destinationPath -Confirm:$false -Recurse
                Remove-RsCatalogItem -RsFolder $rsFolderPath -Confirm:$false
        }

        Context "Out-RsFolderContent with ReportServerUri Parameter"{
                $folderName = 'SutOutRsFolderContentReportServerUriParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $rsFolderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
                Write-RsFolderContent -Path $localResourcesPath -RsFolder $rsFolderPath
                $localFolderName = 'SutOutRsFolderContentTestReportUri' + [guid]::NewGuid()
                $currentLocalPath = (Get-Item -Path ".\" ).FullName
                $destinationPath = $currentLocalPath + '\' + $localFolderName
                New-Item -Path $destinationPath -type "directory"
                $reportServerUri = 'http://localhost/reportserver'
                Out-RsFolderContent -RsFolder $rsFolderPath -Destination $destinationPath -ReportServerUri $reportServerUri
                $localChildrenFolder = Get-ChildItem $destinationPath

                It "Should download a report from Reporting Services with ReportServerUri parameters" {
                        $localReport = $localChildrenFolder | Where-Object Name -eq 'emptyReport.rdl'
                        $localReport.Name | Should Be 'emptyReport.rdl'
                }
                # Removing local folder content downloaded from report server used for testing
                Remove-Item  $destinationPath -Confirm:$false -Recurse
                Remove-RsCatalogItem -RsFolder $rsFolderPath -Confirm:$false
        }

        Context "Out-RsFolderContent with Proxy Parameter"{
                $folderName = 'SutOutRsFolderContentProxyParameter' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $rsFolderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
                Write-RsFolderContent -Path $localResourcesPath -RsFolder $rsFolderPath
                $localFolderName = 'SutOutRsFolderContentTestProxy' + [guid]::NewGuid()
                $currentLocalPath = (Get-Item -Path ".\" ).FullName
                $destinationPath = $currentLocalPath + '\' + $localFolderName
                New-Item -Path $destinationPath -type "directory"
                $proxy = New-RsWebServiceProxy 
                Out-RsFolderContent -RsFolder $rsFolderPath -Destination $destinationPath -Proxy $proxy
                $localChildrenFolder = Get-ChildItem $destinationPath

                It "Should download a report from Reporting Services with Proxy Parameters" {
                        $localReport = $localChildrenFolder | Where-Object Name -eq 'emptyReport.rdl'
                        $localReport.Name | Should Be 'emptyReport.rdl'
                }
                # Removing local folder content downloaded from report server used for testing
                Remove-Item  $destinationPath -Confirm:$false -Recurse
                Remove-RsCatalogItem -RsFolder $rsFolderPath -Confirm:$false
        }

        Context "Out-RsFolderContent with Proxy and ReportServer Parameter"{
                $folderName = 'SutOutRsFolderContentAllParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $rsFolderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
                Write-RsFolderContent -Path $localResourcesPath -RsFolder $rsFolderPath
                $localFolderName = 'SutOutRsFolderContentTestAllParam' + [guid]::NewGuid()
                $currentLocalPath = (Get-Item -Path ".\" ).FullName
                $destinationPath = $currentLocalPath + '\' + $localFolderName
                New-Item -Path $destinationPath -type "directory"
                $proxy = New-RsWebServiceProxy 
                $reportServerUri = 'http://localhost/reportserver'
                Out-RsFolderContent -RsFolder $rsFolderPath -Destination $destinationPath -Proxy $proxy -ReportServerUri $reportServerUri
                $localChildrenFolder = Get-ChildItem $destinationPath

                It "Should download a report from Reporting Services with Proxy and ReportServerUri parameter" {
                        $localReport = $localChildrenFolder | Where-Object Name -eq 'emptyReport.rdl'
                        $localReport.Name | Should Be 'emptyReport.rdl'
                }
                # Removing local folder content downloaded from report server used for testing
                Remove-Item  $destinationPath -Confirm:$false -Recurse
                Remove-RsCatalogItem -RsFolder $rsFolderPath -Confirm:$false
        }

        Context "Out-RsFolderContent with recurse parameters"{
                $folderName = 'SutOutRsFolderContentRecurseParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $rsFolderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
                Write-RsFolderContent -Path $localResourcesPath -RsFolder $rsFolderPath -Recurse
                $localFolderName = 'SutOutRsFolderContentTestRecurse' + [guid]::NewGuid()
                $currentLocalPath = (Get-Item -Path ".\" ).FullName
                $destinationPath = $currentLocalPath + '\' + $localFolderName
                New-Item -Path $destinationPath -type "directory"
                Out-RsFolderContent -RsFolder $rsFolderPath -Destination $destinationPath -Recurse
                $localChildrenFolder = Get-ChildItem $destinationPath -Recurse

                It "Should download a report in a folder from Reporting Services with min parameters" { 
                       $localReport = $localChildrenFolder | Where-Object Name -eq 'emptyReport.rdl'
                       $localReport.Name | Should Be 'emptyReport.rdl'
                }

                It "Should download a RsDataSource from Reporting Services with min parameters" {
                        $localDataSource = $localChildrenFolder| Where-Object Name -eq 'SutWriteRsFolderContent_DataSource.rsds'
                        $localDataSource.Name | Should Be 'SutWriteRsFolderContent_DataSource.rsds'
                }

                It "Should download a RsDataSet from Reporting Services with min parameters" {
                        $localDataSource = $localChildrenFolder | Where-Object Name -eq 'UnDataSet.rsd'
                        $localDataSource.Name | Should Be 'UnDataSet.rsd'
                }

                It "Should download a report inside a subfolder from Reporting Services with min parameters" { 
                       $localReport = $localChildrenFolder | Where-Object Name -eq 'emptyReport2.rdl'
                       $localReport.Name | Should Be 'emptyReport2.rdl'
                }

                 It "Should download a subfolder from Reporting Services with min parameters" { 
                       $localReport = $localChildrenFolder | Where-Object Name -eq 'testResources2'
                       $localReport.Name | Should Be 'testResources2'
                }
                # Removing local folder content downloaded from report server used for testing
                Remove-RsCatalogItem -RsFolder $rsFolderPath -Confirm:$false
                Remove-Item  $destinationPath -Confirm:$false -Recurse
        }
}