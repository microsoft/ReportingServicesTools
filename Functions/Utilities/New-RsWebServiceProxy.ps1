# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsWebServiceProxy
{
    <#
    .SYNOPSIS
        This script creates a web service proxy object to the Reporting Services SOAP endpoint.

    .DESCRIPTION
        This script creates a web service proxy object to the Reporting Services SOAP endpoint associated to the Report Server URI specified by the user. 

    .PARAMETER ReportServerUri
        Specify the Report Server URL to your SQL Server Reporting Services Instance.

	.PARAMETER Credentials
		Specify the credentials to use when connecting to your SQL Server Reporting Services Instance.

    .EXAMPLE 
        New-RsWebServiceProxy 
        Description
        -----------
        This command will create and return a web service proxy to the Report Server located at http://localhost/reportserver using current user's credentials.
        
    .EXAMPLE 
        New-RsWebServiceProxy -ReportServerUri http://myserver/reportserver_sql2012
        Description
        -----------
        This command will create and return a web service proxy to the Report Server located at http://myserver/reportserver_sql2012 using current user's credentials.
    
    .EXAMPLE 
        New-RsWebServiceProxy -Credentials 'CaptainAwesome'
        Description
        -----------
        This command will create and return a web service proxy to the Report Server located at http://localhost/reportserver using CaptainAwesome's credentials.
    #>

    [cmdletbinding()]
    param
    (
        [string]
        $ReportServerUri = 'http://localhost/reportserver',

        [System.Management.Automation.PSCredential]
        $Credentials
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
    if ($sqlcredential.Username -ne $null)
    {
        return New-WebServiceProxy -Uri $ReportServerUri -Credential $Credentials -ErrorAction Stop   
    }
    else
    {
        return New-WebServiceProxy -Uri $reportServerUri -useDefaultCredential -ErrorAction Stop
    }
}