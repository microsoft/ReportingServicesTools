# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<#

.SYNOPSIS
    Overrides the reference of a report to a shared dataset. 

.DESCRIPTION
    Overrides the reference of a report to a shared dataset. 

.PARAMETER ReportServerUri (optional)
    Specify the Report Server URL to your SQL Server Reporting Services Instance.
    Has to be provided if proxy is not provided.

.PARAMETER ReportServerUsername (optional)
    Specify the user name to use when connecting to your SQL Server Reporting Services Instance.

.PARAMETER ReportServerPassword (optional)
    Specify the password to use when connecting to your SQL Server Reporting Services Instance.

.PARAMETER Proxy (optional)
    Report server proxy to use. 
    Has to be provided if ReportServerUri is not provided.

.PARAMETER ItemPath 
    Path of the report.

.PARAMETER DataSetName 
    Name of the dataset reference to override. 

.PARAMETER DataSetPath
    Path to the shared dataset the reference will point to.

.EXAMPLE
    
    Set-RsDataSet -ReportServerUri 'http://localhost/reportserver_sql2012' -ItemPath /ReportWithDSReference -DataSetName Dataset1 -DataSetPath /Datasets/SampleSet

    Description
    -----------
    Sets the dataset reference 'DataSet1' of report /ReportWithDSReference to point to dataset '/DataSets/SampleSet' 
#>


function Set-RsDataSet
{
    param(
        [string]
        $ReportServerUri = 'http://localhost/reportserver',
        
        [string]
        $ReportServerUsername,
        
        [string]
        $ReportServerPassword,
        
        $Proxy,

        [Parameter(Mandatory=$true)]
        [string] 
        $ItemPath,

        [Parameter(Mandatory=$true)]
        [string]
        $DataSetName,

        [Parameter(Mandatory=$true)]
        [string]
        $DataSetPath
    )

    if(-not $Proxy)
    {
        $Proxy = New-RsWebServiceProxy -ReportServerUri $ReportServerUri -Username $ReportServerUsername -Password $ReportServerPassword 
    }

    $dataSets = $Proxy.GetItemReferences($ItemPath, "DataSet")
    $dataSetReference = $dataSets | Where-Object {$_.Name -eq $DataSetName} | Select-Object -First 1 

    if(-not $dataSetReference)
    {
        throw "$ItemPath does not contain a dataSet reference with name $DataSetName"
    }

    $proxyNamespace = $dataSetReference.GetType().Namespace
    $dataSetReference = New-Object ("$($proxyNamespace).ItemReference")
    $dataSetReference.Name = $DataSetName
    $dataSetReference.Reference = $DataSetPath

    Write-Verbose "Set dataSet reference '$DataSetName' of item $ItemPath to $DataSetPath"
    $Proxy.SetItemReferences($ItemPath, @($dataSetReference))
}

