function Get-DatabaseCredentialType() 
{
    param(
        [Parameter(Mandatory=$True)]
        [Int32]$DatabaseLogonType
    )
    switch ($DatabaseLogonType) 
    {
        0 { return 'Windows' }
        1 { return 'SQL' }
        2 { return 'ServiceAccount' }
        default { throw 'Invalid Credential Type!' }
    }
}