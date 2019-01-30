# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


Describe "Set-RsDatsSetReference" {
    Context "Set-RsDatsSetReference with minimun parameters"{
        $folderName = 'SutSetRsDataSetReferenceMinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localResourcesPath -RsFolder $folderPath
        $report = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
        $dataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
        $reportDataSetReference = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSet'
        $reportDataSetReferencePath =  $reportDataSetReference.Reference
        Set-RsDataSetReference -Path $report.path -DataSetName  $reportDataSetReference.Name -DataSetPath $dataSet.path

        It "Should set a RsDataSet reference" {
            $newReportDataSetReference = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSet'
            $newReportDataSetReferencePath =  $newReportDataSetReference.Reference
            $reportDataSetReferencePath | Should Not Be $newReportDataSetReferencePath 
            $newReportDataSetReferencePath | Should Be $dataSet.Path 
        }
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

     Context "Set-RsDatsSetReference with Proxy Parameter"{
        $folderName = 'SutSetRsDataSetReferenceMinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localResourcesPath -RsFolder $folderPath
        $report = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
        $dataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
        $reportDataSetReference = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSet'
        $reportDataSetReferencePath =  $reportDataSetReference.Reference
        $proxy = New-RsWebServiceProxy 
        Set-RsDataSetReference -Path $report.path -DataSetName  $reportDataSetReference.Name -DataSetPath $dataSet.path -Proxy $proxy

        It "Should set a RsDataSet reference" {
            $newReportDataSetReference = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSet'
            $newReportDataSetReferencePath =  $newReportDataSetReference.Reference
            $reportDataSetReferencePath | Should Not Be $newReportDataSetReferencePath 
            $newReportDataSetReferencePath | Should Be $dataSet.Path 
        }
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

     Context "Set-RsDatsSetReference with Report Server Parameter"{
        $folderName = 'SutSetRsDataSetReferenceMinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localResourcesPath -RsFolder $folderPath
        $report = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
        $dataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
        $reportDataSetReference = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSet'
        $reportServerUri = 'http://localhost/reportserver'
        $reportDataSetReferencePath =  $reportDataSetReference.Reference
        Set-RsDataSetReference -Path $report.path -DataSetName  $reportDataSetReference.Name -DataSetPath $dataSet.path -ReportServerUri $reportServerUri
        
        It "Should set a RsDataSet referencee" {
            $newReportDataSetReference = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSet'
            $newReportDataSetReferencePath =  $newReportDataSetReference.Reference
            $reportDataSetReferencePath | Should Not Be $newReportDataSetReferencePath 
            $newReportDataSetReferencePath | Should Be $dataSet.Path 
        }
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

     Context "Set-RsDatsSetReference with ReportServerUri and Proxy parameters"{
        $folderName = 'SutSetRsDataSetReferenceMinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localResourcesPath -RsFolder $folderPath
        $report = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
        $dataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
        $reportDataSetReference = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSet'
        $reportServerUri = 'http://localhost/reportserver'
        $proxy = New-RsWebServiceProxy 
        $reportDataSetReferencePath =  $reportDataSetReference.Reference
        Set-RsDataSetReference -Path $report.path -DataSetName  $reportDataSetReference.Name -DataSetPath $dataSet.path -ReportServerUri $reportServerUri -Proxy $proxy
       
        It "Should set a RsDataSet reference" {
            $newReportDataSetReference = Get-RsItemReference -Path $report.Path | Where-Object ReferenceType -eq 'DataSet'
            $newReportDataSetReferencePath =  $newReportDataSetReference.Reference
            $reportDataSetReferencePath | Should Not Be $newReportDataSetReferencePath 
            $newReportDataSetReferencePath | Should Be $dataSet.Path 
        }
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

}
