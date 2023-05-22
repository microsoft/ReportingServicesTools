function New-RestSessionHelperSplat
{
    <#
        .SYNOPSIS
            Internal helper function. Facilitates generating Rest Session objects.

        .DESCRIPTION
            Internal helper function. Facilitates generating Rest Session objects.
            It is an enhancement to the New-RsRestSession function - containing Credentials and UseBasicParsing.
            This allows simpler usage and avoids duplicated calls (Credential/UseDefaultCredentials)

            It accepts all bound parameters of the calling function and processes the following keys:
            - ReportPortalUri
            - RestApiVersion
            - Credential
            - WebSession
            These parameters are passed on to the New-RsRestSession function, unless WebSession was specified.
            If the bound parameters contain the WebSession parameter, the function will return that object.
            All other bound parameters are ignored.

        .PARAMETER BoundParameters
            The bound parameters of the calling function

        .EXAMPLE
            $RsRestWebSession = New-RestSessionHelperSplat -BoundParameters $PSBoundParameters

            Generates or retrieves a WebSession object and returns a hashtable to be used in further webrequest calls.

        .RETURNS
            A hastable containing all properties to be passed to a Invoke-Webrequest call using splatting.
    #>

    [CmdletBinding()]
    Param (
        [AllowNull()]
        [object]
        $BoundParameters
    )

    if ($BoundParameters["WebSession"])
    {
        $session =  $WebSession
    } else {
        $goodKeys = @("ReportPortalUri", "RestApiVersion", "Credential")
        $NewRsRestSessionParams = @{ }

        foreach ($key in $BoundParameters.Keys)
        {
            if ($goodKeys -contains $key)
            {
                $NewRsRestSessionParams[$key] = $BoundParameters[$key]
            }
        }

        $session = New-RsRestSession @NewRsRestSessionParams
    }
    if ($null -ne $session.Credentials -and $null -eq $Credential) {
        Write-Verbose "Using credentials from WebSession"
        $Credential = New-Object System.Management.Automation.PSCredential "$($session.Credentials.UserName)@$($session.Credentials.Domain)", $session.Credentials.SecurePassword
    }
    $splatInvokeWebRequest = @{
        WebSession = $session
        UseBasicParsing = $true
        Verbose = $false
    }
    if ($null -ne $Credential) {
        $splatInvokeWebRequest.Add("Credential", $Credential)
    } else {
        $splatInvokeWebRequest.Add("UseDefaultCredentials", $true)
    }
    $splatInvokeWebRequest
}