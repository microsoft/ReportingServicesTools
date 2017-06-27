function New-RsWebServiceProxyHelper
{
    <#
        .SYNOPSIS
            Internal helper function. Facilitates generating WebProxy objects.
        
        .DESCRIPTION
            Internal helper function. Facilitates generating WebProxy objects.
            
            It accepts all bound parameters of the calling function and processes the following keys:
            - ReportServerUri
            - Credential
            - Proxy
            These parameters are passed on to the New-RsWebServiceProxy function, unless Proxy was specified.
            If the bound parameters contain the proxy parameter, the function will return that object.
            All other bound parameters are ignored.
        
        .PARAMETER BoundParameters
            The bound parameters of the calling function
        
        .EXAMPLE
            $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        
            Generates or retrieves a proxy object for the reporting services web api.
    #>
    [CmdletBinding()]
    Param (
        [AllowNull()]
        [object]
        $BoundParameters
    )
    
    if ($BoundParameters["Proxy"])
    {
        return $BoundParameters["Proxy"]
    }
    
    $goodKeys = @("ReportServerUri", "Credential")
    $NewRsWebServiceProxyParam = @{ }
    
    foreach ($key in $BoundParameters.Keys)
    {
        if ($goodKeys -contains $key)
        {
            $NewRsWebServiceProxyParam[$key] = $BoundParameters[$key]
        }
    }
    
    New-RsWebServiceProxy @NewRsWebServiceProxyParam
}

function New-RsConfigurationSettingObjectHelper
{
    <#
        .SYNOPSIS
            Internal helper function. Facilitates generating wmi objects.
        
        .DESCRIPTION
            Internal helper function. Facilitates generating wmi objects.
            
            It accepts all bound parameters of the calling function and processes the following keys:
            - ReportServerInstance
            - ReportServerVersion
            - ComputerName
            - Credential
            - MinimumReportServerVersion
            These parameters are passed on to the New-RsConfigurationSettingObject function.
            All other bound parameters are ignored.
        
        .PARAMETER BoundParameters
            The bound parameters of the calling function
        
        .EXAMPLE
            $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters
        
            Generates or retrieves a wmi object for administrating a Report Server.
    #>
    [CmdletBinding()]
    Param (
        [AllowNull()]
        [object]
        $BoundParameters
    )
    
    $goodKeys = @("SqlServerInstance", "ReportServerInstance", "SqlServerVersion", "ReportServerVersion", "ComputerName", "Credential", "MinimumSqlServerVersion", "MinimumReportServerVersion")
    $NewRsConfigurationSettingObjectParam = @{ }
    
    foreach ($key in $BoundParameters.Keys)
    {
        if ($goodKeys -contains $key)
        {
            $NewRsConfigurationSettingObjectParam[$key] = $BoundParameters[$key]
        }
    }
    
    New-RsConfigurationSettingObject @NewRsConfigurationSettingObjectParam
}