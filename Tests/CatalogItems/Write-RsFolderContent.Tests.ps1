# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Write-RsFolderContent" {
    Context "Write-RsFolderContent with min parameters"{
        # First Local Folder
        #$localFolderName = 'SutLocalWrite_RsFolderContent' + [guid]::NewGuid()
        #$localPathFolder = (Get-Item -Path ".\" -Verbose).FullName + '\' + $localFolderName + '\' 
        #New-Item -Path '.' -Name $localFolderName  -ItemType "directory"
        # RsFolder
        #$rsFolderName = 'SutWrite-RsFolderContentMinParameters' + [guid]::NewGuid()
        #$rsFolderPath = '/' + $rsFolderName 
        #New-RsFolder -Path / -FolderName $rsFolderName
        
        It "Should upload a local report in Report Server" {

            $folderName = 'SutWriteRsFolderContentReportMin' + [guid]::NewGuid()
            New-RsFolder -Path / -FolderName $folderName
            $folderPath = '/' + $folderName
            $localReportPath =   (Get-Item -Path ".\" -Verbose).FullName  + '\Tests\CatalogItems\testResources'
            Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath
            $rsReportPath = $folderPath + '/' + $reportName
            $uploadedReport = (Get-RsFolderContent -RsFolder / -Recurse ) | Where-Object path -eq $rsReportPath

            $uploadedReport.path | Should Be $rsReportPath
            
            # Removing folders used for testing
            Remove-RsCatalogItem -RsFolder $folderPath
        }

        It "Should upload a local database in Report Server" {

            $folderName = 'SutWriteRsFolderContentReportMin' + [guid]::NewGuid()
            New-RsFolder -Path / -FolderName $folderName
            $folderPath = '/' + $folderName
            $localReportPath =   (Get-Item -Path ".\" -Verbose).FullName  + '\Tests\CatalogItems\testResources'
            Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath
            $rsReportPath = $folderPath + '/' + $reportName
            $uploadedReport = (Get-RsFolderContent -RsFolder / -Recurse ) | Where-Object path -eq $rsReportPath

            $uploadedReport.path | Should Be $rsReportPath
            
            # Removing folders used for testing
            Remove-RsCatalogItem -RsFolder $folderPath
        }
        
        #Remove-Item $localPathFolder
    }

    Context "Write-RsFolderContent with ReportServerUri parameter"{
        $folderName = 'SutWriteRsFolderContentReportMin' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\" -Verbose).FullName  + '\Tests\CatalogItems\testResources'
        $reportServerUri = 'http://localhost/reportserver'
        Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath -ReportServerUri $reportServerUri
        $rsReportPath = $folderPath + '/' + $reportName
        $uploadedReport = (Get-RsFolderContent -RsFolder / -Recurse ) | Where-Object path -eq $rsReportPath
        It "Should upload a local report in Report Server with ReportServerUri Parameter" {
            $uploadedReport.path | Should Be $rsReportPath
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath
    }

    Context "Write-RsFolderContent with Proxy Parameter"{
        $folderName = 'SutWriteRsFolderContentReportMin' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\" -Verbose).FullName  + '\Tests\CatalogItems\testResources'
        $proxy = New-RsWebServiceProxy 
        Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath -Proxy $proxy
        $rsReportPath = $folderPath + '/' + $reportName
        $uploadedReport = (Get-RsFolderContent -RsFolder / -Recurse ) | Where-Object path -eq $rsReportPath
        It "Should upload a local report in Report Server with Proxy Parameter" {
            $uploadedReport.path | Should Be $rsReportPath
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath
    }

    Context "Write-RsFolderContent with Proxy and ReportServerUri"{
        $folderName = 'SutWriteRsFolderContentReportMin' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\" -Verbose).FullName  + '\Tests\CatalogItems\testResources'
        $proxy = New-RsWebServiceProxy 
        $reportServerUri = 'http://localhost/reportserver'
        Write-RsFolderContent -Path $localReportPath -RsFolder $folderPath -Proxy $proxy -ReportServerUri $reportServerUri
        $rsReportPath = $folderPath + '/' + $reportName
        $uploadedReport = (Get-RsFolderContent -RsFolder / -Recurse ) | Where-Object path -eq $rsReportPath
        It "Should upload a local report in Report Server with ReportServer and Proxy Uri" {
            $uploadedReport.path | Should Be $rsReportPath
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath
    }
}
