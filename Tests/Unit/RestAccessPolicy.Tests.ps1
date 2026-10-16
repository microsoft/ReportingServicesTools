# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Import-Module "$PSScriptRoot\..\..\ReportingServicesTools\ReportingServicesTools.psd1" -Force

InModuleScope ReportingServicesTools {
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

        It 'Retains the catalog endpoint for reports' {
            Get-RsRestItemAccessPolicy -RsItem '/Report' | Out-Null
            $script:policyRequests[0] | Should Be 'http://localhost/reports/api/v2.0/CatalogItems(Report)/Policies'
        }

        It 'Retains the catalog endpoint for Power BI reports' {
            Get-RsRestItemAccessPolicy -RsItem '/PowerBIReport' | Out-Null
            $script:policyRequests[0] | Should Be 'http://localhost/reports/api/v2.0/CatalogItems(PowerBIReport)/Policies'
        }

        It 'Uses each pipeline item identifier and type' {
            @([pscustomobject]@{ RsItem = '/Folder' }, [pscustomobject]@{ RsItem = '/Report' }) |
                Get-RsRestItemAccessPolicy | Out-Null
            $script:policyRequests.Count | Should Be 2
            $script:policyRequests[0] | Should Be 'http://localhost/reports/api/v2.0/Folders(Folder)/Policies'
            $script:policyRequests[1] | Should Be 'http://localhost/reports/api/v2.0/CatalogItems(Report)/Policies'
        }

        It 'Uses typed folder routes for recursive children' {
            Get-RsRestItemAccessPolicy -RsItem '/Folder' -Recurse | Out-Null
            $script:policyRequests.Count | Should Be 3
            $script:policyRequests[1] | Should Be 'http://localhost/reports/api/v2.0/Folders(ChildFolder)/Policies'
            $script:policyRequests[2] | Should Be 'http://localhost/reports/api/v2.0/CatalogItems(ChildReport)/Policies'
        }

        It 'Keeps failures catchable' {
            Mock Invoke-RestMethod { throw 'policy read failed' }
            { Get-RsRestItemAccessPolicy -RsItem '/Folder' } | Should Throw 'policy read failed'
        }
    }
}
