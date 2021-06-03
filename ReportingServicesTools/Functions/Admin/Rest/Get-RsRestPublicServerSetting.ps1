function Get-RsRestPublicServerSetting
{
    <#
        .SYNOPSIS
            This function gets the public settings of the RS server.

        .DESCRIPTION
            This function gets the value of the specified property from the public settings of the RS server.

        .PARAMETER Property
            Specify the name of the property.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Get-RsRestPublicServerSetting -Property "MaxFileSizeMb"
            Description
            -----------
            Gets the value of the property "MaxFileSizeMb" from the Report Server located at http://localhost/reports.
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $True)]        
        [string]
        $Property,

        [string]
        $ReportPortalUri,

        [Alias('ApiVersion')]
        [ValidateSet("v2.0")]
        [string]
        $RestApiVersion = "v2.0",

        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )
    Begin
    {
        $WebSession = New-RsRestSessionHelper -BoundParameters $PSBoundParameters
        $ReportPortalUri = Get-RsPortalUriHelper -WebSession $WebSession
        $systemPropertiesUri = $ReportPortalUri + "api/$RestApiVersion/System/Properties?properties={0}"
    }
    Process
    {
        try
        {
            Write-Verbose "Getting server configuration - $Property"

            $uri = [String]::Format($systemPropertiesUri, $Property)

            if ($Credential -ne $null)
            {
                $response = Invoke-RestMethod -Uri $uri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
            }
            else
            {
                $response = Invoke-RestMethod -Uri $uri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
            }
        
            if ($response -ne $null -and $response.value -ne $null -and $response.value[0] -ne $null -and $response.value[0].Name -eq $Property)
            {
                return $response.value[0].Value
            }
            else
            {
                return $null
            }
        }
        catch
        {
            Write-Error (New-Object System.Exception("Failed to get server setting: $($_.Exception.Message)", $_.Exception))
        }
    }
}
