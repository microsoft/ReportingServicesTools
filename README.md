[![Build status](https://ci.appveyor.com/api/projects/status/github/microsoft/reportingservicestools?branch=master&svg=true)](https://ci.appveyor.com/project/jtarquino/reportingservicestools)
# Reporting Services PowerShell
SQL Server Reporting Services PowerShell utilities 

## Synopsis

This project contains PowerShell scripts that allows you to perform various operations with SQL Server Reporting Services. In order to use the scripts included in this project successfully, please download/clone the entire project as there are dependencies between the scripts. 

All of our scripts were written with the assumption that you will be executing them against SQL Server 2016 Reporting Services default instance (i.e. mssqlserver). However, we understand this may not be the case for you. So for each script, you will see that we have provided a way for you to specify the name and/or version of your SQL Server Reporting Services instance name. Sometimes the version of your SQL Server instance is also required. If you do not provide one, we will assume that you want to execute this against the default instance.   

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

## List of commands

The following is a list of commands which are available for you to use once you follow the steps in Installation

|Command|Description|
|-------|-----------|
|Backup-RsEncryptionKey|This command backs up the encryption key used by SQL Server Reporting Services to protect sensitive content.|
|Export-RsSubscriptionXml|This command exports a collection of subscriptions to an XML file on disk.|
|Copy-RsSubscription|This command adds a retrieved subscription to an existing report. For use with Get-RsSubscription.|
|Get-RsFolderContent|This command lists all catalog items under a folder.|
|Get-RsDataSource|This command lists information about data source located at the specified path.|
|Get-RsItemReferences|This command sets the item references of a report or a dataset.|
|Get-RsItemDataSource|This command fetches embedded data sources associated to a report.|
|Get-RsCatalogItemRole|This command retrieves access on catalog items for users or groups.|
|Get-RsRestItemDataSource|This command fetches embedded data sources associated to a Paginated report or a Power BI report using the REST Endpoint.|
|Get-RsSubscription|This command retrieves information about subscriptions for a report.|
|Grant-AccessOnCatalogItem|This command grants access on catalog item to users or groups.|
|Grant-AccessToRs|This command grants access to SQL Server Reporting Services to users or groups.|
|Import-RsSubscriptionXml|This command imports a collection of subscriptions from an XML file on disk, typically created via Export-RsSubscriptionXml.|
|Initialize-Rs|This command initializes Report Server post installation. The database MUST be configured and URLs MUST be reserved prior to running this command.|
|New-RsConfigurationSettingObject|This command creates a new RSConfigurationSettingObject which is used to interact with the WMI Provider.|
|New-RsDataSource|This command creates/overwrites data source to the specified path.|
|New-RsFolder|This command creates a new folder in the specified path.|
|New-RsRestCredentialsByUserObject|This command creates a CredentialsByUser object to be used by Set-RsRestItemDataSource command.|
|New-RsRestCredentialsInServerObject|This command creates a CredentialsInServer object to be used by Set-RsRestItemDataSource command.|
|New-RsRestFolder|This command creates a new folder in the specified path using the REST Endpoint.|
|New-RsRestSession|This command creates a session object to be specified for all subsequent calls to the REST Endpoint.|
|New-RsSubscription|This command adds a new subscription to an existing report.|
|New-RsScheduleXml|This command creates an XML string definition of a subscription schedule. For use with the -Schedule parameter or New-RsSubscription.|
|New-RsWebServiceProxy|This command creates a new Web Service Proxy which is used to interact with the SOAP Endpoint.|
|Out-RsCatalogItem|This command downloads a catalog item.|
|Out-RsFolderContent|This command all catalog items in folder.|
|Out-RsRestFolderContent|This command downloads all catalog items under a folder using the REST Endpoint.|
|Out-RsRestCatalogItem|This command downloads a catalog item using the REST Endpoint.|
|Register-PowerBI|This command registers Power BI information with SQL Server Reporting Services.|
|Remove-RsCatalogItem|This command removes catalog item located at the specified path.|
|Remove-RsRestCatalogItem|This command removes catalog item located at the specified path using the REST Endpoint.|
|Remove-RsRestFolder|This command removes folder located at the specified path using the REST Endpoint.|
|Restore-RsEncryptionKey|This command restores encryption key on to the SQL Server Reporting Services.|
|Revoke-AccessOnCatalogItem|This command revokes access on catalog item from users or groups.|
|Revoke-AccessToRs|This command revokes access on SQL Server Reporting Services from users or groups.|
|Set-RsDatabase|This command configures the database used by SQL Server Reporting Services.|
|Set-RsDatabaseCredentials|This command configures the credentials to use when connecting to the database used by SQL Server Reporting Services.|
|Set-RsDataSet|This command links a report to  a dataset.|
|Set-RsDataSource|This command updates information associated to a data source.|
|Set-RsDataSourcePassword|This command sets the password associated with a data source.|
|Set-RsEmailSettingsAsBasicAuth|This command configures the SQL Server Reporting Services email settings to use basic authentication.|
|Set-RsEmailSettingsAsNoAuth|This command configures the SQL Server Reporting Services email settings to use no authentication.|
|Set-RsEmailSettingsAsNTLMAuth|This command configures the SQL Server Reporting Services email settings to use NTLM authentication.|
|Set-RsItemDataSource|This command updates embedded data source associated to a report.|
|Set-RsRestItemDataSource|This command updates embedded data sources associated to a Paginated report or a Power BI Report using the REST endpoint.|
|Set-RsSharedDataSource|This command links a report or a dataset to a data source.|
|Set-RsUrlReservation|This command configures the SQL Server Reporting Services URLs.|
|Set-PbiRsUrlReservation|This command configures the Power BI Report Server URLs.|
|Set-RsSubscription|This command updates existing subscriptions piped from Get-RsSubscription|
|Write-RsCatalogItem|This command uploads a report, a dataset or a data source using the SOAP Endpoint..|
|Write-RsFolderContent|This uploads all reports, datasets and data sources in a folder.|
|Write-RsRestCatalogItem|This command uploads a report, a dataset or a mobile report using the REST Endpoint.|
|Write-RsRestFolderContent|This uploads all reports, datasets, data sources, mobile reports and Power BI reports in a folder using the REST Endpoint.|

## SQL Server Versions

Some of the commands listed above allow you to optionally specify the version of your SQL Server Reporting Services instance. The following is a list of versions associated to each SQL Server Reporting Services release.

|SQL Server Release|Version|
|------------------|-------|
|SQL Server 2012|11|
|SQL Server 2014|12|
|SQL Server 2016|13|
|SQL Server 2017|14|

## Motivation

The motivation behind this project was to help users perform SQL Server Reporting Services operations via the command line. 

## API Reference

All of the APIs used by this project are publicly available. There are 2 types of APIs used in this repository: SOAP and WMI. You can find more details about the SOAP API at https://msdn.microsoft.com/en-us/library/ms154052.aspx and the WMI API at https://msdn.microsoft.com/en-us/library/ms152836.aspx. In general, you will use SOAP API for operations you would perform using Report Server and Web Portal whereas you will use WMI API for operations you would perform using Reporting Services Configuration Manager. 

## Local testing and development

To verify the versions installed
```powershell
Get-Module -ListAvailable | where Name -eq "reportingservicestools"
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
Install-Module -Name Pester
```

To excute the tests run (this will execute the CatalogItems test only which doesn't change the local Reporting Services Installation)
```powershell
.\Test.ps1
```

## Style Guidelines

If you have any scripts you would like to share, we request you to please format your scripts according to the guidelines created by the team behind the DSC Resource Kit. (https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md) and the PowerShell verbs https://msdn.microsoft.com/en-us/library/ms714428(v=vs.85).aspx

## Contributions

For contributions please provide the minimun possible increment per Pull Request so it can reviewed and merged quickly.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
