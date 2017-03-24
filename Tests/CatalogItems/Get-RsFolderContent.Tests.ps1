# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "Get-RsFolderContent" {
    Context "Get folder with ReportServerUri parameter"{
        # Create a folder
        $folderName = 'SutGetFolderReportServerUriParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        # Declare parameter ReportServerUri  
        $reportServerUri = 'http://localhost/reportserver'
        # Test if the folder can be found
        $folderList = Get-RsFolderContent -ReportServerUri $reportServerUri -RsFolder / 
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        It "Should found a folder" {
            $folderCount | Should Be 1
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath
    }

    Context "Get folder with proxy parameter"{
        # Create a folder
        $folderName = 'SutGetFolderProxyParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        # Declare parameter proxy
        $proxy = New-RsWebServiceProxy 
        # Test if the folder can be found
        $folderList = Get-RsFolderContent -Proxy $proxy -RsFolder / 
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        It "Should found a folder" {
            $folderCount | Should Be 1
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath   
    }

    Context "Get folder with Proxy and ReportServerUri parameter"{
        # Create a folder
        $folderName = 'SutGetFolderProxyAndReportServerUriParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        # Declare parameter proxy and ReportServerUri 
        $proxy = New-RsWebServiceProxy 
        $reportServerUri = 'http://localhost/reportserver'
        # Test if the folder can be found
        $folderList = Get-RsFolderContent -Proxy $proxy -ReportServerUri $reportServerUri -RsFolder / 
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        It "Should found a folder" {
            $folderCount | Should Be 1
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath   
    }

    Context "Get folder inside 4 folders"{
        # Create the first folder in the root
        $sutRootFolder = 'SutGetFolderParent' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $sutRootFolder
        # Create 5 folders, one inside the other
        $currentFolderDepth = 2
        $folderParentName = $sutRootFolder
        While ($currentFolderDepth -le 5)
        {
            # Create a folder in a specified path 
            $folderParentPath +=  '/' + $folderParentName
            $folderParentName = 'SutGetFolderParent' + $currentFolderDepth 
            New-RsFolder -Path $folderParentPath -FolderName $folderParentName
            $currentFolderDepth +=1
            
        }
        # Test if the ´SutGetFolderParent5´ folder inside the other folders can be found
        $fifthFolderPath = $folderParentPath + '/' + $folderParentName
        $rootFolderPath = '/'  + $sutRootFolder 
        $folderList = Get-RsFolderContent -RsFolder $rootFolderPath -Recurse
        $folderCount = ($folderList | Where-Object path -eq $fifthFolderPath).Count
        It "Should found 4 subfolders" {
            $folderCount | Should Be 1
            $folderList.Count | Should be 4
        }
         # Removing folders used for testing
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $rootFolderPath
    }
}