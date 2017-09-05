function Get-ShouldProcessTargetWmi
{
    <#
        .SYNOPSIS
            Creates the target string for a should process call of Wmi functions.
        
        .DESCRIPTION
            Creates the target string for a should process call of Wmi functions.
        
        .PARAMETER BoundParameters
            The actual PSBoundParameters object of the calling function should be passed here.
        
        .PARAMETER Target
            Additional piece of targeting string to be appended to the base info.
        
        .EXAMPLE
            Get-ShouldProcessTargetWmi -BoundParameters $PSBoundParameters
    
            Returns a string for use as target in the ShouldProcess calls of Wmi queries.
            The string will contain the actual values used for ComputerName, SqlVersion and SqlInstance:
            "<ComputerName> (<SqlVersion>) \ <SqlInstance>"
    
            e.g.: "Server01 (SqlServer2016) \ ReportServer"
    
        .EXAMPLE
            Get-ShouldProcessTargetWmi -BoundParameters $PSBoundParameters -Target "Foo"
    
            Returns a string for use as target in the ShouldProcess calls of Wmi queries.
            The string will contain the actual values used for ComputerName, SqlVersion and SqlInstance, and also have a custom value appended:
            "<ComputerName> (<SqlVersion>) \ <SqlInstance> : <Target>"
    
            e.g.: "Server01 (SqlServer2016) \ ReportServer : Foo"
    #>
    [CmdletBinding()]
    Param (
        [AllowNull()]
        [object]
        $BoundParameters,
        
        [string]
        $Target
    )
    
    if ($BoundParameters["ComputerName"])
    {
        $Server = $BoundParameters["ComputerName"]
    }
    elseif ([Microsoft.ReportingServicesTools.ConnectionHost]::ComputerName)
    {
        $Server = [Microsoft.ReportingServicesTools.ConnectionHost]::ComputerName
    }
    else
    {
        $Server = $env:COMPUTERNAME
    }
    
    if ($BoundParameters["ReportServerVersion"])
    {
        $Version = $BoundParameters["ReportServerVersion"]
    }
    else
    {
        $Version = [Microsoft.ReportingServicesTools.ConnectionHost]::Version
    }    
    
    if ($BoundParameters["ReportServerInstance"])
    {
        $Instance = $BoundParameters["ReportServerInstance"]
    }
    else
    {
        $Instance = ([Microsoft.ReportingServicesTools.ConnectionHost]::Instance)
    }
    
    if ($PSBoundParameters.ContainsKey("Target"))
    {
        return "$Server ($Version) \ $Instance : $Target"
    }
    else
    {
        return "$Server ($Version) \ $Instance"
    }
}

function Get-ShouldProcessTargetWeb
{
    <#
        .SYNOPSIS
            Creates the target string for a should process call of Web functions.
        
        .DESCRIPTION
            Creates the target string for a should process call of Web functions.
        
        .PARAMETER BoundParameters
            The actual PSBoundParameters object of the calling function should be passed here.
        
        .PARAMETER Target
            Additional piece of targeting string to be appended to the base info.
        
        .EXAMPLE
            Get-ShouldProcessTargetweb -BoundParameters $PSBoundParameters
    
            Returns a string for use as target in the ShouldProcess calls of Web queries.
            The string will contain the actual value used for ReportServerUri:
            "<ReportServerUri>"
    
        .EXAMPLE
            Get-ShouldProcessTargetweb -BoundParameters $PSBoundParameters -Target "Foo"
    
            Returns a string for use as target in the ShouldProcess calls of Web queries.
            The string will contain the actual value used for ReportServerUri and also have a custom value appended:
            "<ReportServerUri> : <Target>"
    #>
    [CmdletBinding()]
    Param (
        [AllowNull()]
        [object]
        $BoundParameters,
        
        [string]
        $Target
    )
    
    if ($BoundParameters.ContainsKey("ReportServerUri"))
    {
        if ($Target)
        {
            return "$($BoundParameters["ReportServerUri"]) : $Target"
        }
        else
        {
            return $BoundParameters["ReportServerUri"]
        }
    }
    else
    {
        if ($Target)
        {
            return "$([Microsoft.ReportingServicesTools.ConnectionHost]::ReportServerUri) : $Target"
        }
        else
        {
            return [Microsoft.ReportingServicesTools.ConnectionHost]::ReportServerUri
        }
    }
}