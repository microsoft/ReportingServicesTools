# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-TestUser() {
    if (-not $env:RsUser) {
        throw 'Environment variable RsUser is not defined!'
    }
    return $env:RsUser
}

Describe "Get-RsCatalogItemRole" { 
    $user = Get-TestUser
    $reportServerUri = 'http://localhost/reportserver'
    $catalogItemPath = '/'

    Context "Get Catalog Item Policy"{

        It "Should retrieve Browser permission access" {
            $role = 'Browser'

            # Grant Access
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $catalogItemPolicy = Get-RsCatalogItemRole -Path $catalogItemPath
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles.Name -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        It "Should retrieve Content Manager permission access" {
            $role = 'Content Manager'

            # Grant Access
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $catalogItemPolicy = Get-RsCatalogItemRole -Path $catalogItemPath 
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles.Name -eq $role}).Count
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

            $catalogItemPolicy = Get-RsCatalogItemRole -Path $catalogItemPath -Identity $user
            $catalogItemPolicyCount = @($catalogItemPolicy).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        It "Should retrieve Content Manager permission access for test user" {
            $role = 'Content Manager'

            # Grant Access
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $catalogItemPolicy = Get-RsCatalogItemRole -Path $catalogItemPath -Identity $user
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

            $catalogItemPolicy = Get-RsCatalogItemRole -Path $catalogItemPath -ReportServerUri $reportServerUri
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles.Name -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        It "Should retrieve Content Manager permission access" {
            $role = 'Content Manager'

            # Grant Access
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $catalogItemPolicy = Get-RsCatalogItemRole -Path $catalogItemPath -ReportServerUri $reportServerUri
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles.Name -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        AfterEach {
            Revoke-AccessOnCatalogItem -UserOrGroupName $user -Path $catalogItemPath -Confirm:$false -Verbose
        }
    }

    Context "Get Catalog Item Policy with proxy parameter"{

        It "Should retrieve Browser permission access" {
            $role = 'Browser'
            
            # Grant Access
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $proxy = New-RsWebServiceProxy 

            $catalogItemPolicy = Get-RsCatalogItemRole -proxy $proxy
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles.Name -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        It "Should retrieve Content Manager permission access" {
            $role = 'Content Manager'

            # Grant Access
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $proxy = New-RsWebServiceProxy 

            $catalogItemPolicy = Get-RsCatalogItemRole -proxy $proxy
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles.Name -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        AfterEach {
            Revoke-AccessOnCatalogItem -UserOrGroupName $user -Path $catalogItemPath -Confirm:$false -Verbose
        }
    }

    Context "Get Catalog Item Policy with proxy parameter and ReportServerUri"{

        It "Should retrieve Browser permission access" {
            $role = 'Browser'
            
            # Grant Access
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $proxy = New-RsWebServiceProxy 

            $catalogItemPolicy = Get-RsCatalogItemRole -proxy $proxy -ReportServerUri $reportServerUri
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles.Name -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        It "Should retrieve Content Manager permission access" {
            $role = 'Content Manager'

            # Grant Access
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $proxy = New-RsWebServiceProxy 

            $catalogItemPolicy = Get-RsCatalogItemRole -proxy $proxy -ReportServerUri $reportServerUri
            $catalogItemPolicyCount = @($catalogItemPolicy | Where-Object {$_.Identity -eq $user -and $_.Roles.Name -eq $role}).Count
            $catalogItemPolicyCount | Should BeGreaterThan 0
        }

        AfterEach {
            Revoke-AccessOnCatalogItem -UserOrGroupName $user -Path $catalogItemPath -Confirm:$false -Verbose
        }
    }

}