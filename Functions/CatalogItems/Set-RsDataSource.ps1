# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsDataSource
{
    <#
    .SYNOPSIS
        This script updates information about a data source on Report Server.

    .DESCRIPTION
        This script updates information about a data source on Report Server that was retrieved using Get-RsDataSource.  

    .PARAMETER ReportServerUri (optional)
        Specify the Report Server URL to your SQL Server Reporting Services Instance.

    .PARAMETER ReportServerUsername (optional)
        Specify the user name to use when connecting to your SQL Server Reporting Services Instance.

    .PARAMETER ReportServerPassword (optional)
        Specify the password to use when connecting to your SQL Server Reporting Services Instance.

    .PARAMETER Proxy (optional)
        Specify the Proxy to use when communicating with Reporting Services server. If Proxy is not specified, connection to Report Server will be created using ReportServerUri, ReportServerUsername and ReportServerPassword.

    .PARAMETER Name
        Specify the name of the the Data Source

    .PARAMETER DataSourceDefinition
        Specify the data source definition of the Data Source to update 

    .EXAMPLE 
        New-RsDataSource -Name 'My Data Source' -DataSourceDefinition $dataSourceDefinition 
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. When connecting to this data source, it will use not specify any credentials.
    #>

    [cmdletbinding()]
    param
    (
        [string]
        $ReportServerUri = 'http://localhost/reportserver',

        [string]
        $ReportServerUsername,

        [string]
        $ReportServerPassword,

        $Proxy,

        [Parameter(Mandatory=$True)]
        [string]
        $Name,

        [Parameter(Mandatory=$True)]
        [string]
        $DataSourceDefinition
    )

    if (-not $Proxy)
    {
        $Proxy = New-RsWebServiceProxy -ReportServerUri $ReportServerUri -Username $ReportServerUsername -Password $ReportServerPassword
    }

    if ($DataSourceDefinition.GetType().Name -ne 'DataSourceDefinition')
    {
        throw 'Invalid object specified for DataSourceDefinition!'
    }

    if ($CredentialRetrieval.ToUpper() -eq 'STORE')
    {
        if ([System.String]::IsNullOrEmpty($DataSourceDefinition.UserName) -or [System.String]::IsNullOrEmpty($DataSourceDefinition.Password))
        {
            throw "Username and password must be specified when CredentialRetrieval is set to Store!"
        }
    }
    else 
    {
        if (-not [System.String]::IsNullOrEmpty($DataSourceDefinition.UserName) -or
            -not [System.String]::IsNullOrEmpty($DataSourceDefinition.Password))
        {
            throw "Username and/or password can be specified only when CredentialRetrieval is Store!"
        }

        if ($DataSourceDefinition.ImpersonateUser)
        {
            throw "ImpersonateUser can be set to true only when CredentialRetrieval is Store!"
        }
    }

    # validating extension specified by the user is supported
    Write-Verbose "Retrieving data extensions..."
    $dataExtensions = $Proxy.ListExtensions("Data")
    $isExtensionValid = $false
    foreach ($dataExtension in $dataExtensions)
    {
        Write-Verbose "`t$($dataExtension.Name)`n"
        if ($dataExtension.Name -eq $DataSourceDefinition.Extension)
        {
            $isExtensionValid = $True
            break
        }
    }

    if (-not $isExtensionValid)
    {
        throw "Extension specified is not supported by the report server!"
    }

    try
    {
        Write-Verbose "Updating data source..."
        $Proxy.SetDataSourceContents($Name, $DataSourceDefinition)
        Write-Information "Data source updated successfully!"
    }
    catch
    {
       Write-Error "Exception occurred while updating data source! $($_.Exception.Message)"
       break 
    }
}
