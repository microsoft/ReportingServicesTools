function Get-RsDeploymentConfig {
    <#
        .SYNOPSIS
            This script retrieves a list of deployment configurations from a Reporting Services project file.

        .DESCRIPTION
            This function This script retrieves a list of deployment configurations from a Reporting Services project file for deployment to a Power BI Report Server.

        .PARAMETER RsProjectFile
            Specify the location of the SSRS project file whose deployment profiles should be fetched.

        .PARAMETER ConfigurationToUse
            Specify which configuration to use from the SSRS project file, if you already know it's name.

        .EXAMPLE
            Get-RsDeploymentConfig -RsProjectFile 'C:\source\repos\SQL Server Performance Dashboard\SQL Server Performance Dashboard.rptproj' -ConfigurationToUse Release

            FullPath               : Release
            OverwriteDatasets      : False
            OverwriteDataSources   : False
            TargetReportFolder     : /SQL Server Performance Dashboard
            TargetDatasetFolder    : /Datasets
            TargetDatasourceFolder : /Data Sources
            TargetReportPartFolder : Report Parts
            TargetServerURL        : http://localhost/reportserver
            RsProjectFolder        : C:\source\repos\SQL Server Performance Dashboard

            Description
            -----------
            Retrieves all deployment settings for the 'Release' deployment configuration of the SQL Server Performance Dashboard.rptproj file.  
            Then returns an object with all applicable settings from that deployment configuration.
        
        .EXAMPLE
            Get-RsDeploymentConfig -RsProjectFile 'C:\Users\Aaron\source\repos\Finance\Financial Reports\SSRS_FR\SSRS_FR.rptproj'

            Description
            -----------
            Retrieves all deployment profiles from the SSRS_FR.rptproj file and allows the user to choose which deployment configuration to use.  
            Then returns an object with all applicable settings from that deployment configuration.
        
        .EXAMPLE
            $RSConfig = Get-RsDeploymentConfig -RsProjectFile 'C:\Users\Aaron\source\repos\Financial Reports\SSRS_FR\SSRS_FR.rptproj'

            Description
            -----------
            Retrieves all deployment profiles from the SSRS_FR.rptproj file and allows the user to choose which deployment configuration to use.  
            After the selection is made, the applicable settings are stored in the $RSConfig variable.
        
        .EXAMPLE
            $RSConfig = Get-RsDeploymentConfig -RsProjectFile 'C:\Users\Aaron\source\repos\Financial Reports\SSRS_FR\SSRS_FR.rptproj' -ConfigurationToUse Dev01 |
            Add-Member -PassThru -MemberType NoteProperty -Name ReportPortal -Value 'http://localhost/PBIRSportal/'
            $RSConfig | Deploy-RsProject

            Retrieves all deployment settings for the 'Dev01' deployment configuration, adds a NoteProperty for the ReportPortal to deploy to, 
            and then deploys all the project files by calling Deploy-RsProject and passing in all the settings in the $RSConfig variable.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$RsProjectFile,

        [Parameter(Mandatory = $false)]
        [string]$ConfigurationToUse
    )

    if($ConfigurationToUse){
        [XML]$rptproj = Get-Content $RsProjectFile
        $Deployment = $rptproj.Project.PropertyGroup | where { $_.FullPath -eq $ConfigurationToUse }

            $RSConfig = [pscustomobject]@{
                FullPath               = $Deployment.FullPath
                OverwriteDatasets      = $Deployment.OverwriteDatasets
                OverwriteDataSources   = $Deployment.OverwriteDataSources
                TargetReportFolder     = ($Deployment.TargetReportFolder).Trimend("/")
                TargetDatasetFolder    = if ($null -eq $Deployment.TargetDatasetFolder) { $null } else { ($Deployment.TargetDatasetFolder).Trimend("/") }
                TargetDatasourceFolder = if ($null -eq $Deployment.TargetDatasourceFolder) { $null } else { ($Deployment.TargetDatasourceFolder).Trimend("/") }
                TargetReportPartFolder = if ($null -eq $Deployment.TargetReportPartFolder) { $null } else { ($Deployment.TargetReportPartFolder).Trimend("/") }
                TargetServerURL        = $Deployment.TargetServerURL
                RsProjectFolder        = Split-Path -Path $RsProjectFile
            }

        return $RSConfig
        }
    else{[XML]$rptproj = Get-Content $RsProjectFile
        $ConfigurationToUse = $rptproj.Project.PropertyGroup.FullPath | ogv -PassThru
        $Deployment = $rptproj.Project.PropertyGroup | where { $_.FullPath -eq $ConfigurationToUse }

            $RSConfig = [pscustomobject]@{
                FullPath               = $Deployment.FullPath
                OverwriteDatasets      = $Deployment.OverwriteDatasets
                OverwriteDataSources   = $Deployment.OverwriteDataSources
                TargetReportFolder     = ($Deployment.TargetReportFolder).Trimend("/")
                TargetDatasetFolder    = if ($null -eq $Deployment.TargetDatasetFolder) { $null } else { ($Deployment.TargetDatasetFolder).Trimend("/") }
                TargetDatasourceFolder = if ($null -eq $Deployment.TargetDatasourceFolder) { $null } else { ($Deployment.TargetDatasourceFolder).Trimend("/") }
                TargetReportPartFolder = if ($null -eq $Deployment.TargetReportPartFolder) { $null } else { ($Deployment.TargetReportPartFolder).Trimend("/") }
                TargetServerURL        = $Deployment.TargetServerURL
                RsProjectFolder        = Split-Path -Path $RsProjectFile
            }

        return $RSConfig
        }
}