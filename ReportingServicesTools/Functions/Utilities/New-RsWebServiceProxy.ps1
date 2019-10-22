# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsWebServiceProxy
{
    <#
        .SYNOPSIS
            This script creates a web service proxy object to the Reporting Services SOAP endpoint.
        
        .DESCRIPTION
            This script creates a web service proxy object to the Reporting Services SOAP endpoint associated to the Report Server URI specified by the user.
    
            By default, this function uses the connection values set by Connect-RsReportingServer.
            The defaults without ever calling Connect-RsReportingServer are:
            - ReportServerUri: http://localhost/reportserver/
            - Credential: Current User
        
        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            By Default, this parameter uses the uri specified by the Connect-RsReportingServer function.
        
        .PARAMETER Credential
            Specify the Credential to use when connecting to your SQL Server Reporting Services Instance.
            By Default, this parameter uses the credentials (if any) specified by the Connect-RsReportingServer function.
        
        .PARAMETER ApiVersion
            The version of the API to use, 2010 by default. Specify '2005' or '2006' if you need
            to query a Sql Server Reporting Service Instance running a version prior to
            SQL Server 2008 R2 to access those respective APIs.

        .PARAMETER CustomAuthentication
            If the server implements a custom authentication schema such as 'Forms' instead of standard Basic/NTLM.
                    
        .EXAMPLE
            New-RsWebServiceProxy
            Description
            -----------
            This command will create and return a web service proxy to the default server using default credentials.
        
        .EXAMPLE
            New-RsWebServiceProxy -ReportServerUri http://myserver/reportserver_sql2012
            Description
            -----------
            This command will create and return a web service proxy to the Report Server located at http://myserver/reportserver_sql2012 using current user's credentials.
        
        .EXAMPLE
            New-RsWebServiceProxy -Credential 'CaptainAwesome'
            Description
            -----------
            This command will create and return a web service proxy to the Report Server located at http://localhost/reportserver using CaptainAwesome's credentials.
    #>

    [cmdletbinding()]
    param
    (
        [string]
        $ReportServerUri = ([Microsoft.ReportingServicesTools.ConnectionHost]::ReportServerUri),
        
        [Alias('Credentials')]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        $Credential = ([Microsoft.ReportingServicesTools.ConnectionHost]::Credential),

        [ValidateSet('2005','2006','2010')]
        [string]
        $ApiVersion = '2010',

        [switch]
        $CustomAuthentication
    )
    
    #region If we did not specify a connection parameter, use a default connection
    if (-not ($PSBoundParameters.ContainsKey("ReportServerUri") -or $PSBoundParameters.ContainsKey("Credential")))
    {
        if ([Microsoft.ReportingServicesTools.ConnectionHost]::Proxy)
        {
            return ([Microsoft.ReportingServicesTools.ConnectionHost]::Proxy)
        }
        else
        {
            try
            {
                $proxy = New-RsWebServiceProxy -ReportServerUri ([Microsoft.ReportingServicesTools.ConnectionHost]::ReportServerUri) -Credential ([Microsoft.ReportingServicesTools.ConnectionHost]::Credential) -ErrorAction Stop
                [Microsoft.ReportingServicesTools.ConnectionHost]::Proxy = $proxy
                return $proxy
            }
            catch
            {
                throw (New-Object System.Exception("Failed to establish proxy connection to $([Microsoft.ReportingServicesTools.ConnectionHost]::ReportServerUri) : $($_.Exception.Message)", $_.Exception))
            }
        }
    }
    #endregion If we did not specify a connection parameter, use a default connection

    #region Build explicitly required proxy object
    # forming the full URL to the SOAP Proxy of ReportServerUri 
    if ($ReportServerUri -notlike '*/') 
    {
        $ReportServerUri = $ReportServerUri + '/'
    }
    $reportServerUriObject = New-Object System.Uri($ReportServerUri)
    $soapEndpointUriObject = New-Object System.Uri($reportServerUriObject, "ReportService$ApiVersion.asmx")
    $ReportServerUri = $soapEndPointUriObject.ToString()
    
    # creating proxy either using specified credentials or default credentials
    try
    {
        Write-Verbose "Establishing proxy connection to $ReportServerUri..."
        if ($Credential)
        {
            $proxy = New-WebServiceProxy -Uri $ReportServerUri -Credential $Credential -ErrorAction Stop
        }
        else
        {
            $proxy = New-WebServiceProxy -Uri $ReportServerUri -UseDefaultCredential -ErrorAction Stop
        }

        if ($CustomAuthentication)
        {
            if (!$Credential) 
            {
                $Credential = Get-Credential
            }
            $NetworkCredential = $Credential.GetNetworkCredential()

            $proxy.CookieContainer = New-Object System.Net.CookieContainer
            $proxy.LogonUser($NetworkCredential.UserName, $NetworkCredential.Password, "Forms")

            Write-Verbose "Authenticated!"    
        }

        return $proxy
    }
    catch
    {
        throw (New-Object System.Exception("Failed to establish proxy connection to $ReportServerUri : $($_.Exception.Message)", $_.Exception))
    }
    #endregion Build explicitly required proxy object
}
