
Describe "Get-RsDeploymentConfig" {
    $RSConfig = Get-RsDeploymentConfig -RsProjectFile "$($PSScriptRoot)\TestProjects\SQLServerPerformanceDashboardReportingSolution\SQL Server Performance Dashboard\SQL Server Performance Dashboard.rptproj" -ConfigurationToUse Release
    
    Write-Verbose "$RSConfig.TargetServerURL"
    Write-Verbose "$RSConfig.RsProjectFolder"

    Context "Get the DeploymentConfig of a ReportServer project file using ConfigurationToUse parameter"{
        # Create a folder
        # Test if the config was found
        It "Should verify TargetServerURL matches" {
            $RSConfig.TargetServerURL | Should Be 'http://localhost/reportserver'
        }

        # Test if the folder can be found
        It "Should verify a config was retrieved" {
            @($RSConfig).Count | Should Be 1
        }
        
    }
}    