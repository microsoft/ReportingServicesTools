# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

<#

.SYNOPSIS
    Overrides the reference of a report or dataset to a shared data source. 

.DESCRIPTION
    Overrides the reference of a report or dataset to a shared data source. 

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
    Path to DataSource.

.PARAMETER Password 
    Password to set.

.EXAMPLE
    
    Set-RsDataSourcePassword -ReportServerUri 'http://localhost/reportserver_sql2012' -ItemPath /DataSource1 -Password SuperSecretPassword

    Description
    -----------
    Sets the password for the datasource /DataSource1 to 'SuperSecretPassword'
#>


function Set-RsDataSourcePassword
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
        $Password
    )

    if(-not $Proxy)
    {
        $Proxy = New-RSWebServiceProxy -ReportServerUri $ReportServerUri -Username $ReportServerUsername -Password $ReportServerPassword 
    }

    $dataSourceContent = $Proxy.GetDataSourceContents($ItemPath)
    $dataSourceContent.Password = $Password
    Write-Output "Setting password of datasource $ItemPath"
    $Proxy.SetDataSourceContents($ItemPath, $dataSourceContent)
}

