# Copyright (c) 2017 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = if ($env:PesterPortalUrl -eq $null) { 'http://localhost/reports' } else { $env:PesterPortalUrl }

Describe "Set-RsRestItemDataModelParameters" {
    $session = $null
    $rsFolderPath = ""
    $sqlPowerBIReport = ""

    BeforeEach {
        $session = New-RsRestSession -ReportPortalUri $reportPortalUri

        # creating test folder
        $folderName = 'SUT_SetRsRestItemDataModelParameters_' + [guid]::NewGuid()
        New-RsRestFolder -WebSession $session -RsFolder / -FolderName $folderName
        $rsFolderPath = '/' + $folderName

        # uploading test artifacts: dataModelParametersReport.rdl and DataModelParameters.pbix
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'

        Write-RsRestCatalogItem -WebSession $session -Path "$localPath\DataModelParameters.pbix" -RsFolder $rsFolderPath
        $sqlPowerBIReport = "$rsFolderPath/DataModelParameters"
    }

    AfterEach {
        # deleting test folder
        Remove-RsRestFolder -WebSession $session -RsFolder $rsFolderPath -Confirm:$false
    }

    Context "ReportPortalUri parameter" {
        It "fetches data sources for power bi reports" {
            $dataModelParameters = Get-RsRestItemDataModelParameters -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport -Verbose            
            $dataModelParameters[0].Value = "NewValue"

            Set-RsRestItemDataModelParameters -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport -DataModelParameters $dataModelParameters -Verbose

            $dataModelParameters = Get-RsRestItemDataModelParameters -ReportPortalUri $reportPortalUri -RsItem $sqlPowerBIReport -Verbose            
            $dataModelParameters[0].Value | Should Be "NewValue"            
        }
    }

    Context "WebSession parameter" {
        $rsSession = $null

        BeforeEach {
            $rsSession = New-RsRestSession -ReportPortalUri $reportPortalUri
        }

        It "fetches data sources for power bi reports" {
            $dataModelParameters = Get-RsRestItemDataModelParameters -WebSession $rsSession -RsItem $sqlPowerBIReport -Verbose
            $dataModelParameters[0].Value = "NewValue"

            Set-RsRestItemDataModelParameters -WebSession $rsSession -RsItem $sqlPowerBIReport -DataModelParameters $dataModelParameters -Verbose

            $dataModelParameters = Get-RsRestItemDataModelParameters -WebSession $rsSession -RsItem $sqlPowerBIReport -Verbose            
            $dataModelParameters[0].Value | Should Be "NewValue" 
        }
    }
}