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
    Context "Granting System User permission to test user" {
        $user = Get-TestUser
        Grant-AccessToRs -UserOrGroupName $user -RoleName 'System User' -Verbose

        It "Should assign System User access to test user" {
            $policies = Get-RsSystemPolicies
            
            $userPolicy = $policies | Where-Object { $_.GroupUserName -eq $user }
            $userPolicy | Should Not BeNullOrEmpty
            
            $role = $userPolicy.Roles | Where-Object { $_.Name -eq 'System User' }
            $role | Should Not BeNullOrEmpty
        }
    }

    Context "Revoking all access to test user" {
        $user = Get-TestUser
        Revoke-AccessToRs -UserOrGroupName $user -Verbose
    
        It "Should remove all access for test user" {
            $policies = Get-RsSystemPolicies
            
            $userPolicy = $policies | Where-Object { $_.GroupUserName -eq $user }
            $userPolicy | Should BeNullOrEmpty
        }
    }

    Context "Granting System Administrator permission to test user" {
        $user = Get-TestUser
        Grant-AccessToRs -UserOrGroupName $user -RoleName 'System Administrator' -Verbose

        It "Should assign System Administrator access to test user" {
            $policies = Get-RsSystemPolicies
            
            $userPolicy = $policies | Where-Object { $_.GroupUserName -eq $user }
            $userPolicy | Should Not BeNullOrEmpty
            
            $role = $userPolicy.Roles | Where-Object { $_.Name -eq 'System Administrator' }
            $role | Should Not BeNullOrEmpty
        }
    }
}