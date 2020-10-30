$reportPortalUri = if ($env:PesterPortalUrl -eq $null) { 'http://localhost/reports' } else { $env:PesterPortalUrl }

Describe "Publish-RsProject" {
    Context "Deploy an entire SSRS Project by getting the DeploymentConfig of a ReportServer project file using ConfigurationToUse parameter"{
        # Create a folder
        $RSConfig = Get-RsDeploymentConfig -RsProjectFile "$($PSScriptRoot)\TestProjects\SQLServerPerformanceDashboardReportingSolution\SQL Server Performance Dashboard\SQL Server Performance Dashboard.rptproj" -ConfigurationToUse Release |
        Add-Member -PassThru -MemberType NoteProperty -Name ReportPortal -Value $reportPortalUri
        
        # Test if the config was retrieved
        It "Should verify a config was retrieved" {
            @($RSConfig).Count | Should Be 1
        }
        
        # Test if the TargetServerURL in the config was found
        It "Should verify TargetServerURL matches" {
            $RSConfig.TargetServerURL | Should Be 'http://localhost/reportserver'
        }

        $RSConfig | Publish-RsProject
        $CatalogList = Get-RsRestFolderContent -reportPortalUri $RSConfig.ReportPortal -RsFolder '/SQL Server Performance Dashboard' -Recurse
        $folderCount = ($CatalogList | measure).Count
        It "Should find at least 1 folder" {
            $folderCount | Should Be 22
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -RsFolder $RSConfig.TargetReportFolder -Confirm:$false
        Remove-RsCatalogItem -RsFolder $RSConfig.TargetDatasetFolder -Confirm:$false
        Remove-RsCatalogItem -RsFolder $RSConfig.TargetDatasourceFolder -Confirm:$false
        
    }
}    