# Copyright (c) 2020 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Get-RsRestPublicServerSetting" {
    Context "Get Catalog Item Policy"{
        $reportPortalUri = if ($env:PesterPortalUrl -eq $null) { 'http://localhost/reports' } else { $env:PesterPortalUrl }

        It "Should get MaxFileSizeMb property" {
            $property = Get-RsRestPublicServerSetting -ReportPortalUri $reportPortalUri -Property "MaxFileSizeMb"
            $property | Should -Not -BeNullOrEmpty
            $property | Should -Be '1000'
        }

        It "Should get ShowDownloadMenu property" {
            $property = Get-RsRestPublicServerSetting -ReportPortalUri $reportPortalUri -Property "ShowDownloadMenu" 
            $property | Should -Not -BeNullOrEmpty
            $property | Should -Be 'true'
        }

        It "Should not get BadRandomProperty property" {
            Get-RsRestPublicServerSetting -ReportPortalUri $reportPortalUri -Property "BadRandomProperty" | Should -BeNullOrEmpty
        }
    }
}
