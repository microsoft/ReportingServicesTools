function Deploy-RsProject
{
    <#
        .SYNOPSIS
            This script deploys a Reporting Services project to a Power BI Report Server.

        .DESCRIPTION
            This function deploys a full SSRS project to a Power BI Report Server.

        .PARAMETER RsProjectFile
            Specify the location of the SSRS project file whose deployment profiles should be fetched.

        .EXAMPLE
            Deploy-RsProject -ProjectFile 'C:\Users\Aaron\source\repos\Finance\Financial Reports\SSRS_FR\SSRS_FR.rptproj'

            Description
            -----------
            Deploys all project files using all applicable settings from the project file.
        
        .EXAMPLE
            $RSConfig = Get-RsDeploymentConfig -RsProjectFile 'C:\Users\Aaron\source\repos\Financial Reports\SSRS_FR\SSRS_FR.rptproj' -ConfigurationToUse Dev01 $RSConfig |
            Add-Member -PassThru -MemberType NoteProperty -Name ReportPortal -Value 'http://localhost/PBIRSportal/'
            $RSConfig | Deploy-RsProject

            Retrieves all deployment settings for the 'Dev01' deployment configuration, adds a NoteProperty for the ReportPortal to deploy to, and then deploys all the project files by calling Deploy-RsProject and passing in all the settings in the $RSConfig variable.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$RsProjectFile,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$TargetServerURL,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$TargetReportFolder,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$TargetDatasourceFolder,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$TargetDatasetFolder,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$TargetReportPartFolder,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$OverwriteDatasets,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$OverwriteDataSources,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$FullPath,
        
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$ReportPortal
        )

[string]$ProjectFolder=Split-Path -Path $RsProjectFile

"`$ProjectFolder = '$ProjectFolder'"
"This deployment is going to happen using the $ConfigurationToUse profile.
"
$RSConfig | FL

<# RsFolder Structure
    Make sure all the folders needed already exist with the following code. #>
Write-Host "
Beginning deployment.
Building folder structures...
"

$TargetReportFolder, $TargetDatasourceFolder, $TargetDatasetFolder | 
sort -Unique | 
foreach {
    MakeDeploymentFolders -RsFolder $_ -ReportPortal $ReportPortal
}

<# Deploy Data Sources #>
Write-Host "
Deploying Data Sources to $($TargetDatasourceFolder)...
"
foreach($RDS in dir -Path $ProjectFolder -Filter *.rds)
{
    try{ Write-Verbose "Checking for $TargetDatasourceFolder/$($_.BaseName)"
        Get-RsRestItem -ReportPortalUri $ReportPortal -RsItem "$TargetDatasourceFolder/$($RDS.BaseName)" | ft -AutoSize
    }
    catch{ Write-Verbose 'Did not find Data Source'
        Write-RsRestCatalogItem -Path "$ProjectFolder\$($RDS.Name)" -ReportPortalUri $ReportPortal -RsFolder $TargetDatasourceFolder
    }
}

<# Deploy Data Sets & set their Data Source References. #>
Write-Host "
Deploying DataSets to $TargetDatasetFolder...
"
dir -Path $ProjectFolder  -Filter *.rsd | 
foreach{
    [XML]$dsetref = Get-Content "$ProjectFolder\$($_.Name)"
    $DataSetQuery = $dsetref.SharedDataSet.DataSet.Query

    $DSetConfig = [pscustomobject]@{
        DataSourceReference = $dsetref.SharedDataSet.DataSet.Query.DataSourceReference
        CommandText         = $dsetref.SharedDataSet.DataSet.Query.CommandText
        CommandType         = $dsetref.SharedDataSet.DataSet.Query.CommandType
        DataSetParameters   = $dsetref.SharedDataSet.DataSet.Query.DataSetParameters
    }

    Write-RsRestCatalogItem -Path "$ProjectFolder\$($_.Name)" -ReportPortalUri $ReportPortal -RsFolder $TargetDatasetFolder -Overwrite
    Set-RsDataSourceReference -ReportServerUri $TargetServerURL -Path "$TargetDatasetFolder/$($_.BaseName)" -DataSourceName DataSetDataSource -DataSourcePath "$($TargetDatasourceFolder)/$($DSetConfig.DataSourceReference)"
}

<# Deploy the Reports #>
Write-Host "Deploying the report files to $TargetReportFolder...
"
dir -Path $ProjectFolder -Filter *.rdl | 
foreach{
    $ReportName=$_.BaseName
    Write-RsCatalogItem -Path "$ProjectFolder\$($_.Name)" -ReportServerUri $TargetServerURL -RsFolder $TargetReportFolder -Overwrite
    "$($_.BaseName)";
    Get-RsRestItemDataSource -ReportPortalUri $ReportPortal -RsItem "$TargetReportFolder/$ReportName" | 
    foreach{
        Set-RsDataSourceReference -ReportServerUri $TargetServerURL -Path "$TargetReportFolder/$ReportName" -DataSourceName $_.Name -DataSourcePath "$($TargetDatasourceFolder)/$($_.Name)"
    }
}

<# Now read in the DataSet References directly from the report files and set them on the server #>
if($TargetDatasetFolder -ne $TargetReportFolder){
    $Reports = dir -Path $ProjectFolder -Filter *.rdl

    foreach($Report in $Reports)
    {
    [XML]$ReportDSetRef = Get-Content $Report.FullName
    foreach($SDS in $ReportDSetRef.Report.DataSets.DataSet){
        Set-RsDataSetReference -ReportServerUri $TargetServerURL -Path "$TargetReportFolder/$($Report.BaseName)" -DataSetName $SDS.Name -DataSetPath "$TargetDatasetFolder/$($SDS.SharedDataSet.SharedDataSetReference)"
        }
    }
}


}