function Clear-SubString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $True)]        
        [string]
        $string,
        
        [Parameter(Mandatory = $True)]        
        [string]
        $substring,
        
        [ValidateSet('front', 'back')]
        [string]
        $position
    )

    if($position -eq "front")
    {
        $result = $string -ireplace ("^" + [regex]::Escape($substring)), ""
    }
    elseif($position -eq "back")
    {
        $result = $string -ireplace ([regex]::Escape($substring) + "$"), ""
    }
    else 
    {
        $result = $string -ireplace [regex]::Escape($substring), ""
    }
    return $result
}
