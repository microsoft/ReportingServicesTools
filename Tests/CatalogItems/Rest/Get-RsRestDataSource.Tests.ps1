# Copyright (c) 2023 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = if ($null -eq $env:PesterPortalUrl) { 'http://localhost/reports' } else { $env:PesterPortalUrl }

Describe "Get-RsRestDataSource" {
    BeforeAll {
        $folderName = 'SutGetRsRestDataSource_' + [guid]::NewGuid()
        $dsName = 'SutWriteRsFolderContent_DataSource'
        $dsPath = "/$folderName/$dsName"
        $localPath = (Get-Item -Path ".\").FullName + '\Tests\CatalogItems\testResources'
        $dsLocalPath = $localPath + "\$dsName.rsds"
        New-RsRestFolder -ReportPortalUri $reportPortalUri -RsFolder '/' -Name $folderName
        Write-RsRestCatalogItem -ReportPortalUri $reportPortalUri -Path $dsLocalPath -RsFolder "/$folderName" -Overwrite
    }
    AfterAll {
        Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $dsPath -Confirm:$false
        Remove-RsRestFolder -ReportPortalUri $reportPortalUri -RsFolder "/$folderName" -Confirm:$false
    }

    Context "Datasource exists" {
        It "Should retrieve a datasource" {
            $ds = Get-RsRestDataSource -ReportPortalUri $reportPortalUri -RsItem $dsPath
            $ds.Name | Should -Be $dsName
            $ds.Type | Should -Be 'DataSource'
            $ds.ConnectionString | Should -Not -BeNullOrEmpty
        }
    }
    Context "Datasource does not exist" {
        It "Should throw" {
            $result = { Get-RsRestDataSource -ReportPortalUri $reportPortalUri -RsItem '/missing' } | Should -Throw -ExpectedMessage '/missing' -Because 'the invalid path was "/missing"' -PassThru
            $result.Exception.Message | Should -BeLike '*/missing*'
        }
    }
}