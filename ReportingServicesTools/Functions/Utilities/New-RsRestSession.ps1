# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsRestSession
{
    <#
        .SYNOPSIS
            This script returns a new WebSession object to be used when making calls to Reporting Services OData endpoint.

        .DESCRIPTION
            This script returns a new WebSession object to be used when making calls to Reporting Services OData endpoint associated to the Report Portal URI specified by the user.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER Credential
            Specify the Credential to use when connecting to your SQL Server Reporting Services Instance.

        .EXAMPLE
            New-RsRestSession
            Description
            -----------
            This command will fetch a new XSRF token to the default report portal URI using default credentials.

        .EXAMPLE
            New-RsRestSession -ReportPortalUri http://myserver/reports_sql2016
            Description
            -----------
            This command will fetch a new XSRF token to the Report Portal located at http://myserver/reports_sql2016 using current user's credentials.

        .EXAMPLE
            New-RsRestSession -Credential 'CaptainAwesome'
            Description
            -----------
            This command will fetch a new XSRF token to the Report Portal located at http://localhost/reports using CaptainAwesome's credentials.
    #>

    [cmdletbinding()]
    param
    (
        [string]
        $ReportPortalUri = ([Microsoft.ReportingServicesTools.ConnectionHost]::ReportPortalUri),
        
        [Alias('Credentials')]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        $Credential = ([Microsoft.ReportingServicesTools.ConnectionHost]::Credential)
    )

    if (($ReportPortalUri -eq $null) -or ($ReportPortalUri.Length -eq 0))
    {
        throw "Report Portal Uri must be specified!"
    }

    try
    {
        if ($ReportPortalUri -notlike '*/') 
        {
            $ReportPortalUri = $ReportPortalUri + '/'
        }
        $meUri = $ReportPortalUri + "api/v1.0/me"

        Write-Verbose "Making call to $meUri to create a session..."
        if ($Credential)
        {
            $result = Invoke-WebRequest -Uri $meUri -Credential $Credential -SessionVariable mySession -ErrorAction Stop
        }
        else
        {
            $result = Invoke-WebRequest -Uri $meUri -UseDefaultCredentials -SessionVariable mySession -ErrorAction Stop
        }

        if ($result.StatusCode -ne 200)
        {
            throw "Encountered non-success status code while contacting Report Portal. Status Code: $($result.StatusCode)"
        }

        Write-Verbose "Loading System.Web assembly..."
        Add-Type -AssemblyName 'System.Web'

        Write-Verbose "Decoding XSRF Token cookie and setting it as a header of the session..."
        $mySession.Headers['X-XSRF-TOKEN'] = [System.Web.HttpUtility]::UrlDecode($mySession.Cookies.GetCookies($meUri)['XSRF-TOKEN'].Value)
        $mySession.Headers['X-RSTOOLS-URL'] = $ReportPortalUri
        return $mySession
    }
    catch
    {
        throw (New-Object System.Exception("Failed to create a new session to $meUri : $($_.Exception.Message)", $_.Exception))
    }
}
