function Get-TestUser() {
    if (-not $env:RsUser) {
        throw 'Environment variable RsUser is not defined!'
    }
    return $env:RsUser
}

function Get-RsCatalogItemPolicies()
{
    param(
        [Parameter(Mandatory = $True)]
        [string]$Path
    )

    $inheritsParentProperties = $false
    $rsProxy = New-RsWebServiceProxy
    return $rsProxy.GetPolicies($Path, [ref] $inheritsParentProperties)
}

Describe "Grant and Revoke Access On RS Catalog Items" {
    $user = Get-TestUser

    Context "Granting permission on catalog item to test user" {
        $catalogItemPath = '/'

        It "Should assign Browser access to test user" {
            $role = 'Browser'
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $policies = Get-RsCatalogItemPolicies -Path $catalogItemPath
            
            $userPolicy = $policies | Where-Object { $_.GroupUserName -eq $user }
            $userPolicy | Should Not BeNullOrEmpty
            
            $userPolicy.Roles.Length | Should Be 1
            $role = $userPolicy.Roles | Where-Object { $_.Name -eq $role }
            $role | Should Not BeNullOrEmpty
        }

        It "Should assign Content Manager access to test user" {
            $role = 'Content Manager'
            Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

            $policies = Get-RsCatalogItemPolicies -Path $catalogItemPath
            
            $userPolicy = $policies | Where-Object { $_.GroupUserName -eq $user }
            $userPolicy | Should Not BeNullOrEmpty
            
            $userPolicy.Roles.Length | Should Be 1
            $role = $userPolicy.Roles | Where-Object { $_.Name -eq $role }
            $role | Should Not BeNullOrEmpty
        }

        AfterEach {
            Revoke-AccessOnCatalogItem -UserOrGroupName $user -Path $catalogItemPath -Confirm:$false -Verbose
        }
    }

    Context "Revoking access from test user" {
        $catalogItemPath = '/'
        $role = 'Content Manager'
        Grant-AccessOnCatalogItem -UserOrGroupName $user -RoleName $role -Path $catalogItemPath -Confirm:$false -Verbose

        It "Should revoke all access from test user" {
            Revoke-AccessOnCatalogItem -UserOrGroupName $user -Path $catalogItemPath -Confirm:$false -Verbose

            $policies = Get-RsCatalogItemPolicies -Path $catalogItemPath
            
            $userPolicy = $policies | Where-Object { $_.GroupUserName -eq $user }
            $userPolicy | Should BeNullOrEmpty
        }
    }
}