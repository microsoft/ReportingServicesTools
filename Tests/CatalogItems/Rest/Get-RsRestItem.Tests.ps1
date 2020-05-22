# Copyright (c) 2020 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = if ($env:PesterPortalUrl -eq $null) { 'http://localhost/reports' } else { $env:PesterPortalUrl }
$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

Describe "Get-RsRestItem" {
    Context "Get folder with reportPortalUri parameter"{
        # Create a folder
        $folderName = 'SutGetFolderReportPortalUriParameter' + [guid]::NewGuid()
        New-RsRestFolder -RsFolder / -FolderName $folderName
        $folderPath = '/' + $folderName
        # Test if the folder can be found
        $folderList = Get-RsRestItem -reportPortalUri $reportPortalUri -RsItem / 
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        It "Should found a folder" {
            $folderCount | Should Be 1
        }
        # Removing folders used for testing
        Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsFolder $folderPath -Confirm:$false
    }

    Context "Get folder inside 4 folders"{
        # Create the first folder in the root
        $sutRootFolder = 'SutGetFolderParent' + [guid]::NewGuid()
        New-RsRestFolder -RsFolder / -FolderName $sutRootFolder
        # Create 5 folders, one inside the other
        $currentFolderDepth = 2
        $folderParentName = $sutRootFolder
        While ($currentFolderDepth -le 5)
        {
            # Create a folder in a specified path 
            $folderParentPath +=  '/' + $folderParentName
            $folderParentName = 'SutGetFolderParent' + $currentFolderDepth 
            New-RsRestFolder -Path $folderParentPath -FolderName $folderParentName
            $currentFolderDepth +=1
            
        }
        # Test if the ´SutGetFolderParent5´ folder inside the other folders can be found
        $fifthFolderPath = $folderParentPath + '/' + $folderParentName
        $rootFolderPath = '/'  + $sutRootFolder 
        $folderList = Get-RsRestItem -RsItem $rootFolderPath -Recurse
        $folderCount = ($folderList | Where-Object path -eq $fifthFolderPath).Count
        It "Should found 4 subfolders" {
            $folderCount | Should Be 1
            $folderList.Count | Should be 1
        }
         # Removing folders used for testing
        Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsFolder $rootFolderPath -Confirm:$false
    }
}