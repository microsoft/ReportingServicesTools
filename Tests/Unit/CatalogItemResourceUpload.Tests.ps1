# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Import-Module "$PSScriptRoot\..\..\ReportingServicesTools\ReportingServicesTools.psd1" -Force

if (-not ('RsUnitResourceUpload.Proxy' -as [type]))
{
    Add-Type -TypeDefinition @'
namespace RsUnitResourceUpload
{
    public class Property
    {
        public string Name { get; set; }
        public string Value { get; set; }
    }

    public class Warning
    {
        public string Message { get; set; }
    }

    public class CatalogItem
    {
    }

    public class UploadCall
    {
        public string ItemType { get; set; }
        public string Name { get; set; }
        public string Parent { get; set; }
        public Property[] Properties { get; set; }
    }

    public class Proxy
    {
        public System.Collections.Generic.List<UploadCall> Calls = new System.Collections.Generic.List<UploadCall>();

        public CatalogItem CreateCatalogItem(string itemType, string name, string parent, bool overwrite, byte[] definition, Property[] properties, out Warning[] warnings)
        {
            Calls.Add(new UploadCall { ItemType = itemType, Name = name, Parent = parent, Properties = properties });
            warnings = null;
            return new CatalogItem();
        }
    }
}
'@
}

InModuleScope ReportingServicesTools {
    Describe 'Write-RsCatalogItem resource uploads without a report server' {
        BeforeEach {
            $script:proxy = New-Object RsUnitResourceUpload.Proxy
        }

        $resourceCases = @(
            @{ FileName = 'image.png'; MimeType = 'image/png' },
            @{ FileName = 'image.jpg'; MimeType = 'image/jpeg' },
            @{ FileName = 'image.jpeg'; MimeType = 'image/jpeg' },
            @{ FileName = 'IMAGE.JPG'; MimeType = 'image/jpeg' },
            @{ FileName = 'image.gif'; MimeType = 'image/gif' },
            @{ FileName = 'IMAGE.GIF'; MimeType = 'image/gif' },
            @{ FileName = 'image.bmp'; MimeType = 'image/bmp' },
            @{ FileName = 'document.pdf'; MimeType = 'application/pdf' },
            @{ FileName = 'workbook.xls'; MimeType = 'application/vnd.ms-excel' },
            @{ FileName = 'workbook.xlsx'; MimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
        )

        It 'Uploads <FileName> as a resource with MIME type <MimeType>' -TestCases $resourceCases {
            param($FileName, $MimeType)
            $path = Join-Path $TestDrive $FileName
            [System.IO.File]::WriteAllBytes($path, [byte[]](1, 2, 3))

            Write-RsCatalogItem -Path $path -RsFolder /Target -Proxy $script:proxy -Confirm:$false

            $script:proxy.Calls.Count | Should Be 1
            $script:proxy.Calls[0].ItemType | Should Be 'Resource'
            $script:proxy.Calls[0].Name | Should Be $FileName
            $script:proxy.Calls[0].Parent | Should Be '/Target'
            @($script:proxy.Calls[0].Properties).Count | Should Be 1
            $script:proxy.Calls[0].Properties[0].Name | Should Be 'MimeType'
            $script:proxy.Calls[0].Properties[0].Value | Should BeExactly $MimeType
        }

        It 'Keeps the hidden property for resources' {
            $path = Join-Path $TestDrive 'hidden.gif'
            [System.IO.File]::WriteAllBytes($path, [byte[]](1, 2, 3))

            Write-RsCatalogItem -Path $path -RsFolder /Target -Hidden -Proxy $script:proxy -Confirm:$false

            ($script:proxy.Calls[0].Properties | Where-Object Name -eq 'Hidden').Value | Should Be 'True'
        }

        It 'Rejects unsupported <FileName> files before uploading' -TestCases @(
            @{ FileName = 'workbook.xlsm' },
            @{ FileName = 'notes.txt' }
        ) {
            param($FileName)
            $path = Join-Path $TestDrive $FileName
            [System.IO.File]::WriteAllBytes($path, [byte[]](1, 2, 3))

            { Write-RsCatalogItem -Path $path -RsFolder /Target -Proxy $script:proxy -Confirm:$false } | Should Throw 'Invalid item specified!'
            $script:proxy.Calls.Count | Should Be 0
        }
    }

    Describe 'Write-RsFolderContent resource filtering without a report server' {
        It 'Uploads image and pdf resources and skips Excel workbooks' {
            $sourceFolder = Join-Path $TestDrive 'source'
            New-Item -Path $sourceFolder -ItemType Directory | Out-Null
            foreach ($fileName in 'image.png', 'image.jpg', 'image.gif', 'image.bmp', 'document.pdf', 'workbook.xls', 'workbook.xlsx', 'notes.txt')
            {
                [System.IO.File]::WriteAllBytes((Join-Path $sourceFolder $fileName), [byte[]](1, 2, 3))
            }
            $script:uploadedFiles = @()
            Mock Write-RsCatalogItem { $script:uploadedFiles += [System.IO.Path]::GetFileName($Path[0]) }

            Write-RsFolderContent -Path $sourceFolder -RsFolder /Target -Proxy (New-Object RsUnitResourceUpload.Proxy) -Confirm:$false

            ($script:uploadedFiles | Sort-Object) -join ',' | Should Be 'document.pdf,image.bmp,image.gif,image.jpg,image.png'
        }
    }
}
