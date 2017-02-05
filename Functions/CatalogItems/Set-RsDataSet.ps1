# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Set-RsDataSet
{
    <#
        .SYNOPSIS
            Overrides the reference of a report to a shared dataset.
        
        .DESCRIPTION
            Overrides the reference of a report to a shared dataset.
        
        .PARAMETER Path
            Path of the report.
        
        .PARAMETER DataSetName
            Name of the dataset reference to override.
        
        .PARAMETER DataSetPath
            Path to the shared dataset the reference will point to.
        
        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Credential
            Specify the password to use when connecting to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.
        
        .EXAMPLE
            Set-RsDataSet -ReportServerUri 'http://localhost/reportserver_sql2012' -Path /ReportWithDSReference -DataSetName Dataset1 -DataSetPath /Datasets/SampleSet
            
            Description
            -----------
            Sets the dataset reference 'DataSet1' of report /ReportWithDSReference to point to dataset '/DataSets/SampleSet'
        
        .NOTES
            Author:      ???
            Editors:     Friedrich Weinmann
            Created on:  ???
            Last Change: 04.02.2017
            Version:     1.1
            
            Release 1.1 (04.02.2017, Friedrich Weinmann)
            - Fixed Parameter help (Don't poison the name with "(optional)", breaks Get-Help)
            - Standardized the parameters governing the Report Server connection for consistent user experience.
            - Renamed the parameter 'ItemPath' to 'Path', in order to maintain parameter naming conventions. Added the previous name as an alias, for backwards compatiblity.
            - Changed type of parameter 'Path' to System.String[], to better facilitate pipeline & nonpipeline use
            - Redesigned to accept pipeline input from 'Path'
            - Implemented ShouldProcess (-WhatIf, -Confirm)
    
            Release 1.0 (???, ???)
            - Initial Release
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Alias('ItemPath')]
        [Parameter(Mandatory = $true)]
        [string[]] 
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        $DataSetName,

        [Parameter(Mandatory = $true)]
        [string]
        $DataSetPath,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    Begin
    {
        #region Connect to Report Server using Web Proxy
        if (-not $Proxy)
        {
            try
            {
                $splat = @{ }
                if ($PSBoundParameters.ContainsKey('ReportServerUri')) { $splat['ReportServerUri'] = $ReportServerUri }
                if ($PSBoundParameters.ContainsKey('Credential')) { $splat['Credential'] = $Credential }
                $Proxy = New-RSWebServiceProxy @splat
            }
            catch
            {
                throw
            }
        }
        #endregion Connect to Report Server using Web Proxy
    }
    
    Process
    {
        foreach ($item in $Path)
        {
            #region Process each path passed
            if ($PSCmdlet.ShouldProcess($item, "Set datasource's DataSet $DataSetName to $DataSetPath"))
            {
                Write-Verbose "Processing: $item"
                
                try { $dataSets = $Proxy.GetItemReferences($item, "DataSet") }
                catch { throw (New-Object System.Exception("Failed to retrieve item references from Report Server for '$item': $($_.Exception.Message)", $_.Exception)) }
                $dataSetReference = $dataSets | Where-Object { $_.Name -eq $DataSetName } | Select-Object -First 1
                
                if (-not $dataSetReference)
                {
                    throw "$item does not contain a dataSet reference with name $DataSetName"
                }
                
                $proxyNamespace = $dataSetReference.GetType().Namespace
                $dataSetReference = New-Object "$($proxyNamespace).ItemReference"
                $dataSetReference.Name = $DataSetName
                $dataSetReference.Reference = $DataSetPath
                
                Write-Verbose "Set dataSet reference '$DataSetName' of item $item to $DataSetPath"
                $Proxy.SetItemReferences($item, @($dataSetReference))
            }
            #endregion Process each path passed
        }
    }
}

