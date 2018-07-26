# Copyright (c) 2017 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsItemDataSource
{
    <#
        .SYNOPSIS
            This script updates embedded data sources for a report or a shared data set on Report Server.
        
        .DESCRIPTION
            This script updates embedded data sources for a report or a shared data set on Report Server.
        
        .PARAMETER RsItem
            Specify the path to report or shared data set.

        .PARAMETER DataSource
            Specify the data sources, associated to this catalog item, to update.
        
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
            $dataSources = Get-RsItemDataSource -RsItem '/report'
            Set-RsItemDataSource -RsItem '/report' -DataSource $datasources

            Description
            -----------
            This command will update data sources associated to '/report' catalog item at the Report Server located at http://localhost/reports.

        .EXAMPLE
            $dataSources = Get-RsItemDataSource -ReportServerUri 'http://remote-machine:8080/reportserver_sql16' -RsItem '/report'
            Set-RsItemDataSource -ReportServerUri 'http://remote-machine:8080/reportserver_sql16' -RsItem '/report' -DataSource $datasources

            Description
            -----------
            This command will update data sources associated to '/report' catalog item at the Report Server located at http://remote-machine:8080/reportserver_sql16.

        .EXAMPLE
            $rsProxy = New-RsWebServiceProxy -ReportServerUri 'http://remote-machine:8080/reportserver_sql16'
            $dataSources = Get-RsItemDataSource -RsProxy $rsProxy -RsItem '/report'
            Set-RsItemDataSource -RsProxy $rsProxy -RsItem '/report -DataSource $datasources

            Description
            -----------
            This command will update data sources associate to '/report' catalog item at the Report Server located at $rsProxy.
        
        .EXAMPLE
            $dataSources = Get-RsItemDataSource -RsItem '/report'
            $dataSources[0].Item.CredentialRetrieval = 'Integrated'
            $dataSources[0].Item.Username = '' # (optional) Clear up username if you had previously specified one.
            $dataSources[0].Item.Password = '' # (optional) clear up password if you had previously specified one.
            Set-RsItemDataSource -RsItem '/report' -DataSource $dataSources

            Description
            -----------
            This command will update 1st data source associated to '/report' catalog item at the Report Server located at http://localhost/reportserver. It will instruct Report Server to use current user's credentials when fetching data.


        .EXAMPLE
            $dataSources = Get-RsItemDataSource -RsItem '/report'
            $dataSources[0].Item.CredentialRetrieval = 'Store'
            $dataSources[0].Item.Username = 'domain\\user'
            $dataSources[0].Item.Password = 'UserPassword'
            $dataSources[0].Item.WindowsCredentials = $true # (optional) Setting this property would make Report Server treat these credentials as Windows Credentials. By default, Report Server treats credentials as SQL Credentials.
            $dataSources[0].Item.ImpersonateUser = $true # (optional) Setting this property would make Report Server connect using the specified credentials but fetch data using the credentials of the user who is using this data source via Report/Shared Dataset.
            Set-RsItemDataSource -RsItem '/report' -DataSource $dataSources

            Description
            -----------
            This command will update 1st data source associated to '/report' catalog item at the Report Server located at http://localhost/reportserver. It will instruct Report Server to use stored credentials when fetching data.

        .EXAMPLE
            $dataSources = Get-RsItemDataSource -RsItem '/report'
            $dataSources[0].Item.CredentialRetrieval = 'Prompt'
            $dataSources[0].Item.Prompt = 'Please enter your credentials.' # (optional) Enter the message you want to display to user when asking for their credentials
            $dataSources[0].Item.WindowsCredentials = $true # (optional) Setting this property would make Report Server treat these credentials as Windows Credentials. By default, Report Server treats credentials as SQL Credentials.
            $dataSources[0].Item.Username = '' # (optional) clear up username if you had previously specified one.
            $dataSources[0].Item.Password = '' # (optional) clear up password if you had previously specified one.
            Set-RsItemDataSource -RsItem '/report' -DataSource $dataSources

            Description
            -----------
            This command will update 1st data source associated to '/report' catalog item at the Report Server located at http://localhost/reportserver. It will instruct Report Server to ask user for credentials when fetching data.

        .EXAMPLE
            $dataSources = Get-RsItemDataSource -RsItem '/report'
            $dataSources[0].Item.CredentialRetrieval = 'None'
            $dataSources[0].Item.Username = '' # (optional) clear up username if you had previously specified one.
            $dataSources[0].Item.Password = '' # (optional) clear up password if you had previously specified one.
            Set-RsItemDataSource -RsItem '/report' -DataSource $dataSources

            Description
            -----------
            This command will update 1st data source associated to '/report' catalog item at the Report Server located at http://localhost/reportserver. It will instruct Report Server to specify no credentials when fetching data.
    #>

    [cmdletbinding()]
    param
    (
        [Alias('ItemPath', 'DataSourcePath', 'Path')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string]
        $RsItem,

        [Parameter(Mandatory = $True)]
        $DataSource,
        
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
        # $DataSource can be one or more data source objects, so validating each one of the objects
        foreach ($ds in $DataSource)
        {
            if ($ds.Name -eq $null -or $ds.Item -eq $null)
            {
                throw "Invalid data source specified: $ds!"
            }
            elseif ($ds.Item.Reference -ne $null)
            {
                throw "Please use Set-RsDataSource to update shared data sources!"
            }
            elseif ($ds.Item.CredentialRetrieval -like 'STORE')
            {
                if (-not ($ds.Item.UserName))
                {
                    throw "Username and password must be specified when CredentialRetrieval is set to Store!"
                }
            }
            else
            {
                if ($ds.Item.UserName -or $ds.Item.Password)
                {
                    throw "Username and/or password can be specified only when CredentialRetrieval is Store!"
                }
                
                if ($ds.Item.ImpersonateUser)
                {
                    throw "ImpersonateUser can be set to true only when CredentialRetrieval is Store!"
                }
            }
        }

        try
        {
            Write-Verbose "Updating data sources associated to $RsItem..."
            $Proxy.SetItemDataSources($RsItem, $DataSource)
            Write-Verbose "Data source updated successfully!"
        }
        catch
        {
            throw (New-Object System.Exception("Exception while updating datasources! $($_.Exception.Message)", $_.Exception))
        }
    }
}
