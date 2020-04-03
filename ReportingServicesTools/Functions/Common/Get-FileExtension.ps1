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
        'MobileReport' { return '.rsmobile' }
        'PowerBIReport' { return '.pbix' }
        'ExcelWorkbook' { return '' }
        'Resource' { return '' }
        'Kpi' { return '.kpi' }
        'Component' { return '' }
        default      { throw 'Unsupported item type! We only support items which are of type Report, DataSet, DataSource, Mobile Report or Power BI Report' }
    }
}