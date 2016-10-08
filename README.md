# Reporting Services PowerShell
SQL Server Reporting Services PowerShell utilities 

#Install
Invoke-Expression (Invoke-WebRequest https://raw.githubusercontent.com/Microsoft/ReportingServicesTools/master/Install.ps1)

or

Invoke-Expression (Invoke-WebRequest https://aka.ms/rstools)

## List of commands

The following is a list of commands which are available for you to use once you follow the steps in Installation

|Command|Description|
|-------|-----------|
|Backup-RsEncryptionKey|This command backs up the encryption key used by SQL Server Reporting Services to protect sensitive content.|
|Get-RsCatalogItems|This command lists all catalog items under a folder.|
|Get-RsDataSource|This command lists information about data source located at the specified path.|
|Get-RsItemReferences|This commands sets the item references of a report or a dataset.|
|Grant-AccessOnCatalogItem|This command grants access on catalog item to users or groups.|
|Grant-AccessToRs|This command grants access to SQL Server Reporting Services to users or groups.|
|New-RsConfigurationSettingObject|This command creates a new RSConfigurationSettingObject which is used to interact with the WMI Provider.|
|New-RsDataSource|This command creates/overwrites data source to the specified path.|
|New-RsWebServiceProxy|This command creates a new Web Service Proxy which is used to interact with the SOAP Endpoint.|
|Out-RsCatalogItem|This command downloads a catalog item.|
|Out-RsFolderContent|This command all catalog items in folder.|
|Register-PowerBI|This command registers Power BI information with SQL Server Reporting Services.|
|Remove-RsCatalogItem|This command removes catalog item located at the specified path.|
|Restore-RsEncryptionKey|This command restores encryption key on to the SQL Server Reporting Services.|
|Revoke-AccessOnCatalogItem|This command revokes access on catalog item from users or groups.|
|Revoke-AccessToRs|This command revokes access on SQL Server Reporting Services from users or groups.|
|Set-RsDataSet|This command links a report to  a dataset.|
|Set-RsDataSource|This command updates information associated to a data source.|
|Set-RsDataSourcePassword|This command sets the password associated with a data source.|
|Set-RsEmailSettingsAsBasicAuth|This command configures the SQL Server Reporting Services email settings to use basic authentication.|
|Set-RsEmailSettingsAsNoAuth|This command configures the SQL Server Reporting Services email settings to use no authentication.|
|Set-RsEmailSettingsAsNTLMAuth|This command configures the SQL Server Reporting Services email settings to use NTLM authentication.|
|Set-RsSharedDataSource|This command links a report or a dataset to a data source.|
|Write-RsCatalogItem|This command uploads a report, a dataset or a data source.|
|Write-RsFolderContent|This uploads all reports, datasets and data sources in a folder.|


# Microsoft Open Source Code of Conduct
This project has adopted the [Microsoft Open Source Code of
Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct
FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com)
with any additional questions or comments.
