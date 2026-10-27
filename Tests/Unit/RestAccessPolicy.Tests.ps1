# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Import-Module "$PSScriptRoot\..\..\ReportingServicesTools\ReportingServicesTools.psd1" -Force

InModuleScope ReportingServicesTools {
    foreach ($policyCommandName in 'Grant-RsRestItemAccessPolicy', 'Revoke-RsRestItemAccessPolicy') {
        Describe "$policyCommandName request payload" {
            BeforeEach {
                $script:policySession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
                $script:policyPayload = $null
                $script:policyItemType = 'Folder'
                Mock New-RsRestSessionHelper { $script:policySession }
                Mock Get-RsPortalUriHelper { 'http://localhost/reports/' }
                Mock Get-RsRestItem { [pscustomobject]@{ Id = 'item-id'; Type = $script:policyItemType } }
                Mock Invoke-RestMethod {
                    param ($Uri, $Method, $Body)
                    if ($Method -eq 'Get') {
                        return [pscustomobject]@{
                            '@odata.context' = 'http://localhost/reports/api/v2.0/$metadata#Collection(Model.ItemPolicy)'
                            Id = '00000000-0000-0000-0000-000000000000'
                            InheritParentPolicy = $false
                            Policies = @(
                                [pscustomobject]@{
                                    GroupUserName = 'DOMAIN\Administrator'
                                    Roles = @([pscustomobject]@{ Name = 'Content Manager'; Description = $null })
                                }
                                [pscustomobject]@{
                                    GroupUserName = 'DOMAIN\Reader'
                                    Roles = @([pscustomobject]@{ Name = 'Browser'; Description = '' })
                                }
                            )
                        }
                    }
                    $script:policyPayload = [Text.Encoding]::UTF8.GetString($Body) | ConvertFrom-Json
                }
                $script:policyArguments = @{ RsItem = '/TestItem'; Identity = 'DOMAIN\Reader' }
                if ($policyCommandName -eq 'Grant-RsRestItemAccessPolicy') { $script:policyArguments.Role = 'Publisher' }
            }

            It 'Sends a writable policy model without response-only OData annotations' {
                & $policyCommandName @script:policyArguments | Out-Null
                @($script:policyPayload.PSObject.Properties.Name) -contains '@odata.context' | Should Be $false
                @($script:policyPayload.PSObject.Properties.Name) -contains 'Id' | Should Be $false
                $script:policyPayload.InheritParentPolicy | Should Be $false
                $script:policyPayload.Policies -is [array] | Should Be $true
                $admin = @($script:policyPayload.Policies | Where-Object { $_.GroupUserName -eq 'DOMAIN\Administrator' })
                $admin.Count | Should Be 1
                $admin[0].Roles[0].Name | Should Be 'Content Manager'
                $reader = @($script:policyPayload.Policies | Where-Object { $_.GroupUserName -eq 'DOMAIN\Reader' })
                if ($policyCommandName -eq 'Grant-RsRestItemAccessPolicy') {
                    @($reader | ForEach-Object { $_.Roles.Name }) -contains 'Publisher' | Should Be $true
                } else {
                    $reader.Count | Should Be 0
                }
            }

            It 'Uses the same clean request model for reports' {
                $script:policyItemType = 'Report'
                & $policyCommandName @script:policyArguments | Out-Null
                @($script:policyPayload.PSObject.Properties.Name) -contains '@odata.context' | Should Be $false
                Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Method -eq 'Put' -and $Uri -eq 'http://localhost/reports/api/v2.0/Reports(item-id)/Policies'
                }
            }

            It 'Propagates policy write failures' {
                Mock Invoke-RestMethod { throw 'policy write failed' } -ParameterFilter { $Method -eq 'Put' }
                { & $policyCommandName @script:policyArguments } | Should Throw 'policy write failed'
            }
        }
    }

    Describe 'REST access policy routes' {
        BeforeEach {
            $script:policySession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
            $script:policyRequests = @()
            Mock New-RsRestSessionHelper { $script:policySession }
            Mock Get-RsPortalUriHelper { 'http://localhost/reports/' }
            Mock Get-RsRestItem {
                param ($RsItem)
                $type = if ($RsItem -like '*PowerBIReport*') { 'PowerBIReport' } elseif ($RsItem -like '*Report*') { 'Report' } else { 'Folder' }
                [pscustomobject]@{ Id = $RsItem.Trim('/'); Type = $type; Path = $RsItem }
            }
            Mock Get-RsRestFolderContent {
                @(
                    [pscustomobject]@{ Id = 'ChildFolder'; Type = 'Folder'; Path = '/Folder/ChildFolder' }
                    [pscustomobject]@{ Id = 'ChildReport'; Type = 'Report'; Path = '/Folder/ChildReport' }
                )
            }
            Mock Invoke-RestMethod {
                param ($Uri)
                $script:policyRequests += $Uri
                [pscustomobject]@{
                    InheritParentPolicy = $false
                    Policies = @([pscustomobject]@{
                        GroupUserName = 'DOMAIN\Reader'
                        Roles = @([pscustomobject]@{ Name = 'Browser' })
                    })
                }
            }
        }

        It 'Reads folder policies through the folder endpoint' {
            $result = Get-RsRestItemAccessPolicy -RsItem '/Folder'
            $script:policyRequests[0] | Should Be 'http://localhost/reports/api/v2.0/Folders(Folder)/Policies'
            $result.Identity | Should Be 'DOMAIN\Reader'
            $result.Roles | Should Be 'Browser'
        }

        It 'Reads report policies through the typed report endpoint' {
            Get-RsRestItemAccessPolicy -RsItem '/Report' | Out-Null
            $script:policyRequests[0] | Should Be 'http://localhost/reports/api/v2.0/Reports(Report)/Policies'
        }

        It 'Reads Power BI report policies through the typed endpoint' {
            Get-RsRestItemAccessPolicy -RsItem '/PowerBIReport' | Out-Null
            $script:policyRequests[0] | Should Be 'http://localhost/reports/api/v2.0/PowerBIReports(PowerBIReport)/Policies'
        }

        It 'Uses each pipeline item identifier and type' {
            @([pscustomobject]@{ RsItem = '/Folder' }, [pscustomobject]@{ RsItem = '/Report' }) |
                Get-RsRestItemAccessPolicy | Out-Null
            $script:policyRequests.Count | Should Be 2
            $script:policyRequests[0] | Should Be 'http://localhost/reports/api/v2.0/Folders(Folder)/Policies'
            $script:policyRequests[1] | Should Be 'http://localhost/reports/api/v2.0/Reports(Report)/Policies'
        }

        It 'Uses typed folder routes for recursive children' {
            Get-RsRestItemAccessPolicy -RsItem '/Folder' -Recurse | Out-Null
            $script:policyRequests.Count | Should Be 3
            $script:policyRequests[1] | Should Be 'http://localhost/reports/api/v2.0/Folders(ChildFolder)/Policies'
            $script:policyRequests[2] | Should Be 'http://localhost/reports/api/v2.0/Reports(ChildReport)/Policies'
        }

        It 'Keeps failures catchable' {
            Mock Invoke-RestMethod { throw 'policy read failed' }
            { Get-RsRestItemAccessPolicy -RsItem '/Folder' } | Should Throw 'policy read failed'
        }
    }
    Describe 'Get-RsRestPolicyUri' {
        $cases = @(
            @{ Type = 'Folder'; Set = 'Folders' }
            @{ Type = 'Report'; Set = 'Reports' }
            @{ Type = 'PowerBIReport'; Set = 'PowerBIReports' }
            @{ Type = 'LinkedReport'; Set = 'LinkedReports' }
            @{ Type = 'DataSource'; Set = 'DataSources' }
            @{ Type = 'DataSet'; Set = 'DataSets' }
            @{ Type = 'Kpi'; Set = 'Kpis' }
            @{ Type = 'Resource'; Set = 'Resources' }
            @{ Type = 'ExcelWorkbook'; Set = 'ExcelWorkbooks' }
            @{ Type = 'Component'; Set = 'Components' }
            @{ Type = 'SomethingNew'; Set = 'CatalogItems' }
        )

        It 'Maps <Type> to the <Set> entity set' -TestCases $cases {
            param ($Type, $Set)
            $uri = Get-RsRestPolicyUri -ReportPortalUri 'http://localhost/reports/' -RestApiVersion 'v2.0' -Item ([pscustomobject]@{ Id = 'abc'; Type = $Type })
            $uri | Should Be "http://localhost/reports/api/v2.0/$Set(abc)/Policies"
        }
    }
}
