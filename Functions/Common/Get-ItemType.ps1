function Get-ItemType
{
        param(
            [string]$FileExtension
        )
switch ($FileExtension)
    {
        '.rdl'  {return 'Report'}
        '.rsds' {return 'DataSource'}
        '.rsd'  {return 'DataSet'}
        default {throw 'Uploading currently only supports .rdl, .rsds and .rsd files'}
    }
}