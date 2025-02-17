function Get-DatabaseName() {
    $wmiObject = New-RsConfigurationSettingObject -ReportServerInstance PBIRS -ReportServerVersion PowerBIReportServer
    return $wmiObject.DatabaseName
}

function Get-CredentialType() {
    $wmiObject = New-RsConfigurationSettingObject -ReportServerInstance PBIRS -ReportServerVersion PowerBIReportServer
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

Describe "Set-RsDatabase" {
    Context "Changing database to a new database using ServiceAccount credentials" {
        $databaseServerName = 'localhost'
        $databaseName = 'ReportServer' + [System.DateTime]::Now.Ticks
        $credentialType = 'ServiceAccount'
        Set-RsDatabase -DatabaseServerName $databaseServerName -DatabaseName $databaseName -DatabaseCredentialType $credentialType -Confirm:$false -Verbose -ReportServerInstance PBIRS -ReportServerVersion PowerBIReportServer
        
        It "Should update database and credentials" {
            Get-DatabaseName | Should be $databaseName
            Get-CredentialType | Should be $credentialType
        }
    }
    
    Context "Changing database to a new database using SQL credentials" {
        $databaseServerName = 'localhost'
        $databaseName = 'ReportServer' + [System.DateTime]::Now.Ticks
        $credentialType = 'SQL'
        $credential = Get-SaCredentials
        Set-RsDatabase -DatabaseServerName $databaseServerName -DatabaseName $databaseName -DatabaseCredentialType $credentialType -DatabaseCredential $credential -Confirm:$false -Verbose -ReportServerInstance PBIRS -ReportServerVersion PowerBIReportServer
        
        It "Should update database and credentials" {
            Get-DatabaseName | Should be $databaseName
            Get-CredentialType | Should be $credentialType
        }
    }
    
    Context "Changing database to an existing database using SQL credentials" {
        $databaseServerName = 'localhost'
        $databaseName = 'ReportServer'
        $credentialType = 'SQL'
        $credential = Get-SaCredentials
        Set-RsDatabase -DatabaseServerName $databaseServerName -DatabaseName $databaseName -DatabaseCredentialType $credentialType -DatabaseCredential $credential -IsExistingDatabase -Confirm:$false -Verbose -ReportServerInstance PBIRS -ReportServerVersion SQLServer2022
        
        It "Should update database and credentials" {
            Get-DatabaseName | Should be $databaseName
            Get-CredentialType | Should be $credentialType
        }
    }
    
    Context "Changing database to an existing database using ServiceAccount credentials" {
        $databaseServerName = 'localhost'
        $databaseName = 'ReportServer'
        $credentialType = 'ServiceAccount'
        Set-RsDatabase -DatabaseServerName $databaseServerName -DatabaseName $databaseName -DatabaseCredentialType $credentialType -IsExistingDatabase -Confirm:$false -Verbose -ReportServerInstance PBIRS -ReportServerVersion SQLServer2022
        
        It "Should update database and credentials" {
            Get-DatabaseName | Should be $databaseName
            Get-CredentialType | Should be $credentialType
        }
    }
}
