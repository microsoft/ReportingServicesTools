# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Out-RsFolderContent" {

        Context "Out-RsFolderContent with min parameters"{
                $folderName = 'SutOutRsFolderContentMinParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $rsFolderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
                Write-RsFolderContent -Path $localResourcesPath -RsFolder $rsFolderPath
                $localFolderName = 'SutOutRsFolderContentTest' + [guid]::NewGuid()
                $currentLocalPath = (Get-Item -Path ".\" ).FullName
                $destinationPath = $currentLocalPath + '\' + $localFolderName
                New-Item -Path $destinationPath -type "directory"
                Out-RsFolderContent -RsFolder $rsFolderPath -Destination $destinationPath
                $localChildrenFolder = Get-ChildItem $destinationPath

                It "Should download a folder content from Reporting Services with min parameters" {
                        $localChildrenFolder.Count | Should BeGreaterThan 0
                }
                # Removing local folder content downloaded from report server used for testing
                Remove-Item  $destinationPath -Confirm:$false -Recurse
                Remove-RsCatalogItem -RsFolder $rsFolderPath
        }

        Context "Out-RsFolderContent with ReportServerUri Parameter"{
                $folderName = 'SutOutRsFolderContentReportServerUriParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $rsFolderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
                Write-RsFolderContent -Path $localResourcesPath -RsFolder $rsFolderPath
                $localFolderName = 'SutOutRsFolderContentTest' + [guid]::NewGuid()
                $currentLocalPath = (Get-Item -Path ".\" ).FullName
                $destinationPath = $currentLocalPath + '\' + $localFolderName
                New-Item -Path $destinationPath -type "directory"
                $reportServerUri = 'http://localhost/reportserver'
                Out-RsFolderContent -RsFolder $rsFolderPath -Destination $destinationPath -ReportServerUri $reportServerUri
                $localChildrenFolder = Get-ChildItem $destinationPath

                It "Should download a folder content from Reporting Services with min parameters" {
                        $localChildrenFolder.Count | Should BeGreaterThan 0
                }
                # Removing local folder content downloaded from report server used for testing
                Remove-Item  $destinationPath -Confirm:$false -Recurse
                Remove-RsCatalogItem -RsFolder $rsFolderPath
        }

        Context "Out-RsFolderContent with Proxy Parameter"{
                $folderName = 'SutOutRsFolderContentProxyParameter' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $rsFolderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
                Write-RsFolderContent -Path $localResourcesPath -RsFolder $rsFolderPath
                $localFolderName = 'SutOutRsFolderContentTest' + [guid]::NewGuid()
                $currentLocalPath = (Get-Item -Path ".\" ).FullName
                $destinationPath = $currentLocalPath + '\' + $localFolderName
                New-Item -Path $destinationPath -type "directory"
                $proxy = New-RsWebServiceProxy 
                Out-RsFolderContent -RsFolder $rsFolderPath -Destination $destinationPath -Proxy $proxy
                $localChildrenFolder = Get-ChildItem $destinationPath

                It "Should download a folder content from Reporting Services with min parameters" {
                        $localChildrenFolder.Count | Should BeGreaterThan 0
                }
                # Removing local folder content downloaded from report server used for testing
                Remove-Item  $destinationPath -Confirm:$false -Recurse
                Remove-RsCatalogItem -RsFolder $rsFolderPath
        }

        Context "Out-RsFolderContent with Proxy and ReportServer Parameter"{
                $folderName = 'SutOutRsFolderContentAllParameters' + [guid]::NewGuid()
                New-RsFolder -Path / -FolderName $folderName
                $rsFolderPath = '/' + $folderName
                $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
                Write-RsFolderContent -Path $localResourcesPath -RsFolder $rsFolderPath
                $localFolderName = 'SutOutRsFolderContentTest' + [guid]::NewGuid()
                $currentLocalPath = (Get-Item -Path ".\" ).FullName
                $destinationPath = $currentLocalPath + '\' + $localFolderName
                New-Item -Path $destinationPath -type "directory"
                $proxy = New-RsWebServiceProxy 
                $reportServerUri = 'http://localhost/reportserver'
                Out-RsFolderContent -RsFolder $rsFolderPath -Destination $destinationPath -Proxy $proxy -ReportServerUri $reportServerUri
                $localChildrenFolder = Get-ChildItem $destinationPath

                It "Should download a folder content from Reporting Services with min parameters" {
                        $localChildrenFolder.Count | Should BeGreaterThan 0
                }
                # Removing local folder content downloaded from report server used for testing
                Remove-Item  $destinationPath -Confirm:$false -Recurse
                Remove-RsCatalogItem -RsFolder $rsFolderPath
        }
}