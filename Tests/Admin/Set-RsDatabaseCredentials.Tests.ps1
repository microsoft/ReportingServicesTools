function Get-CredentialType() {
    $wmiObject = New-RsConfigurationSettingObject -SqlServerInstance MSSQLSERVER
    return Get-DatabaseCredentialType -DatabaseLogonType $wmiObject.DatabaseLogonType
}

function Get-SaCredentials() {
    if (-not $env:SqlSaPwd) {
        throw 'Environment variable SqlSaPwd is not defined!'
    }
    $password = ConvertTo-SecureString -AsPlainText -Force $env:SqlSaPwd
    return New-Object System.Management.Automation.PSCredential('sa', $password)
}

Describe "Set-RsDatabaseCredentials" {
    Context "Changing database credential type to ServiceAccount credentials" {
        $credentialType = 'SQL'
        $credential = Get-SaCredentials
        Set-RsDatabaseCredentials -DatabaseCredentialType $credentialType -DatabaseCredential $credential -Verbose
        
        It "Should update credentials" {
            Get-CredentialType | Should be $credentialType
        }
    }

    Context "Changing database credential type to SQL credentials" {
        $credentialType = 'ServiceAccount'
        Set-RsDatabaseCredentials -DatabaseCredentialType $credentialType -Verbose
        
        It "Should update credentials" {
            Get-CredentialType | Should be $credentialType
        }
    }
}