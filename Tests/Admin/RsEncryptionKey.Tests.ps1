function New-TestDataSource() {
    $dataSource = New-Object -TypeName PSObject
    $dataSourceName = 'SimpleDataSource' + [System.DateTime]::Now.Ticks

    $dataSource | Add-Member -MemberType NoteProperty -Name Name -Value $dataSourceName
    $dataSource | Add-Member -MemberType NoteProperty -Name ConnectionString -Value 'Data Source=localhost;'
    $dataSource | Add-Member -MemberType NoteProperty -Name Extension -Value 'SQL'
    $dataSource | Add-Member -MemberType NoteProperty -Name CredentialRetrievalType -Value 'None'
    $dataSource | Add-Member -MemberType NoteProperty -Name Path -Value "/$dataSourceName"

    return $dataSource
}

function Test-AccessToEncryptedContent() {
    param(
        [Parameter(Mandatory=$True)]
        [PSObject]$ExpectedDataSource
    )

    $dataSource = Get-RsDataSource -DataSourcePath $ExpectedDataSource.Path
    $dataSource.Extension | Should be $ExpectedDataSource.Extension
    $dataSource.ConnectString | Should be $ExpectedDataSource.ConnectionString
    $dataSource.CredentialRetrieval | Should be $ExpectedDataSource.CredentialRetrievalType
}

#Describe "RsEncryptionKey" {
#    Context "Backing up and restoring encryption key" {
#        $itemsToClean = New-Object System.Collections.Generic.List[string]
#
#        It "Should allow access of encrypted content post restore" {
#            $dataSource = New-TestDataSource
#            New-RsDataSource -RsFolder '/' -Name $dataSource.Name -Extension $dataSource.Extension -ConnectionString $dataSource.ConnectionString -CredentialRetrieval $dataSource.CredentialRetrievalType
#            $itemsToClean.Add($dataSource.Path)
#
#            $keyPassword = 'RS4Ever!'
#            $currentDir = (Resolve-Path '.').Path
#            $keyPath = Join-Path $currentDir -ChildPath 'key.snk'
#
#            Backup-RsEncryptionKey -Password $keyPassword -KeyPath $keyPath -Confirm:$false -Verbose
#            Restore-RsEncryptionKey -Password $keyPassword -KeyPath $keyPath -Confirm:$false -Verbose
#
#            Test-AccessToEncryptedContent -ExpectedDataSource $dataSource
#        }
#
#        It "Should allow backup and restore of encryption key to relative paths" {
#            $dataSource = New-TestDataSource
#            New-RsDataSource -RsFolder '/' -Name $dataSource.Name -Extension $dataSource.Extension -ConnectionString $dataSource.ConnectionString -CredentialRetrieval $dataSource.CredentialRetrievalType
#            $itemsToClean.Add($dataSource.Path)
#
#            $keyPassword = 'RS4Ever!'
#            $keyPath = '.\key.snk'
#
#            Backup-RsEncryptionKey -Password $keyPassword -KeyPath $keyPath -Confirm:$false -Verbose
#            Restore-RsEncryptionKey -Password $keyPassword -KeyPath $keyPath -Confirm:$false -Verbose
#
#            Test-AccessToEncryptedContent -ExpectedDataSource $dataSource
#        }
#
#        BeforeEach {
#            $itemsToClean.Clear()
#        }
#
#        AfterEach {
#            Remove-RsCatalogItem -Path $itemsToClean
#        }
#    }
#}