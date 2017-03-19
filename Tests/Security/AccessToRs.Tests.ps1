function Get-TestUser() {
    if (-not $env:RsUser) {
        throw 'Environment variable RsUser is not defined!'
    }
    return $env:RsUser
}

function Get-RsSystemPolicies() {
    $rsProxy = New-RsWebServiceProxy
    return $rsProxy.GetSystemPolicies()
}

Describe "Grant and Revoke Access To Rs" {
    $user = Get-TestUser

    Context "Granting permission to test user" {
        It "Should assign System User access to test user" {
            $role = 'System User'
            Grant-AccessToRs -UserOrGroupName $user -RoleName $role -Confirm:$false -Verbose

            $policies = Get-RsSystemPolicies
            
            $userPolicy = $policies | Where-Object { $_.GroupUserName -eq $user }
            $userPolicy | Should Not BeNullOrEmpty
            
            $userPolicy.Roles.Length | Should Be 1
            $role = $userPolicy.Roles | Where-Object { $_.Name -eq $role }
            $role | Should Not BeNullOrEmpty
        }

        It "Should assign System Administrator access to test user" {
            $role = 'System Administrator'
            Grant-AccessToRs -UserOrGroupName $user -RoleName $role -Confirm:$false -Verbose

            $policies = Get-RsSystemPolicies
            
            $userPolicy = $policies | Where-Object { $_.GroupUserName -eq $user }
            $userPolicy | Should Not BeNullOrEmpty
            
            $userPolicy.Roles.Length | Should Be 1
            $role = $userPolicy.Roles | Where-Object { $_.Name -eq $role }
            $role | Should Not BeNullOrEmpty
        }

        AfterEach {
            Revoke-AccessToRs -UserOrGroupName $user -Confirm:$false -Verbose
        }
    }

    Context "Revoking access from test user" {
        $role = 'System Administrator'
        Grant-AccessToRs -UserOrGroupName $user -RoleName $role -Confirm:$false -Verbose

        It "Should remove all access for test user" {
            Revoke-AccessToRs -UserOrGroupName $user -Confirm:$false -Verbose

            $policies = Get-RsSystemPolicies
            
            $userPolicy = $policies | Where-Object { $_.GroupUserName -eq $user }
            $userPolicy | Should BeNullOrEmpty
        }
    }
}