$reportPortalUri = if ($env:PesterPortalUrl -eq $null) { 'http://localhost/reports' } else { $env:PesterPortalUrl }

Describe "Get-RsDeploymentConfig" {
    Context "Get the DeploymentConfig of a ReportServer project file using ConfigurationToUse parameter"{
        # Create a folder
        $RSConfig = Get-RsDeploymentConfig -RsProjectFile "$($PSScriptRoot)\testResources\TestProjects\SQLServerPerformanceDashboardReportingSolution\SQL Server Performance Dashboard\SQL Server Performance Dashboard.rptproj" -ConfigurationToUse Release |
        Add-Member -PassThru -MemberType NoteProperty -Name ReportPortal -Value $reportPortalUri
        $RSConfig | Deploy-RsProject
        
        # Test if the config was found
        It "Should verify TargetServerURL matches" {
            $RSConfig.TargetServerURL | Should Be 'http://localhost/reportserver'
        }

        # Test if the folder can be found
        It "Should verify a config was retrieved" {
            $RSConfig.Count | Should Be 1
        }
        
        $folderList = Get-RsRestFolderContent -reportPortalUri $reportPortalUri -RsFolder / -Recurse
        $folderCount = ($folderList).Count
        It "Should find at least 1 folder" {
            $folderCount | Should Be 1
        }
        
    }
}    