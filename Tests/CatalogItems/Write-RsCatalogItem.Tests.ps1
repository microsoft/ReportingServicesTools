# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Write-RsCatalogItem" {

    Context "Write-RsCatalogItem with min parameters"{
        $folderName = 'SutWriteRsCatalogItem_MinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'

        It "Should upload a local report in Report Server" {
            $localReportPath = $localPath + '\emptyReport.rdl'
            Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Description 'newDescription'
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
            $uploadedReport.Description | Should Be 'newDescription'
        }

        It "Should upload a local RsDataSource in Report Server" {
            $localDataSourcePath = $localPath + '\SutWriteRsFolderContent_DataSource.rsds'
            Write-RsCatalogItem -Path $localDataSourcePath -RsFolder $folderPath
            $uploadedDataSource = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSource'
            $uploadedDataSource.Name | Should Be 'SutWriteRsFolderContent_DataSource'
        }

        It "Should upload a local DataSet in Report Server" {
            $localDataSetPath = $localPath + '\UnDataset.rsd'
            Write-RsCatalogItem -Path $localDataSetPath -RsFolder $folderPath
            $uploadedDataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
            $uploadedDataSet.Name | Should Be 'UnDataset'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsCatalogItem with hidden parameters"{
        $folderName = 'SutWriteRsCatalogItem_Hidden' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName -Hidden
        $folderPath = '/' + $folderName
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'

        It "Should upload a local report in Report Server" {
            $localReportPath = $localPath + '\emptyReport.rdl'
            Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Description 'newDescription' -Hidden
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
            $uploadedReport.Description | Should Be 'newDescription'
            $uploadedReport.Hidden | Should -BeTrue
        }

        It "Should upload a local RsDataSource in Report Server" {
            $localDataSourcePath = $localPath + '\SutWriteRsFolderContent_DataSource.rsds'
            Write-RsCatalogItem -Path $localDataSourcePath -RsFolder $folderPath -Hidden
            $uploadedDataSource = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSource'
            $uploadedDataSource.Name | Should Be 'SutWriteRsFolderContent_DataSource'
            $uploadedDataSource.Hidden | Should -BeTrue
        }

        It "Should upload a local DataSet in Report Server" {
            $localDataSetPath = $localPath + '\UnDataset.rsd'
            Write-RsCatalogItem -Path $localDataSetPath -RsFolder $folderPath -Hidden
            $uploadedDataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
            $uploadedDataSet.Name | Should Be 'UnDataset'
            $uploadedDataSet.Hidden | Should -BeTrue
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsCatalogItem with name parameter"{
        $folderName = 'SutWriteRsCatalogItem_Name' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName -Hidden
        $folderPath = '/' + $folderName
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'

        It "Should upload a local report in Report Server" {
            $localReportPath = $localPath + '\emptyReport.rdl'
            Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Description 'newDescription' -Name 'Test Report'
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'Test Report'
            $uploadedReport.Description | Should Be 'newDescription'
        }

        It "Should upload a local RsDataSource in Report Server" {
            $localDataSourcePath = $localPath + '\SutWriteRsFolderContent_DataSource.rsds'
            Write-RsCatalogItem -Path $localDataSourcePath -RsFolder $folderPath -Name 'Test DataSource'
            $uploadedDataSource = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSource'
            $uploadedDataSource.Name | Should Be 'Test DataSource'
        }

        It "Should upload a local DataSet in Report Server" {
            $localDataSetPath = $localPath + '\UnDataset.rsd'
            Write-RsCatalogItem -Path $localDataSetPath -RsFolder $folderPath -Name 'Test DataSet'
            $uploadedDataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
            $uploadedDataSet.Name | Should Be 'Test DataSet'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsCatalogItem with Proxy parameter"{
        $folderName = 'SutWriteRsCatalogItem_ProxyParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $proxy = New-RsWebServiceProxy
        $localReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
        Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Proxy $proxy -Description 'newDescription'

        It "Should upload a local Report in ReportServer with Proxy Parameter" {
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
            $uploadedReport.Description | Should Be 'newDescription'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsCatalogItem with Proxy and ReportServerUri parameter"{
        $folderName = 'SutWriteRsCatalogItem_ReporServerUrioProxyParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $proxy = New-RsWebServiceProxy
        $reportServerUri = 'http://localhost/reportserver'
        $localReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
        Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Proxy $proxy -ReportServerUri $reportServerUri -Description 'newDescription'

        It "Should upload a local Report in ReportServer with Proxy and ReportServerUri Parameter" {
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
            $uploadedReport.Description | Should Be 'newDescription'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

     Context "Write-RsCatalogItem with ReportServerUri parameter"{
        $folderName = 'SutWriteRsCatalogItem_ReportServerUriParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $reportServerUri = 'http://localhost/reportserver'
        $localReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
        Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -ReportServerUri $reportServerUri -Description 'newDescription'

        It "Should upload a local Report in ReportServer with ReportServerUri Parameter" {
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
            $uploadedReport.Description | Should Be 'newDescription'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsCatalogItem with Overwrite parameter"{
        $folderName = 'SutWriteCatalogItem_OverwriteParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
        Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Description 'newDescription'
        $localDataSourcePath =  (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\SutWriteRsFolderContent_DataSource.rsds'

        It "Should upload a local Report in ReportServer with Overwrite Parameter" {
            { Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath } | Should Throw
            { Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Overwrite -Description 'overwrittenDescription' } | Should Not Throw
            $overwrittenReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $overwrittenReport.Name | Should Be 'emptyReport'
            $overwrittenReport.Description | Should Be 'overwrittenDescription'
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }


    Context "Write-RsCatalogItem with images"{
        $jpgFolderName = 'SutWriteCatalogItem_JPGimages' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $jpgFolderName
        $jpgFolderPath = '/' + $jpgFolderName
        $localJPGImagePath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\imagesResources\PowerShellHero.jpg'
        Write-RsCatalogItem -Path $localJPGImagePath -RsFolder $jpgFolderPath

        It "Should upload a local jpg image in ReportServer" {
            $jpgImageResource = (Get-RsFolderContent -RsFolder $jpgFolderPath ) | Where-Object TypeName -eq 'Resource'
            $jpgImageResource.Name | Should Be 'PowerShellHero.jpg'
            $jpgImageResource.ItemMetadata.Name | Should Be 'MIMEType'
            $jpgImageResource.ItemMetadata.Value | Should Be 'image/jpeg'
        }

        $pngFolderName = 'SutWriteCatalogItem_PNGimages' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $pngFolderName
        $pngFolderPath = '/' + $pngFolderName
        $localPNGImagePath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\imagesResources\SSRS.png'
        Write-RsCatalogItem -Path $localPNGImagePath -RsFolder $pngFolderPath

        It "Should upload a local png image in ReportServer" {
            $jpgImageResource = (Get-RsFolderContent -RsFolder $pngFolderPath ) | Where-Object TypeName -eq 'Resource'
            $jpgImageResource.Name | Should Be 'SSRS.png'
            $jpgImageResource.ItemMetadata.Name | Should Be 'MIMEType'
            $jpgImageResource.ItemMetadata.Value | Should Be 'image/png'
        }

        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $jpgFolderPath -Confirm:$false
        Remove-RsCatalogItem -RsFolder $pngFolderPath -Confirm:$false
    }

    Context "Write-RsCatalogItem with additional resource types"{
        $resourceFolderName = 'SutWriteCatalogItem_AdditionalResources' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $resourceFolderName
        $resourceFolderPath = '/' + $resourceFolderName
        $localResourceFolder = Join-Path ([System.IO.Path]::GetTempPath()) ('SutWriteCatalogItem_AdditionalResources' + [guid]::NewGuid())
        New-Item -Path $localResourceFolder -ItemType Directory | Out-Null
        [System.IO.File]::WriteAllBytes((Join-Path $localResourceFolder 'Pixel.gif'), [System.Convert]::FromBase64String('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'))
        [System.IO.File]::WriteAllBytes((Join-Path $localResourceFolder 'Pixel.bmp'), [System.Convert]::FromBase64String('Qk06AAAAAAAAADYAAAAoAAAAAQAAAAEAAAABABgAAAAAAAQAAAATCwAAEwsAAAAAAAAAAAAA////AA=='))
        [System.IO.File]::WriteAllText((Join-Path $localResourceFolder 'Document.pdf'), "%PDF-1.4`n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj`n2 0 obj<</Type/Pages/Kids[]/Count 0>>endobj`ntrailer<</Root 1 0 R>>`n%%EOF`n")
        $testResourcesPath = (Get-Item -Path ".\").FullName + '\Tests\CatalogItems\testResources'

        $expectedResources = @(
            @{ Path = (Join-Path $localResourceFolder 'Pixel.gif'); Name = 'Pixel.gif'; MimeType = @('image/gif') },
            @{ Path = (Join-Path $localResourceFolder 'Pixel.bmp'); Name = 'Pixel.bmp'; MimeType = @('image/bmp') },
            # Some report server versions store PDF resources as application/octet-stream regardless of the MIME type sent.
            @{ Path = (Join-Path $localResourceFolder 'Document.pdf'); Name = 'Document.pdf'; MimeType = @('application/pdf', 'application/octet-stream') },
            @{ Path = (Join-Path $testResourcesPath 'NewExcelWorkbook.xlsx'); Name = 'NewExcelWorkbook.xlsx'; MimeType = @('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') },
            @{ Path = (Join-Path $testResourcesPath 'OldExcelWorkbook.xls'); Name = 'OldExcelWorkbook.xls'; MimeType = @('application/vnd.ms-excel') }
        )
        foreach ($expectedResource in $expectedResources)
        {
            Write-RsCatalogItem -Path $expectedResource.Path -RsFolder $resourceFolderPath
        }
        $uploadedResources = Get-RsFolderContent -RsFolder $resourceFolderPath | Where-Object TypeName -eq 'Resource'

        foreach ($expectedResource in $expectedResources)
        {
            It "Should upload $($expectedResource.Name) as a resource with MIME type $($expectedResource.MimeType -join ' or ')" {
                $uploadedResource = $uploadedResources | Where-Object Name -eq $expectedResource.Name
                $uploadedResource.Name | Should Be $expectedResource.Name
                ($uploadedResource.ItemMetadata | Where-Object Name -eq 'MIMEType').Value | Should -BeIn $expectedResource.MimeType
            }
        }

        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $resourceFolderPath -Confirm:$false
        Remove-Item -Path $localResourceFolder -Recurse -Force
    }
}
