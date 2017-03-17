Describe "RsEncryptionKey" {
    Context "Backing up and restoring encryption key" {
        $name = 'SimpleDataSource' + [System.DateTime]::Now.Ticks
        $connectionString = 'Data Source=localhost;'
        $extension = 'SQL'
        $credentialRetrieval = 'None'
        New-RsDataSource -RsFolder '/' -Name $name -Extension $extension -ConnectionString $connectionString -CredentialRetrieval $credentialRetrieval

        $keyPassword = 'RS4Ever!'
        $currentDir = (Resolve-Path '.').Path
        $keyPath = Join-Path $currentDir -ChildPath 'key.snk'
        Backup-RsEncryptionKey -Password $keyPassword -KeyPath $keyPath -Verbose
        Restore-RsEncryptionKey -Password $keyPassword -KeyPath $keyPath -Verbose

        It "Should allow access of encrypted content post restore" {
            $dataSource = Get-RsDataSource -DataSourcePath "/$name"
            $dataSource.Extension | Should be $extension
            $dataSource.ConnectString | Should be $connectionString
            $dataSource.CredentialRetrieval | Should be $credentialRetrieval
        }
    }
}