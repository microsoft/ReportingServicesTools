function Publish-RsProject
{
    <#
        .SYNOPSIS
            This command deploys a Reporting Services project to a Power BI Report Server.

        .DESCRIPTION
            This function deploys a full SSRS project to a Power BI Report Server.

        .PARAMETER ProjectFolder
            Specify the location of the SSRS project file whose deployment profiles should be fetched.

        .PARAMETER OverwriteDatasets
            Replace existing shared datasets when True. When False, leave existing datasets and their references unchanged.
            Accepts True or False from project configuration. Defaults to True for compatibility.

        .PARAMETER OverwriteDataSources
            Replace existing shared data sources when True. When False, leave existing data sources unchanged.
            Accepts True or False from project configuration. Defaults to False for compatibility.

        .EXAMPLE
            Get-RsDeploymentConfig -RsProjectFile 'C:\Users\Aaron\source\repos\Finance\Financial Reports\SSRS_FR\SSRS_FR.rptproj' |
            Add-Member -PassThru -MemberType NoteProperty -Name ReportPortal -Value 'http://localhost/PBIRSportal/' |
            Publish-RsProject

            Description
            -----------
            Get-RsDeploymentConfig prompts the user to select which deployment configuration to use from 
            the 'C:\Users\Aaron\source\repos\Finance\Financial Reports\SSRS_FR\SSRS_FR.rptproj' project file.  These settings 
            are piped to the Add-Member where the ReportPortal property is added and set to 'http://localhost/PBIRSportal/'.
            The settings are then piped to the Publish-RsProject function, which deploys all project files using all applicable 
            settings from the deployment configuration chosen.
        
        .EXAMPLE
            $RSConfig = Get-RsDeploymentConfig -RsProjectFile 'C:\Users\Aaron\source\repos\Financial Reports\SSRS_FR\SSRS_FR.rptproj' -ConfigurationToUse Dev01
            Add-Member -PassThru -MemberType NoteProperty -Name ReportPortal -Value 'http://localhost/PBIRSportal/'
            $RSConfig | Publish-RsProject

            Description
            -----------
            Retrieves all deployment settings for the 'Dev01' deployment configuration, adds a NoteProperty for the ReportPortal to 
            deploy to, and then deploys all the project files by calling Publish-RsProject and passing in all the settings in 
            the $RSConfig variable.
        
        .EXAMPLE
            Publish-RsProject -TargetServerURL 'http://localhost/PBIRServer/' -ReportPortal 'http://localhost/PBIRSportal/' -TargetReportFolder /Finance -TargetDatasourceFolder '/Finance/Data Sources' -TargetDatasetFolder /Finance/DataSets -RsProjectFolder 'C:\Users\Aaron\source\repos\Financial Reports\SSRS_FR\'

            Description
            -----------
            Deploys the project files found in the 'C:\Users\Aaron\source\repos\Financial Reports\SSRS_FR\' to the target locations 
            specified in the parameters list.  Use this option when you want to deploy to a location not already listed in 
            the .rptproj project file.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$RsProjectFolder,

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
        [ValidateSet('True', 'False')]
        [string]$OverwriteDatasets = 'True',
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('True', 'False')]
        [string]$OverwriteDataSources = 'False',
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$FullPath,
        
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$ReportPortal
        )

    if (-not $PSCmdlet.ShouldProcess($ReportPortal, "Deploy project from $RsProjectFolder"))
    {
        return
    }

    function Test-DeploymentItemExists
    {
        param ([string]$ItemPath)

        try
        {
            $null = Get-RsRestItem -ReportPortalUri $ReportPortal -RsItem $ItemPath -ErrorAction Stop
            return $true
        }
        catch
        {
            $exception = $_.Exception
            while ($null -ne $exception)
            {
                if ($null -ne $exception.Response -and $exception.Response.StatusCode -eq 404)
                {
                    return $false
                }
                $exception = $exception.InnerException
            }
            throw
        }
    }

    $replaceDatasets = $OverwriteDatasets -eq 'True'
    $replaceDataSources = $OverwriteDataSources -eq 'True'

    Write-Host "`$RsProjectFolder = '$RsProjectFolder' being used is
    This deployment is going to happen using the following settings...
    "
    $RSConfig | FL

    <# RsFolder Structure
        Make sure all the folders needed already exist with the following code. #>
    Write-Host "
    Beginning deployment.
    Building folder structures...
    "
    if(-not ($TargetReportFolder).StartsWith("/")){$TargetReportFolder = '/'+$TargetReportFolder}
    if(-not ($TargetDatasetFolder).StartsWith("/")){$TargetDatasetFolder = '/'+$TargetDatasetFolder}
    if(-not ($TargetDatasourceFolder).StartsWith("/")){$TargetDatasourceFolder = '/'+$TargetDatasourceFolder}

    $TargetReportFolder, $TargetDatasourceFolder, $TargetDatasetFolder | 
    sort -Unique | 
    foreach {
        MakeDeploymentFolders -RsFolder $_ -ReportPortal $ReportPortal
    }

    <# Deploy Data Sources #>
    Write-Host "
    Deploying Data Sources to $($TargetDatasourceFolder)...
    "
    foreach($RDS in dir -Path $RsProjectFolder -Filter *.rds)
    {
        [xml]$sourceDefinition = Get-Content -LiteralPath $RDS.FullName -ErrorAction Stop
        $sourceName = [string]$sourceDefinition.RptDataSource.Name
        if ([string]::IsNullOrEmpty($sourceName))
        {
            throw "Data source name not found in '$($RDS.FullName)'."
        }
        $sourcePath = "$($TargetDatasourceFolder.TrimEnd('/'))/$sourceName"
        if (-not $replaceDataSources -and (Test-DeploymentItemExists -ItemPath $sourcePath))
        {
            Write-Verbose "Leaving existing data source $sourcePath unchanged."
            continue
        }
        Write-RsRestCatalogItem -Path "$RsProjectFolder\$($RDS.Name)" -ReportPortalUri $ReportPortal -RsFolder $TargetDatasourceFolder -Overwrite:$replaceDataSources -ErrorAction Stop
    }

    <# Deploy Data Sets & set their Data Source References. #>
    Write-Host "
    Deploying DataSets to $TargetDatasetFolder...
    "
    dir -Path $RsProjectFolder  -Filter *.rsd | 
    foreach{
        $datasetPath = "$($TargetDatasetFolder.TrimEnd('/'))/$($_.BaseName)"
        if (-not $replaceDatasets -and (Test-DeploymentItemExists -ItemPath $datasetPath))
        {
            Write-Verbose "Leaving existing dataset $datasetPath unchanged."
            return
        }

        [XML]$dsetref = Get-Content "$RsProjectFolder\$($_.Name)"
        $DataSetQuery = $dsetref.SharedDataSet.DataSet.Query

        $DSetConfig = [pscustomobject]@{
            DataSourceReference = $dsetref.SharedDataSet.DataSet.Query.DataSourceReference
            CommandText         = $dsetref.SharedDataSet.DataSet.Query.CommandText
            CommandType         = $dsetref.SharedDataSet.DataSet.Query.CommandType
            DataSetParameters   = $dsetref.SharedDataSet.DataSet.Query.DataSetParameters
        }

        Write-RsRestCatalogItem -Path "$RsProjectFolder\$($_.Name)" -ReportPortalUri $ReportPortal -RsFolder $TargetDatasetFolder -Overwrite:$replaceDatasets -ErrorAction Stop
        Set-RsDataSourceReference -ReportServerUri $TargetServerURL -Path $datasetPath -DataSourceName DataSetDataSource -DataSourcePath "$($TargetDatasourceFolder.TrimEnd('/'))/$($DSetConfig.DataSourceReference)"
    }

    <# Deploy the Reports #>
    Write-Host "Deploying the report files to $TargetReportFolder...
    "
    dir -Path $RsProjectFolder -Filter *.rdl | 
    foreach{
        $ReportName=$_.BaseName
        Write-RsCatalogItem -Path "$RsProjectFolder\$($_.Name)" -ReportServerUri $TargetServerURL -RsFolder $TargetReportFolder -Overwrite
        "$($_.BaseName)";
        Get-RsRestItemDataSource -ReportPortalUri $ReportPortal -RsItem "$TargetReportFolder/$ReportName" | 
        where {$_.IsReference -eq $true} | 
        foreach{
            Set-RsDataSourceReference -ReportServerUri $TargetServerURL -Path "$TargetReportFolder/$ReportName" -DataSourceName $_.Name -DataSourcePath "$($TargetDatasourceFolder)/$($_.Name)"
        }
    }

    <# Now read in the DataSet References directly from the report files and set them on the server #>
    if($TargetDatasetFolder -ne $TargetReportFolder -and (Get-RsRestFolderContent -ReportPortalUri $ReportPortal -RsFolder $TargetDatasetFolder).Count -gt 0){
        $Reports = dir -Path $RsProjectFolder -Filter *.rdl

        foreach($Report in $Reports)
        {
        [XML]$ReportDSetRef = Get-Content $Report.FullName
        foreach($SDS in $ReportDSetRef.Report.DataSets.DataSet){
            if($SDS.SharedDataSet.SharedDataSetReference){
                Set-RsDataSetReference -ReportServerUri $TargetServerURL -Path "$TargetReportFolder/$($Report.BaseName)" -DataSetName $SDS.Name -DataSetPath "$TargetDatasetFolder/$($SDS.SharedDataSet.SharedDataSetReference)"
                }
            }
        }
    }

}
