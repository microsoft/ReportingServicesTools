Describe "New-RsFolder" {
    Context "Create a folder"{
        $itemsToClean = New-Object System.Collections.Generic.List[string]

        It "Should create a new folder with minimum parameters" {
            $folderName = 'SutFolderMinParameters' + [guid]::NewGuid()
            New-RsFolder -RsFolder / -FolderName $folderName -Verbose
            $itemsToClean.Add("/$folderName")
            
            $folderList = Get-RsFolderContent -RsFolder /
            $folderCount = ($folderList | Where-Object name -eq $folderName).Count
            $folderCount | Should Be 1
        }

        AfterEach {
            Remove-RsCatalogItem -Path $itemsToClean
        }
    }
}