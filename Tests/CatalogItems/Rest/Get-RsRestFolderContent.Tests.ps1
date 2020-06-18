# Copyright (c) 2020 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

$reportPortalUri = if ($env:PesterPortalUrl -eq $null) { 'http://localhost/reports' } else { $env:PesterPortalUrl }
$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

Describe "Get-RsRestFolderContent" {
    Context "Get folder with reportPortalUri parameter"{
        # Create a folder
        $folderName = 'SutGetFolderReportPortalUriParameter' + [guid]::NewGuid()
        New-RsRestFolder -reportPortalUri $reportPortalUri -RsFolder / -FolderName $folderName
        $folderPath = '/' + $folderName
        # Test if the folder can be found
        $folderList = Get-RsRestFolderContent -reportPortalUri $reportPortalUri -RsFolder / 
        $folderCount = ($folderList | Where-Object name -eq $folderName | measure).Count
        It "Should found a folder" {
            $folderCount | Should Be 1
        }
        Write-Host "----------------------------
        "
        Write-Host "Showing $folderName variable for single folder test
        "
        Write-Host "$folderName"
        Write-Host "----------------------------
        "
        Write-Host "Showing $folderList variable for single folder test
        "
        Write-Host "$folderList"
        Write-Host "----------------------------
        "
        Write-Host "Showing $folderCount variable for single folder test
        "
        Write-Host "$folderCount"
        Write-Host "----------------------------
        "
        # Removing folders used for testing
        Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $folderPath -Confirm:$false
    }
    Context "Get folder inside 4 folders"{
        # Create the first folder in the root
        $sutRootFolder = 'SutGetFolderParent' + [guid]::NewGuid()
        New-RsRestFolder -reportPortalUri $reportPortalUri -RsFolder / -FolderName $sutRootFolder
        # Create 5 folders, one inside the other
        $currentFolderDepth = 2
        $folderParentName = $sutRootFolder
        While ($currentFolderDepth -le 5)
        {
            # Create a folder in a specified path 
            $folderParentPath +=  '/' + $folderParentName
            $folderParentName = 'SutGetFolderParent' + $currentFolderDepth 
            New-RsRestFolder -reportPortalUri $reportPortalUri -RsFolder $folderParentPath -FolderName $folderParentName
            $currentFolderDepth +=1
            
        }
        # Test if the ´SutGetFolderParent5´ folder inside the other folders can be found
        $fifthFolderPath = $folderParentPath + '/' + $folderParentName
        $rootFolderPath = '/'  + $sutRootFolder 
        $folderList = Get-RsRestFolderContent -reportPortalUri $reportPortalUri -RsFolder $rootFolderPath -Recurse
        $folderCount = ($folderList | Where-Object path -eq $fifthFolderPath | measure).Count
        It "Should found 4 subfolders" {
            $folderCount | Should Be 1
            $folderList.Count | Should be 4
        
        Write-Host "----------------------------
        "
        Write-Host "Showing $folderName variable for 4 folders test
        "
        Write-Host "$folderName"
        Write-Host "----------------------------
        "
        Write-Host "Showing $folderList variable for 4 folders test
        "
        Write-Host "$folderList"
        Write-Host "----------------------------
        "
        Write-Host "Showing $folderCount variable for 4 folders test
        "
        Write-Host "$folderCount"
        Write-Host "----------------------------
        "
        }
         # Removing folders used for testing
        Remove-RsRestCatalogItem -ReportPortalUri $reportPortalUri -RsItem $rootFolderPath -Confirm:$false
    }
}