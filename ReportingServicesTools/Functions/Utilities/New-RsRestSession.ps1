# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsRestSession
{
    <#
        .SYNOPSIS
            This script returns a new WebSession object to be used when making calls to Reporting Services REST endpoint. This exists in SQL Server Reporting Services 2016 and later.

        .DESCRIPTION
            This script returns a new WebSession object to be used when making calls to Reporting Services REST endpoint associated to the Report Portal URI specified by the user. This exists in SQL Server Reporting Services 2016 and later.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v1.0", "v2.0".
            NOTE: v1.0 of REST Endpoint is not supported by Microsoft.

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

        [ValidateSet("v1.0", "v2.0")]
        [string]
        $RestApiVersion = "v2.0",

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
        $meUri = $ReportPortalUri + "api/$RestApiVersion/me"

        Write-Verbose "Making call to $meUri to create a session..."
        if ($Credential)
        {
            $result = Invoke-WebRequest -Uri $meUri -Credential $Credential -SessionVariable mySession -Verbose:$false -ErrorAction Stop
        }
        else
        {
            $result = Invoke-WebRequest -Uri $meUri -UseDefaultCredentials -SessionVariable mySession -Verbose:$false -ErrorAction Stop
        }

        if ($result.StatusCode -ne 200)
        {
            throw "Encountered non-success status code while contacting Report Portal. Status Code: $($result.StatusCode)"
        }
        else
        {
            # parsing body to validate ReportPortalUri is URL to Report Portal and not Report Server which is something user might do accidentally
            # as most of our commands ask for URL to Report Server!
            try
            {
                $body = ConvertFrom-Json $result.Content
                if ($body -eq $null -or 
                    $body.Username -eq $null)
                {
                    throw "Invalid Report Portal Uri specified! Please make sure ReportPortalUri is the URL to the Report Portal!"
                }
            }
            catch
            {
                throw "Invalid Report Portal Uri specified! Please make sure ReportPortalUri is the URL to the Report Portal!"
            }
        }

        Write-Verbose "Reading XSRF Token cookie..."
        $xsrfToken = $mySession.Cookies.GetCookies($meUri)['XSRF-TOKEN'].Value
        if ($xsrfToken -eq $null)
        {
            Write-Warning "No XSRF Token detected! This might be due to XSRF token disabled."
        }
        else
        {
            Add-Type -AssemblyName 'System.Web' -ErrorAction Stop
            
            Write-Verbose "Decoding XSRF Token and setting it as a header of the session..."
            $mySession.Headers['X-XSRF-TOKEN'] = [System.Web.HttpUtility]::UrlDecode($xsrfToken)
        }

        # This header is not required by the REST Endpoint. It is there so that user does not need to specify
        # the Portal Uri every single time they run a command using the REST Endpoint.
        $mySession.Headers['X-RSTOOLS-PORTALURI'] = $ReportPortalUri
        return $mySession
    }
    catch
    {
        throw (New-Object System.Exception("Failed to create a new session to $meUri : $($_.Exception.Message)", $_.Exception))
    }
}
