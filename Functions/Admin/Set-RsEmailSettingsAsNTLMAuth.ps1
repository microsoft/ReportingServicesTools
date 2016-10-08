# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RSEmailSettingsAsNTLMAuth
{
    <#
    .SYNOPSIS
        This script configures the Email Settings for SQL Server Reporting Services.

    .DESCRIPTION
        This script configures the Email Settings for SQL Server Reporting Services.

   .PARAMETER SqlServerInstance (optional)
        Specify the name of the SQL Server Reporting Services Instance.

    .PARAMETER SqlServerVersion (optional)
        Specify the version of the SQL Server Reporting Services Instance. 13 for SQL Server 2016, 12 for SQL Server 2014, 11 for SQL Server 2012

    .PARAMETER SmtpServer
        Specify the SMTP Server address.

    .PARAMETER SenderAddress
        Specify sender email address for the email. 

    .EXAMPLE
        Set-RSEmailSettingsAsNTLMAuth -SmtpServer doe.com -SenderAddress john@doe.com 
        Description
        -----------
        This command will configure the default instance from SQL Server 2016 Reporting Services to use NTLM Authentication with the specified SMTP Server and Sender Address when sending emails.

    .EXAMPLE
        Set-RSEmailSettingsAsNTLMAuth -SqlServerInstance 'SQL2012' -SqlServerVersion '11' -SmtpServer doe.com -SenderAddress john@doe.com 
        Description
        -----------
        This command will configure the named instance (SQL2012) from SQL Server 2012 Reporting Services to use NTLM Authentication with the specified SMTP Server and Sender Address when sending emails.
    #>

    [cmdletbinding()]
    param
    (
        [string]
        $SqlServerInstance='MSSQLSERVER',

        [string]
        $SqlServerVersion='13',
        
        [Parameter(Mandatory=$True)]
        [string]
        $SmtpServer,

        [Parameter(Mandatory=$True)]
        [string]
        $SenderAddress
    )

    $rsWmiObject = New-RSConfigurationSettingObject -SqlServerInstance $SqlServerInstance -SqlServerVersion $SqlServerVersion
    $rsWmiObject.SetAuthenticatedEmailConfiguration($true, $SmtpServer, $SenderAddress, '', '', 2, $true)
}
