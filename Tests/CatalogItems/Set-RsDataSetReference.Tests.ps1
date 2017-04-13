# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Function Get-ExistingDataExtension
{
        $proxy = New-RsWebServiceProxy
        return $proxy.ListExtensions("Data")[0].Name
}

Describe "Set-RsDatsSetReference" {
    Context "Set-RsDatsSetReference with minimun parameters"{
        $folderName = 'SutOutRsCatalogItemMinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        Write-RsFolderContent -Path $localResourcesPath -RsFolder $folderPath
        $report = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
        $dataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
        Set-RsDataSetReference -Path $report.path -DataSetName $dataSet.Name -DataSetPath $dataSet.path

        It "Should be a new data source" {
        }
        # Removing folders used for testing
        #Remove-RsCatalogItem -RsFolder $folderPath
    }
}

PS C:\>Set-RsDataSetReference -ReportServerUri 'http://localhost/reportserver_sql2012' -Path
/ReportWithDSReference -DataSetName Dataset1 -DataSetPath /Datasets/SampleSet

Exception calling "SetItemReferences" with "2" argument(s): "System.Web.Services.Protocols.SoapException: The dataset
'UnDataset' cannot be found. ---> Microsoft.ReportingServices.Diagnostics.Utilities.DataSetNotFoundException: The
dataset 'UnDataset' cannot be found.
   at Microsoft.ReportingServices.Library.ReportingService2010Impl.SetItemReferences(String ItemPath, ItemReference[]
ItemReferences)
   at Microsoft.ReportingServices.WebServer.ReportingService2010.SetItemReferences(String ItemPath, ItemReference[]
ItemReferences)"
At C:\kitsune\ReportingServicesTools\Functions\CatalogItems\Set-RsDataSetReference.ps1:103 char:17
+                 $Proxy.SetItemReferences($item, @($dataSetReference))
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
    + FullyQualifiedErrorId : SoapException
