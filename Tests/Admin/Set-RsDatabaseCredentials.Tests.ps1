function Get-CredentialType() {
    $wmiObject = New-RsConfigurationSettingObject -ReportServerInstance PBIRS -ReportServerVersion SQLServervNext
    switch ($wmiObject.DatabaseLogonType) {
        0 { return 'Windows' }
        1 { return 'SQL' }
        2 { return 'ServiceAccount' }
        default { throw 'Invalid Credential Type!' }
    }
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
        Set-RsDatabaseCredentials -DatabaseCredentialType $credentialType -DatabaseCredential $credential -Confirm:$false -Verbose -ReportServerInstance PBIRS -ReportServerVersion SQLServervNext
        
        It "Should update credentials" {
            Get-CredentialType | Should be $credentialType
        }
    }

    Context "Changing database credential type to SQL credentials" {
        $credentialType = 'ServiceAccount'
        Set-RsDatabaseCredentials -DatabaseCredentialType $credentialType -Confirm:$false -Verbose -ReportServerInstance PBIRS -ReportServerVersion SQLServervNext
        
        It "Should update credentials" {
            Get-CredentialType | Should be $credentialType
        }
    }
}
