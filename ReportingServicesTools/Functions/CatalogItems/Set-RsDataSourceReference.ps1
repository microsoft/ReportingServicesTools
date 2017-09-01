# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Set-RsDataSourceReference
{
    <#
        .SYNOPSIS
            Overrides the reference of a report or dataset to a shared data source.
        
        .DESCRIPTION
            Overrides the reference of a report or dataset to a shared data source.
        
        .PARAMETER Path
            Path of the report or dataset.
        
        .PARAMETER DataSourceName
            Name of the datasource reference to override.
        
        .PARAMETER DataSourcePath
            Path to the shared data source the reference will point to.
        
        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.
        
        .EXAMPLE
            Set-RsDataSourceReference -Path /DataSet -DataSourceName DataSource1 -DataSourcePath /Datasources/SampleSource
            
            Description
            -----------
            Sets the dataset reference 'DataSource1' of dataset '/DataSet' to point to datasource '/Datasources/SampleSource'
    #>
    [CmdletBinding()]
    param (
        [Alias('ItemPath')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] 
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        $DataSourceName,

        [Parameter(Mandatory = $true)]
        [string]
        $DataSourcePath,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }
    
    Process
    {
        foreach ($item in $Path)
        {
            # For when running on Windows 6.1 with a permissive erroraction setting
            $dataSets = $null
            $dataSourceReference = $null
            
            try
            {
                $dataSets = $Proxy.GetItemReferences($item, "DataSource")
            }
            catch
            {
                throw (New-Object System.Exception("Failed to retrieve datasource item references for '$item': $($_.Exception.Message)", $_.Exception))
            }
            $dataSourceReference = $dataSets | Where-Object { $_.Name -eq $DataSourceName } | Select-Object -First 1
            
            if (-not $dataSourceReference)
            {
                throw "$item does not contain a dataSource reference with name $DataSourceName"
            }
            
            $proxyNamespace = $dataSourceReference.GetType().Namespace
            $dataSourceReference = New-Object "$($proxyNamespace).ItemReference"
            $dataSourceReference.Name = $DataSourceName
            $dataSourceReference.Reference = $DataSourcePath
            
            Write-Verbose "Set dataSource reference '$DataSourceName' of item $item to $DataSourcePath"
            try
            {
                $Proxy.SetItemReferences($item, @($dataSourceReference))
            }
            catch
            {
                throw (New-Object System.Exception("Failed to update datasource item references for '$item': $($_.Exception.Message)", $_.Exception))
            }
        }
    }
}

New-Alias -Name "Set-RsSharedDataSource" -Value Set-RsDataSourceReference -Scope Global
