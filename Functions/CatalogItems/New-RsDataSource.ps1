# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsDataSource
{
    <#
    .SYNOPSIS
        This script creates a new data source on Report Server.

    .DESCRIPTION
        This script creates a new data source on Report Server. 

    .PARAMETER ReportServerUri (optional)
        Specify the Report Server URL to your SQL Server Reporting Services Instance.

    .PARAMETER ReportServerUsername (optional)
        Specify the user name to use when connecting to your SQL Server Reporting Services Instance.

    .PARAMETER ReportServerPassword (optional)
        Specify the password to use when connecting to your SQL Server Reporting Services Instance.

    .PARAMETER Proxy (optional)
        Specify the Proxy to use when communicating with Reporting Services server. If Proxy is not specified, connection to Report Server will be created using ReportServerUri, ReportServerUsername and ReportServerPassword.

    .PARAMETER Destination
        Specify the location where the data source should be created at 

    .PARAMETER Name
        Specify the name of the the new data source

    .PARAMETER Extension
        Specify the extension of the new data source (e.g. SQL, SQLAZURE, OLEDB, OLEDB-MD, etc.) For full list, please look at <Extensions>\<Data> node in C:\Program Files\Microsoft SQL Server\MSRS{VersionNumber}.{InstanceName}\Reporting Services\ReportServer\RSReportServer.config.

    .PARAMETER ConnectionString
        Specify the connection string for the new data source.

    .PARAMETER CredentialRetrieval
        Specify the type of authentication to use: None, Prompt, Integrated, Store. Please view https://msdn.microsoft.com/en-us/library/reportservice2010.datasourcedefinition.credentialretrieval.aspx for more details on each option. 

    .PARAMETER Prompt (optional)
        Specify the prompt to display to user.  

    .PARAMETER Username (optional)
        Specify the username to use when connecting to the data source.

    .PARAMETER Password (optional)
        Specify the password to use when connecting to the data source.

    .PARAMETER ImpersonateUser (optional)
        Specify whether to impersonate using the credentials specify when connecting to the data source. You must specify Username and Password if you specify this switch.

    .PARAMETER WindowsCredentials (optional)
        Specify whether the credentials specified are Windows credentials or not. You must specify Username and Password if you specify this switch.

    .PARAMETER Overwrite (optional)
        Specify whether to overwrite data source if an existing data source with same name exists at the specified destination 

    .EXAMPLE 
        New-RsDataSource -Destination '/' -Name 'My Data Source' -Extension 'SQL' -ConnectionString 'Data Source=.;Initial Catalog=MyDb;' -CredentialRetrieval 'None' 
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. When connecting to this data source, it will use not specify any credentials.

    .EXAMPLE 
        New-RsDataSource -Destination '/' -Name 'My Data Source' -Extension 'SQL' -ConnectionString 'Data Source=.;Initial Catalog=MyDb;' -CredentialRetrieval 'Integrated' 
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. When connecting to this data source, it will assume current user's identity.

    .EXAMPLE 
        New-RsDataSource -Destination '/' -Name 'My Data Source' -Extension 'SQL' -ConnectionString 'Data Source=.;Initial Catalog=MyDb;' -CredentialRetrieval 'Prompt' -Prompt 'Please enter your username and password' 
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. When connecting to this data source, it will prompt user for Database credentials.

    .EXAMPLE 
        New-RsDataSource -Destination '/' -Name 'My Data Source' -Extension 'SQL' -ConnectionString 'Data Source=.;Initial Catalog=MyDb;' -CredentialRetrieval 'Prompt' -Prompt 'Please enter your username and password' -WindowsCredentials 
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. When connecting to this data source, it will prompt user for Windows credentials.

    .EXAMPLE 
        New-RsDataSource -Destination '/' -Name 'My Data Source' -Extension 'SQL' -ConnectionString 'Data Source=.;Initial Catalog=MyDb;' -CredentialRetrieval 'Store' -Username 'sa' -Password '<Enter Password>' -ImpersonateUser 
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. When connecting to this data source, the specified credentials will be treated as Database credentials.

    .EXAMPLE 
        New-RsDataSource -Destination '/' -Name 'My Data Source' -Extension 'SQL' -ConnectionString 'Data Source=.;Initial Catalog=MyDb;' -CredentialRetrieval 'Store' -Username 'sa' -Password '<Enter Password>' -ImpersonateUser -WindowsCredentials
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. When connecting to this data source, the specified credentials will be treated as Windows credentials.
    
    .EXAMPLE 
        New-RsDataSource -Destination '/' -Name 'My Data Source' -Extension 'SQL' -ConnectionString 'Data Source=.;Initial Catalog=MyDb;' -CredentialRetrieval 'None' -Overwrite 
        Description
        -----------
        This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. If data source already exists, it will be overwriten.
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
        $Destination,

        [Parameter(Mandatory=$True)]
        [string]
        $Name,

        [Parameter(Mandatory=$True)]
        [string]
        $Extension,

        [Parameter(Mandatory=$True)]
        [string]
        $ConnectionString,

        [Parameter(Mandatory=$True)]
        [ValidateSet("None", "Prompt", "Integrated", "Store")]
        [string]
        $CredentialRetrieval,

        [string]
        $Username,

        [string]
        $Password,

        [string]
        $Prompt,

        [switch]
        $ImpersonateUser,

        [switch]
        $WindowsCredentials,

        [Switch]
        $Overwrite
    )

    if (-not $Proxy)
    {
        $Proxy = New-RsWebServiceProxy -ReportServerUri $ReportServerUri -Username $ReportServerUsername -Password $ReportServerPassword
    }

    if ($CredentialRetrieval.ToUpper() -eq 'STORE')
    {
        if ([System.String]::IsNullOrEmpty($Username) -or [System.String]::IsNullOrEmpty($Password))
        {
            throw "Username and password must be specified when CredentialRetrieval is Store!"
        }
    }

    # validating Extension specified by the user
    Write-Verbose "Retrieving data extensions..."
    $dataExtensions = $Proxy.ListExtensions("Data")
    $isExtensionValid = $false
    foreach ($dataExtension in $dataExtensions)
    {
        Write-Verbose "`t$($dataExtension.Name)`n"
        if ($dataExtension.Name -eq $Extension)
        {
            $isExtensionValid = $True
            break
        }
    }

    if (-not $isExtensionValid)
    {
        throw "Extension specified is not supported by the report server!"
    }

    $namespace = $proxy.GetType().Namespace
    $datasourceDataType = ($namespace + '.DataSourceDefinition')
    $credentialRetrievalEnumType = ($namespace + '.CredentialRetrievalEnum')

    $datasource = New-Object ($datasourceDataType)
    $datasource.ConnectString = $ConnectionString
    $datasource.Enabled = $true
    $datasource.Extension = $Extension
    $datasource.WindowsCredentials = $WindowsCredentials
    $datasource.Prompt = $Prompt

    if ($CredentialRetrieval.ToUpper().Equals('STORE'))
    {
        $datasource.UserName = $Username
        $datasource.Password = $Password
        $datasource.ImpersonateUser = $ImpersonateUser
    }

    try
    {
        $datasource.CredentialRetrieval = [Enum]::Parse($credentialRetrievalEnumType, $CredentialRetrieval)
    }
    catch
    {
        Write-Error "Exception occurred while converting credential retrieval to enum! $($_.Exception.Message)"
        break
    }

    try
    {
        Write-Verbose "Creating data source..."
        $Proxy.CreateDataSource($Name, $Destination, $Overwrite, $datasource, $null)
        Write-Information "Data source created successfully!"
    }
    catch
    {
       Write-Error "Exception occurred while creating data source! $($_.Exception.Message)"
       break 
    }
}
