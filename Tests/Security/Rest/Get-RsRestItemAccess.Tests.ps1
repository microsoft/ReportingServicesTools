# Copyright (c) 2020 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-TestUser() {
    if (-not $env:RsUser) {
        throw 'Environment variable RsUser is not defined!'
    }
    return $env:RsUser
}

Describe "Get-RsRestItemAccess" { 
    $user = Get-TestUser
    $reportServerUri = 'http://localhost/reportserver'
    $ReportPortalUri = 'http://localhost/reports'
    $catalogItemPath = '/'

    Context "Get Catalog Item Policy"{

        It "Should retrieve Browser permission access" {
            $role = 'Browser'

            # Grant Access
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $catalogItemPolicy = Get-RsRestItemAccess -Path $catalogItemPath
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        It "Should retrieve Content Manager permission access" {
            $role = 'Content Manager'

            # Grant Access
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $catalogItemPolicy = Get-RsRestItemAccess -Path $catalogItemPath
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        AfterEach {
            Revoke-AccessOnCatalogItem -UserOrGroupName $user -Path $catalogItemPath -Confirm:$false -Verbose
        }
    }

    Context "Get Catalog Item Policy with Identity"{
        It "Should retrieve Browser permission access for test user" {
            $role = 'Browser'

            # Grant Access
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $catalogItemPolicy = Get-RsRestItemAccess -Path $catalogItemPath -Identity $user
            $catalogItemPolicyCount = @($catalogItemPolicy).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        It "Should retrieve Content Manager permission access for test user" {
            $role = 'Content Manager'

            # Grant Access
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $catalogItemPolicy = Get-RsRestItemAccess -Path $catalogItemPath -Identity $user
            $catalogItemPolicyCount = @($catalogItemPolicy).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        AfterEach {
            Revoke-AccessOnCatalogItem -UserOrGroupName $user -Path $catalogItemPath -Confirm:$false -Verbose
        }
    }

    Context "Get Catalog Item Policy with ReportServerUri parameter"{

        It "Should retrieve Browser permission access" {
            $role = 'Browser'

            # Grant Access
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $catalogItemPolicy = Get-RsRestItemAccess -Path $catalogItemPath -ReportPortalUri $ReportPortalUri
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        It "Should retrieve Content Manager permission access" {
            $role = 'Content Manager'

            # Grant Access
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $catalogItemPolicy = Get-RsRestItemAccess -Path $catalogItemPath -ReportPortalUri $ReportPortalUri
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        AfterEach {
            Revoke-AccessOnCatalogItem -UserOrGroupName $user -Path $catalogItemPath -Confirm:$false -Verbose
        }
    }

}