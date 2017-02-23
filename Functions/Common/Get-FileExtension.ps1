function Get-FileExtension
{
    param(
        [Parameter(Mandatory=$True)]
        [string]$TypeName
    )
    switch ($TypeName)
    {
        'Report'     { return '.rdl' }
        'DataSource' { return '.rsds' }
        'DataSet'    { return '.rsd' } 
        default      {throw 'Unsupported item type! We only support items which are of type Report, DataSet or DataSource'}
    }
}