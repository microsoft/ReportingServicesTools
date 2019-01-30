# Copyright (c) 2017 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

Describe "Set-RsItemDataSource" { 
    $rsFolderPath = ''
    $datasourcesReportPath = ''

    BeforeEach {
        # create new folder in RS
        $folderName = 'SUT_OutRsRestCatalogItem_' + [guid]::NewGuid()
        New-RsFolder -ReportServerUri $reportServerUri -RsFolder / -FolderName $folderName
        $rsFolderPath = '/' + $folderName

        $localResourcesPath = (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\datasources'
        
        # upload datasourcesReport to new folder in RS
        Write-RsCatalogItem -ReportServerUri $reportServerUri -Path "$localResourcesPath\datasourcesReport.rdl" -RsFolder $rsFolderPath
        $datasourcesReportPath = "$rsFolderPath/datasourcesReport"
    }

    AfterEach {
        Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsItem $datasourcesReportPath -Confirm:$false
        Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsItem $rsFolderPath -Confirm:$false
    }

    Context "Updates data sources with Proxy parameter" {
        $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

        It "Should allow integrated auth" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Integrated'
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Integrated'
        }

        It "Should allow stored auth with SQL credentials" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Store'
            $dataSources[0].Item.UserName = 'sqluser'
            $dataSources[0].Item.Password = 'sqluserpassword'
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Store'
            $updatedDataSources[0].Item.UserName | Should Be 'sqluser'
            $updatedDataSources[0].Item.Password | Should BeNullOrEmpty
            $updatedDataSources[0].Item.WindowsCredentials | Should Be False
            $updatedDataSources[0].Item.ImpersonateUser | Should Be False
        }

        It "Should allow stored auth with Windows credentials" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Store'
            $dataSources[0].Item.UserName = 'windowsuser'
            $dataSources[0].Item.Password = 'windowsuserpassword'
            $dataSources[0].Item.WindowsCredentials = $true
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Store'
            $updatedDataSources[0].Item.UserName | Should Be 'windowsuser'
            $updatedDataSources[0].Item.Password | Should BeNullOrEmpty
            $updatedDataSources[0].Item.WindowsCredentials | Should Be True
            $updatedDataSources[0].Item.ImpersonateUser | Should Be False
        }

        It "Should allow stored auth with SQL credentials and impersonation" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Store'
            $dataSources[0].Item.UserName = 'sqluser'
            $dataSources[0].Item.Password = 'sqluserpassword'
            $dataSources[0].Item.ImpersonateUser = $true
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Store'
            $updatedDataSources[0].Item.UserName | Should Be 'sqluser'
            $updatedDataSources[0].Item.Password | Should BeNullOrEmpty
            $updatedDataSources[0].Item.WindowsCredentials | Should Be False
            $updatedDataSources[0].Item.ImpersonateUser | Should Be True
        }

        It "Should allow stored auth with Windows credentials and impersonation" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Store'
            $dataSources[0].Item.UserName = 'windowsuser'
            $dataSources[0].Item.Password = 'windowsuserpassword'
            $dataSources[0].Item.WindowsCredentials = $true
            $dataSources[0].Item.ImpersonateUser = $true
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Store'
            $updatedDataSources[0].Item.UserName | Should Be 'windowsuser'
            $updatedDataSources[0].Item.Password | Should BeNullOrEmpty
            $updatedDataSources[0].Item.WindowsCredentials | Should Be True
            $updatedDataSources[0].Item.ImpersonateUser | Should Be True
        }

        It "Should allow prompt for SQL credentials" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Prompt'
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Prompt'
            $updatedDataSources[0].Item.WindowsCredentials | Should Be False
        }

        It "Should allow prompt for Windows credentials" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Prompt'
            $dataSources[0].Item.WindowsCredentials = $true
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Prompt'
            $updatedDataSources[0].Item.WindowsCredentials | Should Be True
        }

        It "Should allow prompt with message" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Prompt'
            $dataSources[0].Item.Prompt = 'This is a prompt'
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Prompt'
            $updatedDataSources[0].Item.Prompt | Should Be 'This is a prompt'
        }

        It "Should allow no credentials" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'None'
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'None'
        }
    }
}