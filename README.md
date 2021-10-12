[![Build status](https://ci.appveyor.com/api/projects/status/github/microsoft/reportingservicestools?branch=master&svg=true)](https://ci.appveyor.com/project/jtarquino/reportingservicestools) [![ReportingServicesTools](https://img.shields.io/powershellgallery/v/ReportingServicesTools.svg?style=flat-square&label=ReportingServicesTools)](https://www.powershellgallery.com/packages/ReportingServicesTools/)
# Reporting Services PowerShell
SQL Server Reporting Services PowerShell utilities 

## Synopsis

This project contains PowerShell scripts that allow you to perform various operations with SQL Server Reporting Services and Power BI Report Server. In order to use the scripts included in this project successfully, please download/clone the entire project as there are dependencies between the scripts. 

All of our scripts were written with the assumption that you will be executing them against SQL Server 2016 Reporting Services default instance (i.e. mssqlserver). However, we understand this may not be the case for you. So for each script, you will see that we have provided a way for you to specify the name and/or version of your SQL Server Reporting Services or Power BI Report Server instance name. Sometimes the version of your SQL Server instance is also required. If you do not provide one, we will assume that you want to execute this against the default instance.   

## PowerShell Version
Please ensure you're running PowerShell version 3.0+
```powershell
$PSVersionTable
```

## Install
```powershell
Invoke-Expression (Invoke-WebRequest https://raw.githubusercontent.com/Microsoft/ReportingServicesTools/master/Install.ps1)
```
or
```powershell
Invoke-Expression (Invoke-WebRequest https://aka.ms/rstools)
```
or
```powershell
Install-Module -Name ReportingServicesTools
```
Note: Using Install-Module is the preferred installation method for most users.
## List of commands

The following is a list of commands which are available for you to use once you follow the steps in the Installation

|Command|Description|
|-------|-----------|
|Backup-RsEncryptionKey|This command backs up the encryption key used by SQL Server Reporting Services to protect sensitive content.|
|Connect-RsReportServer|This command connects to Reporting Services and sets default connection information.|
|Copy-RsSubscription|This command adds a retrieved subscription to an existing report. For use with Get-RsSubscription.|
|Export-RsSubscriptionXml|This command exports a collection of subscriptions to an XML file on disk.|
|Get-RsFolderContent|This command lists all catalog items under a folder.|
|Get-RsDataSource|This command lists information about the data source located at the specified path.|
|Get-RsDeploymentConfig|This command retrieves a list of deployment configurations from a Reporting Services project file.|
|Get-RsItemReference|This command gets the item references of a report or a dataset.|
|Get-RsItemDataSource|This command fetches embedded data sources associated with a report.|
|Get-RsCatalogItemRole|This command retrieves access to catalog items for users or groups.|
|Get-RsRestCacheRefreshPlan|This function fetches a CacheRefreshPlan from a Power BI report.|
|Get-RsRestCacheRefreshPlanHistory|This function fetches the history of CacheRefreshPlan(s) from a Power BI report.|
|Get-RsRestFolderContent|This function fetches data sources related to a catalog item from the Report Server.|
|Get-RsRestItem|This function fetches a catalog item from the Report Server using the REST API.|
|Get-RsRestItemAccessPolicy|This function retrieves access policies to SQL Server Reporting Services Instance or Power BI Report Server Instance from users/groups.|
|Get-RsRestItemDataModelParameters|This function fetches the Data Model Parameters related to a Catalog Item report from the Report Server. This is currently only applicable to Power BI Reports and only from ReportServer October/2020 or higher.|
|Get-RsRestItemDataSource|This command fetches embedded data sources associated with a Paginated report or a Power BI report using the REST Endpoint.|
|Get-RsSubscription|This command retrieves information about subscriptions for a report.|
|Grant-RsRestItemAccessPolicy|This function grants access policies on the SQL Server Reporting Services Instance or Power BI Report Server Instance to the specified user/group, using the REST Endpoint.|
|Grant-RsSystemRole|This command grants access to SQL Server Reporting Services to users or groups. Alias: Grant-AccessToRs|
|Grant-RsCatalogItemRole|This script grants access to catalog items to users or groups. Alias: Grant-AccessOnCatalogItem|
|Import-RsSubscriptionXml|This command imports a collection of subscriptions from an XML file on disk, typically created via Export-RsSubscriptionXml.|
|Initialize-Rs|This command initializes Report Server post-installation. The database MUST be configured and URLs MUST be reserved prior to running this command.|
|New-RsConfigurationSettingObject|This command creates a new RSConfigurationSettingObject which is used to interact with the WMI Provider.|
|New-RsDataSource|This command creates/overwrites the data source to the specified path.|
|New-RsFolder|This command creates a new folder in the specified path.|
|New-RsRestCacheRefreshPlan|This function creates a new CacheRefreshPlan for the specified Power BI Report.|
|New-RsRestCredentialsByUserObject|This command creates a CredentialsByUser object to be used by Set-RsRestItemDataSource command.|
|New-RsRestCredentialsInServerObject|This command creates a CredentialsInServer object to be used by Set-RsRestItemDataSource command.|
|New-RsRestFolder|This command creates a new folder in the specified path using the REST Endpoint.|
|New-RsRestSession|This command creates a session object to be specified for all subsequent calls to the REST Endpoint.|
|New-RsSubscription|This command adds a new subscription to an existing report.|
|New-RsScheduleXml|This command creates an XML string definition of a subscription schedule. For use with the -Schedule parameter or New-RsSubscription.|
|New-RsWebServiceProxy|This command creates a new Web Service Proxy which is used to interact with the SOAP Endpoint.|
|Out-RsCatalogItem|This command downloads a catalog item.|
|Out-RsFolderContent|This command downloads all catalog items in a folder.|
|Out-RsRestFolderContent|This command downloads all catalog items under a folder using the REST Endpoint.|
|Out-RsRestCatalogItem|This command downloads a catalog item using the REST Endpoint.|
|Publish-RsProject|This command deploys a Reporting Services project to a Power BI Report Server.|
|Register-PowerBI|This command registers Power BI information with SQL Server Reporting Services. Alias: Register-RSPowerBI|
|Remove-RsCatalogItem|This command removes the catalog item located at the specified path.|
|Remove-RsRestCatalogItem|This command removes catalog item located at the specified path using the REST Endpoint.|
|Remove-RsRestFolder|This command removes folder located at the specified path using the REST Endpoint.|
|Remove-RSSubscription|This command removes a subscription associated with a report.|
|Restore-RsEncryptionKey|This command restores the encryption key to the SQL Server Reporting Services.|
|Revoke-RsCatalogItemAccess|This command revokes access to a catalog item from users or groups. Alias: Revoke-AccessOnCatalogItem|
|Revoke-RsRestItemAccessPolicy|This function revokes access to catalog items from users/groups, using the REST Endpoint.|
|Revoke-RsSystemAccess|This command revokes access on SQL Server Reporting Services from users or groups. Alias: Revoke-AccessToRs|
|Set-RsDatabase|This command configures the database used by SQL Server Reporting Services.|
|Set-RsDatabaseCredentials|This command configures the credentials to use when connecting to the database used by SQL Server Reporting Services.|
|Set-RsDataSet|This command links a report to  a dataset. Alias: Set-RsDataSetReference|
|Set-RsDataSource|This command updates information associated to a data source. Alias: Set-RsDataSourceReference|
|Set-RsDataSourcePassword|This command sets the password associated with a data source.|
|Set-RsEmailSettings|This command configures the SQL Server Reporting Services email settings to use basic authentication. Alias: Set-RsEmailSettingsAsBasicAuth, Set-RsEmailSettingsAsNoAuth, Set-RsEmailSettingsAsNTLMAuth|
|Set-RsItemDataSource|This command updates embedded data sources associated with a report.|
|Set-RsDataSourceReference|This command overrides the reference of a report or dataset to a shared data source.|
|Set-RsRestItemDataModelParameters|This function updates data sources related to a catalog item from the Report Server.|
|Set-RsRestItemDataSource|This command updates embedded data sources associated with a Paginated report or a Power BI Report using the REST endpoint.|
|Set-RsSharedDataSource|This command links a report or a dataset to a data source.|
|Set-RsUrlReservation|This command configures the SQL Server Reporting Services URLs.|
|Set-PbiRsUrlReservation|This command configures the Power BI Report Server URLs.|
|Set-RsSubscription|This command updates existing subscriptions piped from Get-RsSubscription.|
|Start-RsRestCacheRefreshPlan|This function fetches the CacheRefreshPlan of a report from the Report Server and refreshes them using the REST API.  Alternatively, when a report has multiple CacheRefreshPlans you can specify which CacheRefreshPlan to refresh by passing the Id of the CacheRefreshPlan to the -Id parameter.|
|Test-RsRestItemDataSource|This function fetches the DataSources from a Paginated or Power BI report and tests them to see if the connection can be made.|
|Write-RsCatalogItem|This command uploads a report, a dataset, or a data source using the SOAP Endpoint.|
|Write-RsFolderContent|This uploads all reports, datasets, and data sources in a folder.|
|Write-RsRestCatalogItem|This command uploads a report, a dataset, or a mobile report using the REST Endpoint.|
|Write-RsRestFolderContent|This uploads all reports, datasets, data sources, mobile reports, and Power BI reports in a folder using the REST Endpoint.|

## SQL Server Versions

Some of the commands listed above allow you to optionally specify the version of your SQL Server Reporting Services instance. The following is a list of versions associated with each SQL Server Reporting Services release.

|SQL Server Release|Version|
|------------------|-------|
|SQL Server 2012|11|
|SQL Server 2014|12|
|SQL Server 2016|13|
|SQL Server 2017|14|
|SQL Server 2019|15|

## Motivation

The motivation behind this project was to help users perform SQL Server Reporting Services operations via the command line. 

## API Reference

All of the APIs used by this project are publicly available. There are 2 types of APIs used in this repository: SOAP and WMI. You can find more details about the SOAP API at https://msdn.microsoft.com/en-us/library/ms154052.aspx and the WMI API at https://msdn.microsoft.com/en-us/library/ms152836.aspx. In general, you will use SOAP API for operations you would perform using Report Server and Web Portal whereas you will use WMI API for operations you would perform using Reporting Services Configuration Manager. 

## Local testing and development

To verify the versions installed
```powershell
Get-Module -ListAvailable -Name ReportingServicesTools
```

After you clone the repo you can make local changes and install them in your local machine with
```powershell
Remove-Module ReportingServicesTools
Import-Module .\ReportingServicesTools.psd1
```

For debugging you can set the verbose logging with `$VerbosePreference = "continue"`

## Test

For running tests locally you need a local default instance of  SQL Server Reporting Services and Pester

To install Pester execute
```powershell
Install-Module -Name Pester -RequiredVersion 4.10.1
```

To execute the tests run (this will execute the CatalogItems test only which doesn't change the local Reporting Services Installation)
```powershell
.\Test.ps1
```

## Import Known Issue
Workaround for newer versions of PowerShell (version 7.0+)
```powershell
Import-Module ReportingServicesTools -UseWindowsPowerShell
```
## Style Guidelines

If you have any scripts you would like to share, we request you to please format your scripts according to the guidelines created by the team behind the DSC Resource Kit. (https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md) and the PowerShell verbs https://msdn.microsoft.com/en-us/library/ms714428(v=vs.85).aspx

## Contributions

For contributions please provide the minimum possible increment per Pull Request so it can be reviewed and merged quickly.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
