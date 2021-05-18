function Get-PublicServerSetting
{
    [CmdletBinding()]
    param
    (
		[Alias('ServerProperty')]
        [Parameter(Mandatory = $True)]        
        [string]
        $Property,

        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Alias('ApiVersion')]
        [ValidateSet("v1.0", "v2.0")]
        [string]
        $RestApiVersion = "v2.0"
    )

    $WebSession = New-RsRestSessionHelper -BoundParameters $PSBoundParameters
    $ReportPortalUri = Get-RsPortalUriHelper -WebSession $WebSession
    $systemPropertiesUri = $ReportPortalUri + "api/$RestApiVersion/System/Properties?properties={0}"
	$uri = [String]::Format($systemPropertiesUri, $Property)
	
    try
    {
        Write-Verbose "Getting server configuration - $Property"
        
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
            Write-Error (New-Object System.Exception("Failed to get server setting: $($_.Exception.Message)", $_.Exception))
        }
    }
    catch
    {
        Write-Error (New-Object System.Exception("Failed to get server setting: $($_.Exception.Message)", $_.Exception))
    }
}
