# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Import-Module "$PSScriptRoot\..\..\ReportingServicesTools\ReportingServicesTools.psd1" -Force

InModuleScope ReportingServicesTools {
    Describe 'Copy-RsSubscription destinations without a report server' {
        BeforeEach {
            $script:createdSubscriptions = @()
            $script:owners = @()
            $script:proxy = [pscustomobject]@{}
            $script:proxy | Add-Member ScriptMethod CreateSubscription {
                $script:createdSubscriptions += [pscustomobject]@{Path=$args[0]; DataDriven=$false}
                return 'new-subscription'
            }
            $script:proxy | Add-Member ScriptMethod CreateDataDrivenSubscription {
                $script:createdSubscriptions += [pscustomobject]@{Path=$args[0]; DataDriven=$true}
                return 'new-subscription'
            }
            $script:proxy | Add-Member ScriptMethod ChangeSubscriptionOwner {
                $script:owners += $args[1]
            }
            $script:subscriptions = @(
                [pscustomobject]@{Report='Source';Path='/Reports/Source';Owner='owner-one';IsDataDriven=$false},
                [pscustomobject]@{Report='Second';Path='/Reports/Second';Owner='owner-two';IsDataDriven=$true}
            )
            Mock Get-RsFolderContent {
                @('/Reports/Destination', '/Reports/Source', '/Reports/Second',
                  '/Destination', '/Source', '/Second') | ForEach-Object { [pscustomobject]@{Path=$_} }
            }
        }

        It 'Copies an array of standard and data-driven subscriptions to one explicit report' {
            $result = Copy-RsSubscription -Subscription $script:subscriptions -RsItem /Reports/Destination -Proxy $script:proxy -Confirm:$false
            @($result).Count | Should Be 2
            @($script:createdSubscriptions | Where-Object Path -ne '/Reports/Destination').Count | Should Be 0
            $script:createdSubscriptions[1].DataDriven | Should Be $true
            $result[1].DestinationReport | Should Be '/Reports/Destination'
            $result[1].OriginalReport | Should Be '/Reports/Second'
            $script:owners.Count | Should Be 2
            $script:owners[1] | Should Be 'owner-two'
        }

        It 'Keeps the explicit report unchanged across pipeline records' {
            $result = $script:subscriptions | Copy-RsSubscription -RsItem /Reports/Destination -Proxy $script:proxy -SkipOwner $true -Confirm:$false
            @($result).Count | Should Be 2
            $script:createdSubscriptions[1].Path | Should Be '/Reports/Destination'
            $script:owners.Count | Should Be 0
        }

        It 'Uses each source report name in folder mode' {
            $null = $script:subscriptions | Copy-RsSubscription -RsFolder /Reports/ -Proxy $script:proxy -SkipOwner $true -Confirm:$false
            $script:createdSubscriptions[0].Path | Should Be '/Reports/Source'
            $script:createdSubscriptions[1].Path | Should Be '/Reports/Second'
        }

        It 'Looks up a root-level explicit target in the root folder' {
            $null = Copy-RsSubscription -Subscription $script:subscriptions -RsItem /Destination -Proxy $script:proxy -SkipOwner $true -Confirm:$false
            $script:createdSubscriptions[1].Path | Should Be '/Destination'
            Assert-MockCalled Get-RsFolderContent -Times 2 -Scope It -ParameterFilter { $RsFolder -eq '/' }
        }

        It 'Supports the root destination folder' {
            $null = Copy-RsSubscription -Subscription $script:subscriptions -RsFolder / -Proxy $script:proxy -SkipOwner $true -Confirm:$false
            $script:createdSubscriptions[0].Path | Should Be '/Source'
            $script:createdSubscriptions[1].Path | Should Be '/Second'
        }

        It 'Skips absent target reports without creating subscriptions' {
            Mock Get-RsFolderContent { @() }
            $null = Copy-RsSubscription -Subscription $script:subscriptions -RsItem /Missing -Proxy $script:proxy -WarningAction SilentlyContinue -Confirm:$false
            $script:createdSubscriptions.Count | Should Be 0
        }

        It 'Creates no subscriptions with WhatIf' {
            $null = Copy-RsSubscription -Subscription $script:subscriptions -RsItem /Reports/Destination -Proxy $script:proxy -WhatIf
            $script:createdSubscriptions.Count | Should Be 0
            $script:owners.Count | Should Be 0
        }
    }

    Describe 'Publish-RsProject overwrite settings without a report server' {
        BeforeEach {
            $script:projectPath = Join-Path $TestDrive 'project'
            $null = New-Item -Path $script:projectPath -ItemType Directory -Force
            Set-Content -LiteralPath (Join-Path $script:projectPath 'source.rds') -Value '<RptDataSource><Name>source</Name><ConnectionProperties><Extension>SQL</Extension><ConnectString>Data Source=fixture</ConnectString></ConnectionProperties></RptDataSource>'
            Set-Content -LiteralPath (Join-Path $script:projectPath 'dataset.rsd') -Value '<SharedDataSet><DataSet><Query><DataSourceReference>source</DataSourceReference></Query></DataSet></SharedDataSet>'
            Set-Content -LiteralPath (Join-Path $script:projectPath 'report.rdl') -Value '<Report />'
            $script:arguments = @{
                RsProjectFolder = $script:projectPath
                ReportPortal = 'http://offline.invalid/reports'
                TargetServerURL = 'http://offline.invalid/reportserver'
                TargetReportFolder = '/Reports'
                TargetDatasourceFolder = '/Sources'
                TargetDatasetFolder = '/Sets'
                Confirm = $false
            }
            Mock MakeDeploymentFolders {}
            Mock Get-RsRestItem { [pscustomobject]@{Path=$RsItem} }
            Mock Write-RsRestCatalogItem {}
            Mock Write-RsCatalogItem {}
            Mock Set-RsDataSourceReference {}
            Mock Set-RsDataSetReference {}
            Mock Get-RsRestItemDataSource { @() }
            Mock Get-RsRestFolderContent { @() }
        }

        It 'Leaves existing sources and datasets completely unchanged when False' {
            Publish-RsProject @script:arguments -OverwriteDatasets False -OverwriteDataSources False
            Assert-MockCalled Write-RsRestCatalogItem -Times 0 -Scope It
            Assert-MockCalled Set-RsDataSourceReference -Times 0 -Scope It
            Assert-MockCalled Write-RsCatalogItem -Times 1 -Scope It -ParameterFilter { $Overwrite }
        }

        It 'Replaces sources and datasets and updates dataset references when True' {
            Publish-RsProject @script:arguments -OverwriteDatasets True -OverwriteDataSources True
            Assert-MockCalled Write-RsRestCatalogItem -Times 2 -Scope It -ParameterFilter { $Overwrite }
            Assert-MockCalled Set-RsDataSourceReference -Times 1 -Scope It -ParameterFilter { $Path -eq '/Sets/dataset' }
            Assert-MockCalled Get-RsRestItem -Times 0 -Scope It
        }

        It 'Preserves omitted defaults: replace datasets and keep existing sources' {
            Publish-RsProject @script:arguments
            Assert-MockCalled Write-RsRestCatalogItem -Times 1 -Scope It -ParameterFilter { $RsFolder -eq '/Sets' -and $Overwrite }
            Assert-MockCalled Write-RsRestCatalogItem -Times 0 -Scope It -ParameterFilter { $RsFolder -eq '/Sources' }
        }

        It 'Creates missing sources and datasets without overwrite when False' {
            Mock Get-RsRestItem {
                $error404 = New-Object System.Exception 'fixture missing'
                $error404 | Add-Member NoteProperty Response ([pscustomobject]@{StatusCode=404})
                throw (New-Object System.Exception 'wrapped REST error', $error404)
            }
            Publish-RsProject @script:arguments -OverwriteDatasets False -OverwriteDataSources False
            Assert-MockCalled Write-RsRestCatalogItem -Times 2 -Scope It -ParameterFilter { -not $Overwrite }
            Assert-MockCalled Set-RsDataSourceReference -Times 1 -Scope It
        }

        It 'Does not interpret False strings as True through pipeline binding' {
            $projectFile = Join-Path $script:projectPath 'fixture.rptproj'
            Set-Content -LiteralPath $projectFile -Value '<Project><PropertyGroup><FullPath>Offline</FullPath><OverwriteDatasets>False</OverwriteDatasets><OverwriteDataSources>False</OverwriteDataSources><TargetReportFolder>/Reports</TargetReportFolder><TargetDatasetFolder>/Sets</TargetDatasetFolder><TargetDatasourceFolder>/Sources</TargetDatasourceFolder><TargetServerURL>http://offline.invalid/reportserver</TargetServerURL></PropertyGroup></Project>'
            Get-RsDeploymentConfig -RsProjectFile $projectFile -ConfigurationToUse Offline |
                Add-Member -PassThru -MemberType NoteProperty -Name ReportPortal -Value 'http://offline.invalid/reports' |
                Publish-RsProject -Confirm:$false
            Assert-MockCalled Write-RsRestCatalogItem -Times 0 -Scope It
        }

        It 'Rejects an invalid overwrite setting before contacting the server' {
            { Publish-RsProject @script:arguments -OverwriteDatasets invalid } | Should Throw
            Assert-MockCalled MakeDeploymentFolders -Times 0 -Scope It
        }

        It 'Does not treat authorization errors as absent items' {
            Mock Get-RsRestItem {
                $error403 = New-Object System.Exception 'fixture denied'
                $error403 | Add-Member NoteProperty Response ([pscustomobject]@{StatusCode=403})
                throw $error403
            }
            { Publish-RsProject @script:arguments -OverwriteDatasets False } | Should Throw 'fixture denied'
            Assert-MockCalled Write-RsRestCatalogItem -Times 0 -Scope It
            Assert-MockCalled Write-RsCatalogItem -Times 0 -Scope It
        }

        It 'Looks up data sources by the XML name used by the upload command' {
            Set-Content -LiteralPath (Join-Path $script:projectPath 'source.rds') -Value '<RptDataSource><Name>SharedSource</Name><ConnectionProperties><Extension>SQL</Extension><ConnectString>Data Source=fixture</ConnectString></ConnectionProperties></RptDataSource>'
            Publish-RsProject @script:arguments -OverwriteDatasets False -OverwriteDataSources False
            Assert-MockCalled Get-RsRestItem -Times 1 -Scope It -ParameterFilter { $RsItem -eq '/Sources/SharedSource' }
            Assert-MockCalled Write-RsRestCatalogItem -Times 0 -Scope It
        }

        It 'Does not hide dataset lookup failures or mutate its references' {
            Mock Get-RsRestItem {
                if ($RsItem -eq '/Sets/dataset') { throw 'fixture connection failure' }
                [pscustomobject]@{Path=$RsItem}
            }
            { Publish-RsProject @script:arguments -OverwriteDatasets False } | Should Throw 'fixture connection failure'
            Assert-MockCalled Write-RsRestCatalogItem -Times 0 -Scope It
            Assert-MockCalled Set-RsDataSourceReference -Times 0 -Scope It
        }

        It 'Looks up root-level shared items without duplicate slashes' {
            $script:arguments.TargetDatasourceFolder = '/'
            $script:arguments.TargetDatasetFolder = '/'
            Publish-RsProject @script:arguments -OverwriteDatasets False -OverwriteDataSources False
            Assert-MockCalled Get-RsRestItem -Times 1 -Scope It -ParameterFilter { $RsItem -eq '/source' }
            Assert-MockCalled Get-RsRestItem -Times 1 -Scope It -ParameterFilter { $RsItem -eq '/dataset' }
            Assert-MockCalled Write-RsRestCatalogItem -Times 0 -Scope It
        }

        It 'Configures root-level references correctly when replacing shared items' {
            $script:arguments.TargetDatasourceFolder = '/'
            $script:arguments.TargetDatasetFolder = '/'
            Publish-RsProject @script:arguments -OverwriteDatasets True -OverwriteDataSources True
            Assert-MockCalled Set-RsDataSourceReference -Times 1 -Scope It -ParameterFilter { $Path -eq '/dataset' -and $DataSourcePath -eq '/source' }
        }

        It 'Does not update references after a failed dataset upload' {
            Mock Write-RsRestCatalogItem { throw 'fixture upload failed' }
            { Publish-RsProject @script:arguments } | Should Throw 'fixture upload failed'
            Assert-MockCalled Set-RsDataSourceReference -Times 0 -Scope It
        }

        It 'Skips one existing dataset without skipping subsequent missing datasets' {
            Set-Content -LiteralPath (Join-Path $script:projectPath 'second.rsd') -Value '<SharedDataSet><DataSet><Query><DataSourceReference>source</DataSourceReference></Query></DataSet></SharedDataSet>'
            Mock Get-RsRestItem {
                if ($RsItem -eq '/Sets/second') {
                    $error404 = New-Object System.Exception 'fixture missing'
                    $error404 | Add-Member NoteProperty Response ([pscustomobject]@{StatusCode=404})
                    throw $error404
                }
                [pscustomobject]@{Path=$RsItem}
            }
            Publish-RsProject @script:arguments -OverwriteDatasets False
            Assert-MockCalled Write-RsRestCatalogItem -Times 1 -Scope It -ParameterFilter { $Path -like '*second.rsd' -and -not $Overwrite }
            Assert-MockCalled Set-RsDataSourceReference -Times 1 -Scope It -ParameterFilter { $Path -eq '/Sets/second' }
        }

        It 'Makes no deployment calls with WhatIf' {
            $script:arguments.Remove('Confirm')
            Publish-RsProject @script:arguments -WhatIf
            Assert-MockCalled MakeDeploymentFolders -Times 0 -Scope It
            Assert-MockCalled Get-RsRestItem -Times 0 -Scope It
            Assert-MockCalled Write-RsRestCatalogItem -Times 0 -Scope It
            Assert-MockCalled Write-RsCatalogItem -Times 0 -Scope It
            Assert-MockCalled Set-RsDataSourceReference -Times 0 -Scope It
        }
    }

    Describe 'REST data-source enabled state without HTTP requests' {
        BeforeEach {
            $script:session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
            $script:payloads = @()
            Mock New-RsRestSessionHelper { $script:session }
            Mock Get-RsPortalUriHelper { 'http://offline.invalid/reports/' }
            Mock Invoke-WebRequest {
                $script:payloads += ([System.Text.Encoding]::UTF8.GetString($Body) | ConvertFrom-Json)
                [pscustomobject]@{Content='{}';StatusCode=201}
            }
        }

        It 'Preserves an explicitly enabled source' {
            $path = Join-Path $TestDrive 'enabled.rsds'
            Set-Content -LiteralPath $path -Value '<DataSourceDefinition><Extension>SQL</Extension><ConnectString>Data Source=fixture</ConnectString><Enabled>true</Enabled></DataSourceDefinition>'
            Write-RsRestCatalogItem -Path $path -RsFolder / -WebSession $script:session -ErrorAction Stop
            $script:payloads[0].IsEnabled | Should Be $true
            $script:payloads[0].IsEnabled.GetType() | Should Be ([bool])
        }

        It 'Preserves an explicitly disabled source' {
            $path = Join-Path $TestDrive 'disabled.rsds'
            Set-Content -LiteralPath $path -Value '<DataSourceDefinition><Extension>SQL</Extension><ConnectString>Data Source=fixture</ConnectString><Enabled>false</Enabled></DataSourceDefinition>'
            Write-RsRestCatalogItem -Path $path -RsFolder / -WebSession $script:session -ErrorAction Stop
            $script:payloads[0].IsEnabled | Should Be $false
        }

        It 'Defaults to enabled when Enabled is absent, matching SOAP uploads' {
            $path = Join-Path $TestDrive 'default.rsds'
            Set-Content -LiteralPath $path -Value '<DataSourceDefinition><Extension>SQL</Extension><ConnectString>Data Source=fixture</ConnectString></DataSourceDefinition>'
            Write-RsRestCatalogItem -Path $path -RsFolder / -WebSession $script:session -ErrorAction Stop
            $script:payloads[0].IsEnabled | Should Be $true
        }

        It 'Accepts XML Boolean numeric values' {
            foreach ($value in @('1', '0')) {
                $path = Join-Path $TestDrive "$value.rsds"
                Set-Content -LiteralPath $path -Value "<DataSourceDefinition><Extension>SQL</Extension><ConnectString>Data Source=fixture</ConnectString><Enabled>$value</Enabled></DataSourceDefinition>"
                Write-RsRestCatalogItem -Path $path -RsFolder / -WebSession $script:session -ErrorAction Stop
            }
            $script:payloads[0].IsEnabled | Should Be $true
            $script:payloads[1].IsEnabled | Should Be $false
        }

        It 'Accepts Report Server True/False casing' {
            foreach ($value in @('True', 'False')) {
                $path = Join-Path $TestDrive "$value-cased.rsds"
                Set-Content -LiteralPath $path -Value "<DataSourceDefinition><Extension>SQL</Extension><ConnectString>Data Source=fixture</ConnectString><Enabled>$value</Enabled></DataSourceDefinition>"
                Write-RsRestCatalogItem -Path $path -RsFolder / -WebSession $script:session -ErrorAction Stop
            }
            $script:payloads[0].IsEnabled | Should Be $true
            $script:payloads[1].IsEnabled | Should Be $false
        }

        It 'Rejects an invalid Enabled value before sending an upload' {
            $path = Join-Path $TestDrive 'invalid.rsds'
            Set-Content -LiteralPath $path -Value '<DataSourceDefinition><Extension>SQL</Extension><ConnectString>Data Source=fixture</ConnectString><Enabled>invalid</Enabled></DataSourceDefinition>'
            { Write-RsRestCatalogItem -Path $path -RsFolder / -WebSession $script:session -ErrorAction Stop } | Should Throw
            Assert-MockCalled Invoke-WebRequest -Times 0 -Scope It
        }

        It 'Keeps each enabled state independent for multiple input files' {
            $paths = @()
            foreach ($value in @('false', 'true')) {
                $path = Join-Path $TestDrive "$value.rsds"
                Set-Content -LiteralPath $path -Value "<DataSourceDefinition><Extension>SQL</Extension><ConnectString>Data Source=fixture</ConnectString><Enabled>$value</Enabled></DataSourceDefinition>"
                $paths += $path
            }
            Write-RsRestCatalogItem -Path $paths -RsFolder / -WebSession $script:session -ErrorAction Stop
            $script:payloads.Count | Should Be 2
            $script:payloads[0].IsEnabled | Should Be $false
            $script:payloads[1].IsEnabled | Should Be $true
        }

        It 'Retains the enabled default for project data sources' {
            $path = Join-Path $TestDrive 'project.rds'
            Set-Content -LiteralPath $path -Value '<RptDataSource><Name>source</Name><ConnectionProperties><Extension>SQL</Extension><ConnectString>Data Source=fixture</ConnectString><IntegratedSecurity>true</IntegratedSecurity></ConnectionProperties></RptDataSource>'
            Write-RsRestCatalogItem -Path $path -RsFolder / -WebSession $script:session -ErrorAction Stop
            $script:payloads[0].IsEnabled | Should Be $true
            $script:payloads[0].CredentialRetrieval | Should Be 'integrated'
        }
    }
}
