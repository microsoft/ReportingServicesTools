function Get-ItemType
{
    param
    (
        [string]$FileExtension
    )
    switch ($FileExtension)
    {
        '.rdl'  {return 'Report'}
        '.rsds' {return 'DataSource'}
        '.rsd'  {return 'DataSet'}
        default {throw 'Currently only .rdl, .rsds and .rsd files are supported'}
    }
}