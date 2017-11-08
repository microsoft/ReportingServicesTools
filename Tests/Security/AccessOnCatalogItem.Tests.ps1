function Get-TestUser() {
    if (-not $env:RsUser) {
        throw 'Environment variable RsUser is not defined!'
    }
    return $env:RsUser
}


Describe "Grant and Revoke Access On RS Catalog Items" {
    $user = Get-TestUser

    Context "Granting permission on catalog item to test user" {
        $catalogItemPath = '/'

        It "Should assign Browser access to test user" {
            $role = 'Browser'
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $policies = Get-RsCatalogItemRole -Path $catalogItemPath

            $userPolicy = $policies | Where-Object { $_.Identity -eq $user }
            $userPolicy | Should Not BeNullOrEmpty

            $userPolicy.Roles.Length | Should Be 1
            $role = $userPolicy.Roles | Where-Object { $_.Name -eq $role }
            $role | Should Not BeNullOrEmpty
        }

        It "Should assign Content Manager access to test user" {
            $role = 'Content Manager'
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $policies = Get-RsCatalogItemRole -Path $catalogItemPath

            $userPolicy = $policies | Where-Object { $_.Identity -eq $user }
            $userPolicy | Should Not BeNullOrEmpty

            $userPolicy.Roles.Length | Should Be 1
            $role = $userPolicy.Roles | Where-Object { $_.Name -eq $role }
            $role | Should Not BeNullOrEmpty
        }

        AfterEach {
            Revoke-AccessOnCatalogItem -UserOrGroupName $user -Path $catalogItemPath -Confirm:$false -Verbose
        }
    }

    Context "Granting more than one permission on catalog item to test user" {
        $catalogItemPath = '/'

        It "Should assign Browser access to test user" {
            $role = 'Browser'
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $policies = Get-RsCatalogItemRole -Path $catalogItemPath

            $userPolicy = $policies | Where-Object { $_.Identity -eq $user }
            $userPolicy | Should Not BeNullOrEmpty

            $userPolicy.Roles.Length | Should Be 1
            $role = $userPolicy.Roles | Where-Object { $_.Name -eq $role }
            $role | Should Not BeNullOrEmpty
        }

        It "Should add Content Manager and keep Browser access to test user" {
            $role = 'Content Manager'
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $policies = Get-RsCatalogItemRole -Path $catalogItemPath

            $userPolicy = $policies | Where-Object { $_.Identity -eq $user }
            $userPolicy | Should Not BeNullOrEmpty

            $userPolicy.Roles.Length | Should Be 2
            $role = $userPolicy.Roles | Where-Object { $_.Name -eq $role }
            $role | Should Not BeNullOrEmpty
        }

        Revoke-AccessOnCatalogItem -UserOrGroupName $user -Path $catalogItemPath -Confirm:$false -Verbose
    }

    Context "Revoking access from test user" {
        $catalogItemPath = '/'
        $role = 'Content Manager'
        Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

        It "Should revoke all access from test user" {
            Revoke-AccessOnCatalogItem -UserOrGroupName $user -Path $catalogItemPath -Confirm:$false -Verbose

            $policies = Get-RsCatalogItemRole -Path $catalogItemPath

            $userPolicy = $policies | Where-Object { $_.Identity -eq $user }
            $userPolicy | Should BeNullOrEmpty
        }
    }
}