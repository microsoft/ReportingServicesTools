function Get-RsDeploymentConfig {
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
            TargetReportFolder     = (StripTrailingSlash $Deployment.TargetReportFolder)
            TargetDatasetFolder    = (StripTrailingSlash $Deployment.TargetDatasetFolder)
            TargetDatasourceFolder = (StripTrailingSlash $Deployment.TargetDatasourceFolder)
            TargetReportPartFolder = (StripTrailingSlash $Deployment.TargetReportPartFolder)
            TargetServerURL        = $Deployment.TargetServerURL
            RsProjectFile          = $RsProjectFile
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
            TargetReportFolder     = (StripTrailingSlash $Deployment.TargetReportFolder)
            TargetDatasetFolder    = (StripTrailingSlash $Deployment.TargetDatasetFolder)
            TargetDatasourceFolder = (StripTrailingSlash $Deployment.TargetDatasourceFolder)
            TargetReportPartFolder = (StripTrailingSlash $Deployment.TargetReportPartFolder)
            TargetServerURL        = $Deployment.TargetServerURL
            RsProjectFile          = $RsProjectFile
        }

    return $RSConfig
    }
}