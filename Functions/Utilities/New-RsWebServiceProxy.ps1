# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RSWebServiceProxy
{
    <#
    .SYNOPSIS
        This script creates a web service proxy object to the Reporting Services SOAP endpoint.

    .DESCRIPTION
        This script creates a web service proxy object to the Reporting Services SOAP endpoint associated to the Report Server URI specified by the user. 

    .PARAMETER ReportServerUri (optional)
        Specify the Report Server URL to your SQL Server Reporting Services Instance.

    .PARAMETER Username (optional)
        Specify the user name to use when connecting to your SQL Server Reporting Services Instance.

    .PARAMETER Password (optional)
        Specify the password to use when connecting to your SQL Server Reporting Services Instance.

    .EXAMPLE 
        New-RSWebServiceProxy 
        Description
        -----------
        This command will create and return a web service proxy to the Report Server located at http://localhost/reportserver using current user's credentials.
        
    .EXAMPLE 
        New-RSWebServiceProxy -ReportServerUri http://myserver/reportserver_sql2012
        Description
        -----------
        This command will create and return a web service proxy to the Report Server located at http://myserver/reportserver_sql2012 using current user's credentials.
    
    .EXAMPLE 
        New-RSWebServiceProxy -Username 'CaptainAwesome' -Password 'CaptainAwesomesPassword'
        Description
        -----------
        This command will create and return a web service proxy to the Report Server located at http://localhost/reportserver using CaptainAwesome's credentials.
    #>

    [cmdletbinding()]
    param
    (
        [string]
        $ReportServerUri = 'http://localhost/reportserver',

        [string]
        $Username,

        [string]
        $Password
    )

    # forming the full URL to the SOAP Proxy of ReportServerUri 
    if ($ReportServerUri[$ReportServerUri.Length - 1] -ne '/') 
    {
        $ReportServerUri = $ReportServerUri + '/'
    }
    $reportServerUriObject = New-Object System.Uri($ReportServerUri)
    $soapEndpointUriObject = New-Object System.Uri($reportServerUriObject, 'ReportService2010.asmx')
    $ReportServerUri = $soapEndPointUriObject.ToString()

    # creating proxy either using specified credentials or default credentials
    if (![string]::IsNullOrEmpty($Username) -and ![string]::IsNullOrEmpty($Password)) 
    {
        $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, (ConvertTo-SecureString $password -AsPlainText -Force)
        return New-WebServiceProxy -Uri $ReportServerUri -Credential $credentials -ErrorAction Stop   
    }
    else
    {
        return New-WebServiceProxy -Uri $reportServerUri -useDefaultCredential -ErrorAction Stop
    }
}