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
        '.rds' {return 'DataSource'}
        '.rsd'  {return 'DataSet'}
        '.rsmobile' {return 'MobileReport'}
        '.pbix' {return 'PowerBIReport'}
        default {throw 'Currently only .rdl, .rds, .rsds, .rsd and .rsmobile files are supported'}
    }
}