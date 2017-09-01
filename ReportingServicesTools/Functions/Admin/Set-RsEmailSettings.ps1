# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsEmailSettings
{
    <#
        .SYNOPSIS
            This script configures the Email Settings for SQL Server Reporting Services.
        
        .DESCRIPTION
            This script configures the Email Settings for SQL Server Reporting Services.
        
        .PARAMETER Authentication
            Default: Ntlm
            The authentication mode the Report Server should be using when sending email.
            
            Note: When using Basic Authentication, the 'EmailCredential' parameter becomes mandatory.
            Note2: When using one of the three predefined authentication-specific aliases without explicitly specifying this parameter, the default Authentication type will be changed to the one contained in the Alias name.
        
        .PARAMETER SmtpServer
            Specify the SMTP Server address.
        
        .PARAMETER SenderAddress
            Specify sender email address for the email.
        
        .PARAMETER EmailCredential
            Specify credentials to specify when connecting to the SMTP server using Basic Authentication.
        
        .PARAMETER ReportServerInstance
            Specify the name of the SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER ReportServerVersion
            Specify the version of the SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER ComputerName
            The Report Server to target.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .EXAMPLE
            Set-RsEmailSettings -SmtpServer doe.com -SenderAddress john@doe.com
            Description
            -----------
            This command will configure the Report Server to use NTLM Authentication with the specified SMTP Server and Sender Address when sending emails.
        
        .EXAMPLE
            Set-RsEmailSettings -ReportServerInstance 'SQL2012' -ReportServerVersion '11' -SmtpServer doe.com -SenderAddress john@doe.com
            Description
            -----------
            This command will configure the named instance (SQL2012) from SQL Server 2012 Reporting Services to use NTLM Authentication with the specified SMTP Server and Sender Address when sending emails.
    
        .EXAMPLE
            Set-RsEmailSettings -Authentication None -SmtpServer foo.nordwind.fiction -SenderAddress Jane@nordwind.fiction
            Description
            -----------
            This command will configure the Report Server to anonymously send emails using the smtp server foo.nordwind.fiction, sending as jane@nordwind.fiction.
    
        .EXAMPLE
            Set-RsEmailSettings -Authentication Basic -SmtpServer foo.nordwind.fiction -SenderAddress Jane@nordwind.fiction -EmailCredential $cred
            Description
            -----------
            This command will configure the Report Server to send emails using the smtp server foo.nordwind.fiction, sending as jane@nordwind.fiction.
            The Report Server will use basic authentication using the specified credentials to complete this process.
        
        .NOTES
            This function unifies the three authentication specific functions that were present in the module until v 0.0.0.8. (Set-RsEmailSettingsAsNTLMAuth, Set-RsEmailSettingsAsNoAuth and Set-RsEmailSettingsAsBasicAuth).
            In order to maintain backwards compatibility, aliases with their respective name were created.
            These then affect the default value for the new 'Authentication' parameter, which was introduced in this function.
            The result should be, that all scripts using the old functions should remain functional, as the same effective outcome with the old call should persist.
    #>
    
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $True)]
        [Microsoft.ReportingServicesTools.SmtpAuthentication]
        $Authentication = "Ntlm",
        
        [Parameter(Mandatory = $True)]
        [string]
        $SmtpServer,
        
        [Parameter(Mandatory = $True)]
        [string]
        $SenderAddress,
        
        [Alias('EmailCredentials')]
        [System.Management.Automation.PSCredential]
        $EmailCredential,
        
        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,
        
        [Alias('SqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion,
        
        [string]
        $ComputerName,
        
        [System.Management.Automation.PSCredential]
        $Credential
    )
    
    $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters
    
    #region Backwards compatibility
    if (-not $PSBoundParameters.ContainsKey("Authentication"))
    {
        $CallName = (Get-PSCallStack)[0].InvocationInfo.InvocationName
        
        if ($CallName -eq "Set-RsEmailSettingsAsNoAuth")
        {
            $Authentication = "None"
        }
        if ($CallName -eq "Set-RsEmailSettingsAsBasicAuth")
        {
            $Authentication = "Basic"
        }
        if ($CallName -eq "Set-RsEmailSettingsAsNTLMAuth")
        {
            $Authentication = "Ntlm"
        }
    }
    #endregion Backwards compatibility
    
    if (($Authentication -like "Basic") -and (-not $EmailCredential))
    {
        throw (New-Object System.Management.Automation.PSArgumentException("Basic authentication requires passing credentials using the 'EmailCredential' parameter!"))
    }
    
    #region Handle Credentials on basic authentication
    $UserName = ''
    $Password = ''
    
    if ($Authentication -like "Basic")
    {
        $UserName = $EmailCredential.UserName
        $Password = $EmailCredential.GetNetworkCredential().Password
    }
    #endregion Handle Credentials on basic authentication
    
    try
    {
        $result = $rsWmiObject.SetAuthenticatedEmailConfiguration($true, $SmtpServer, $SenderAddress, $UserName, $Password, $Authentication.Value__, $true)
    }
    catch
    {
        throw (New-Object System.Exception("Failed to update email settings: $($_.Exception.Message)", $_.Exception))
    }
    
    if ($result.HRESULT -ne 0)
    {
        throw "Failed to update email settings. Errocode: $($result.HRESULT)"
    }
}

# Backwards compatiblity
New-Alias -Name "Set-RsEmailSettingsAsNTLMAuth" -Value Set-RsEmailSettings -Scope Global
New-Alias -Name "Set-RsEmailSettingsAsNoAuth" -Value Set-RsEmailSettings -Scope Global
New-Alias -Name "Set-RsEmailSettingsAsBasicAuth" -Value Set-RsEmailSettings -Scope Global
