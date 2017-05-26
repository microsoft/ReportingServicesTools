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
        $proxy = New-RsWebServiceProxy
        $reportDataSetReference = $proxy.GetItemReferences($report.path, "DataSet")
        $reportDataSetReferencePath =  $reportDataSetReference.Reference
        Set-RsDataSetReference -Path $report.path -DataSetName  $reportDataSetReference.Name -DataSetPath $dataSet.path

        It "Should be a new data source" {
            $newReportDataSetReference = $proxy.GetItemReferences($report.path, "DataSet")
            $newReportDataSetReferencePath =  $newReportDataSetReference.Reference
            $reportDataSetReferencePath | Should Not Be $newReportDataSetReferencePath 
            $newReportDataSetReferencePath | Should Be $dataSet.Path 
        }
    }

     Context "Set-RsDatsSetReference with Proxy Parameter"{
        $folderName = 'SutSetRsDataSetReferenceMinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localResourcesPath -RsFolder $folderPath
        $report = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
        $dataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
        $proxy = New-RsWebServiceProxy
        $reportDataSetReference = $proxy.GetItemReferences($report.path, "DataSet")
        $reportDataSetReferencePath =  $reportDataSetReference.Reference
        Set-RsDataSetReference -Path $report.path -DataSetName  $reportDataSetReference.Name -DataSetPath $dataSet.path -Proxy $proxy

        It "Should be a new data source" {
            $newReportDataSetReference = $proxy.GetItemReferences($report.path, "DataSet")
            $newReportDataSetReferencePath =  $newReportDataSetReference.Reference
            $reportDataSetReferencePath | Should Not Be $newReportDataSetReferencePath 
            $newReportDataSetReferencePath | Should Be $dataSet.Path 
        }
    }

     Context "Set-RsDatsSetReference with Report Server Parameter"{
        $folderName = 'SutSetRsDataSetReferenceMinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localResourcesPath -RsFolder $folderPath
        $report = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
        $dataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
        $proxy = New-RsWebServiceProxy
        $reportServerUri = 'http://localhost/reportserver'
        $reportDataSetReference = $proxy.GetItemReferences($report.path, "DataSet")
        $reportDataSetReferencePath =  $reportDataSetReference.Reference
        Set-RsDataSetReference -Path $report.path -DataSetName  $reportDataSetReference.Name -DataSetPath $dataSet.path -ReportServerUri $reportServerUri
        
        It "Should be a new data source" {
            $newReportDataSetReference = $proxy.GetItemReferences($report.path, "DataSet")
            $newReportDataSetReferencePath =  $newReportDataSetReference.Reference
            $reportDataSetReferencePath | Should Not Be $newReportDataSetReferencePath 
            $newReportDataSetReferencePath | Should Be $dataSet.Path 
        }
    }

     Context "Set-RsDatsSetReference with ReportServerUri and Proxy parameters"{
        $folderName = 'SutSetRsDataSetReferenceMinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localResourcesPath -RsFolder $folderPath
        $report = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
        $dataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
        $proxy = New-RsWebServiceProxy
        $reportServerUri = 'http://localhost/reportserver'
        $reportDataSetReference = $proxy.GetItemReferences($report.path, "DataSet")
        $reportDataSetReferencePath =  $reportDataSetReference.Reference
        Set-RsDataSetReference -Path $report.path -DataSetName  $reportDataSetReference.Name -DataSetPath $dataSet.path -ReportServerUri $reportServerUri -Proxy $proxy
       
        It "Should be a new data source" {
            $newReportDataSetReference = $proxy.GetItemReferences($report.path, "DataSet")
            $newReportDataSetReferencePath =  $newReportDataSetReference.Reference
            $reportDataSetReferencePath | Should Not Be $newReportDataSetReferencePath 
            $newReportDataSetReferencePath | Should Be $dataSet.Path 
        }
    }

}
