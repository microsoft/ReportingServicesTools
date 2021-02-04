# Copyright (c) 2021 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-TestUser() {
    if (-not $env:RsUser) {
        throw 'Environment variable RsUser is not defined!'
    }
    return $env:RsUser
}

Describe "Grant-RsRestItemAccessPolicy" { 
    $user = Get-TestUser
    $ReportPortalUri = 'http://localhost/Reports/'
    $catalogItemPath = '/'

    Context "Get Catalog Item Policy"{

        It "Should retrieve Browser permission access" {
            $role = 'Browser'

            # Grant Access
            Grant-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Identity $user -Role $role -Path $catalogItemPath -Verbose

            $catalogItemPolicy = Get-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Path $catalogItemPath
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        It "Should retrieve Content Manager permission access" {
            $role = 'Content Manager'

            # Grant Access
            Grant-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Identity $user -Role $role -Path $catalogItemPath -Verbose

            $catalogItemPolicy = Get-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Path $catalogItemPath
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        AfterEach {
            Revoke-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Identity $user -Path $catalogItemPath -Verbose
        }
    }

    Context "Get Catalog Item Policy"{

        BeforeEach {
            $session = New-RsRestSession -ReportPortalUri $reportPortalUri
    
            # creating test folder
            $folderName = 'SUT_RevokeRsRestItemAccessPolicy_' + [guid]::NewGuid()
            New-RsRestFolder -WebSession $session -RsFolder / -FolderName $folderName
            $rsFolderPath = '/' + $folderName
    
            # uploading test artifacts: datasourcesReport.rdl and SqlPowerBIReport.pbix
            $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
            Write-RsRestCatalogItem -WebSession $session -Path "$localPath\datasources\datasourcesReport.rdl" -RsFolder $rsFolderPath
            $datasourcesReport =  "$rsFolderPath/datasourcesReport"
        }

        It "Should retrieve Browser permission access" {
            $role = 'Browser'

            # Grant Access
            Grant-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Identity $user -Role $role -Path $datasourcesReport -Verbose

            $catalogItemPolicy = Get-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Path $datasourcesReport
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        It "Should retrieve Content Manager permission access" {
            $role = 'Content Manager'

            # Grant Access
            Grant-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Identity $user -Role $role -Path $datasourcesReport -Verbose

            $catalogItemPolicy = Get-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Path $datasourcesReport
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        AfterEach {
            Revoke-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Identity $user -Path $datasourcesReport -Verbose
        }
    }

        Context "Get Catalog Item Policy"{

            BeforeEach {
                $session = New-RsRestSession -ReportPortalUri $reportPortalUri
        
                # creating test folder
                $folderName = 'SUT_RevokeRsRestItemAccessPolicy_' + [guid]::NewGuid()
                New-RsRestFolder -WebSession $session -RsFolder / -FolderName $folderName
                $rsFolderPath = '/' + $folderName
        
                # uploading test artifacts: datasourcesReport.rdl and SqlPowerBIReport.pbix
                $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'
        
                Write-RsRestCatalogItem -WebSession $session -Path "$localPath\SqlPowerBIReport.pbix" -RsFolder $rsFolderPath
                $sqlPowerBIReport = "$rsFolderPath/SqlPowerBIReport"
            }
    
            It "Should retrieve Browser permission access" {
            $role = 'Browser'

            # Grant Access
            Grant-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Identity $user -Role $role -Path $sqlPowerBIReport -Verbose

            $catalogItemPolicy = Get-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Path $sqlPowerBIReport
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        It "Should retrieve Content Manager permission access" {
            $role = 'Content Manager'

            # Grant Access
            Grant-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Identity $user -Role $role -Path $sqlPowerBIReport -Verbose

            $catalogItemPolicy = Get-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Path $sqlPowerBIReport
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        AfterEach {
            Revoke-RsRestItemAccessPolicy -ReportPortalUri $ReportPortalUri -Identity $user -Path $sqlPowerBIReport -Verbose
        }
    }

}