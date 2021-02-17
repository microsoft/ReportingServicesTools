
Describe "Get-RsDeploymentConfig" {
    $RSConfig = Get-RsDeploymentConfig -RsProjectFile "$($PSScriptRoot)\TestProjects\SQLServerPerformanceDashboardReportingSolution\SQL Server Performance Dashboard\SQL Server Performance Dashboard.rptproj" -ConfigurationToUse Release
    
    Write-Verbose "$RSConfig.TargetServerURL"
    Write-Verbose "$RSConfig.RsProjectFolder"
    Write-Verbose "$RSConfig.TargetDatasetFolder"
    Write-Verbose "$RSConfig.TargetDatasourceFolder"
    Write-Verbose "$RSConfig.TargetReportPartFolder"

    Context "Get the Release DeploymentConfig of a ReportServer project file using ConfigurationToUse parameter"{
        It "Should verify TargetServerURL matches" {
            $RSConfig.TargetServerURL | Should Be 'http://localhost/reportserver'
        }

        It "Should verify a config was retrieved" {
            @($RSConfig).Count | Should Be 1
        }

        It "Should verify the Dataset, Datasource, and ReportPart folders are NULL" {
            #$RSConfig = Get-RsDeploymentConfig -RsProjectFile "$($PSScriptRoot)\TestProjects\SQLServerPerformanceDashboardReportingSolution\SQL Server Performance Dashboard\SQL Server Performance Dashboard.rptproj" -ConfigurationToUse Release
            
            Write-Verbose "$RSConfig.TargetDatasetFolder"
            Write-Verbose "$RSConfig.TargetDatasourceFolder"
            Write-Verbose "$RSConfig.TargetReportPartFolder"

            $RSConfig.TargetDatasetFolder | Should Be '/Datasets'
            $RSConfig.TargetDatasourceFolder | Should Be '/Data Sources'
            $RSConfig.TargetReportPartFolder | Should Be 'Report Parts'
        }
        
    }

    Context "Get the DebugNull DeploymentConfig of a ReportServer project file using ConfigurationToUse parameter"{
        It "Should verify TargetServerURL matches" {
            $RSConfig = Get-RsDeploymentConfig -RsProjectFile "$($PSScriptRoot)\TestProjects\SQLServerPerformanceDashboardReportingSolution\SQL Server Performance Dashboard\SQL Server Performance Dashboard.rptproj" -ConfigurationToUse DebugNull
            
            Write-Verbose "$RSConfig.TargetServerURL"
            Write-Verbose "$RSConfig.RsProjectFolder"
            Write-Verbose "$RSConfig.TargetDatasetFolder"
            Write-Verbose "$RSConfig.TargetDatasourceFolder"
            Write-Verbose "$RSConfig.TargetReportPartFolder"

            $RSConfig.TargetServerURL | Should Be 'http://localhost/reportserver'
        }

        It "Should verify a config was retrieved" {
            @($RSConfig).Count | Should Be 1
        }

        It "Should verify config was successfully retrieved even though Dataset, Datasource, and ReportPart folders are NULL" {
            $RSConfig = Get-RsDeploymentConfig -RsProjectFile "$($PSScriptRoot)\TestProjects\SQLServerPerformanceDashboardReportingSolution\SQL Server Performance Dashboard\SQL Server Performance Dashboard.rptproj" -ConfigurationToUse DebugNull
            
            $RSConfig.TargetDatasetFolder | Should BeNullOrEmpty
            $RSConfig.TargetDatasourceFolder | Should BeNullOrEmpty
            $RSConfig.TargetReportPartFolder | Should BeNullOrEmpty
        }
        
    }
}    