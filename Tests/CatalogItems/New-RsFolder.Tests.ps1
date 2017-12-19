# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Describe "New-RsFolder" {
    Context "Create Folder with minimun parameters"{
        $folderName = 'SutFolderMinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderList = Get-RsFolderContent -RsFolder /
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        $folderPath = '/' + $folderName
        It "Should be a new folder" {
            $folderCount | Should Be 1
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false
    }

    Context "Create a subfolder"{
        # Create folder to create the path
        $parentFolderName = 'SutParentFolder' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $parentFolderName
        $folderPath = '/'+ $parentFolderName
        # Search for the folder path existence 
        $folderList = Get-RsFolderContent -RsFolder /
        $parentfolderCount = ($folderList | Where-Object path -eq $folderPath).Count
        # Section to test the New-RsFolder
        $subFolderName = 'SutSubFolder' + [guid]::NewGuid()
        New-RsFolder -Path $folderPath -FolderName $subFolderName 
        # Test if the folder was created
        $allFolderList = Get-RsFolderContent -RsFolder / -Recurse
        $subFolderPath = $folderPath + '/' + $subFolderName
        $subFolderCount = ($allFolderList | Where-Object path -eq $subFolderPath).Count
        It "Should the parent folder"{
            $parentFolderCount | Should be 1
        }
        It "Should the subfolder"{
            $subFolderCount | Should be 1    
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false
    }

     Context "Create a folder with proxy"{
        # Declaring the parameters name, path and proxy
        $folderName = 'SutFolderParameterProxy' + [guid]::NewGuid()
        $folderPath = '/' + $folderName
        $proxy = New-RsWebServiceProxy 
        # Creating the folder with the parameters name, path and proxy
        New-RsFolder -Path / -FolderName $folderName -Proxy $proxy
        # Test if the folder was created
        $folderList = Get-RsFolderContent -RsFolder /
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        It "Should be a new folder with the parameter proxy"{
            $folderCount | Should be 1    
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false
    }

    Context "Create a folder with ReportServerUri"{
        # Declaring the parameters name, path and ReportServerUri
        $folderName = 'SutFolderParameterReportServerUri' + [guid]::NewGuid()
        $folderPath = '/'  + $folderName
        $folderReportServerUri = 'http://localhost/reportserver'
        # Creating the folder with the parameters name, path, ReportServerUri
        New-RsFolder -ReportServerUri $folderReportServerUri -Path / -FolderName $folderName
        # Test if the folder was created
        $folderList = Get-RsFolderContent -RsFolder /
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        It "Should be a new folder with the parameter ReportServerUri" {
            $folderCount | Should Be 1
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false
    }
    
    Context "Create a folder with all the parameters except credentials"{
        # Declaring the parameters name, path and ReportServerUri
        $folderName = 'SutFolderAllParameters' + [guid]::NewGuid()
        $folderPath = '/'  + $folderName
        $folderReportServerUri = 'http://localhost/reportserver'
        $proxy = New-RsWebServiceProxy 
        # Creating the folder with the parameters name, path, ReportServerUri and proxy
        New-RsFolder -ReportServerUri $folderReportServerUri -Path / -FolderName $folderName -Proxy $proxy
        # Test if the folder was created
        $folderList = Get-RsFolderContent -RsFolder /
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        It "Should be a new folder with all parameters except credentials" {
            $folderCount | Should Be 1
        }
        # Removing folders used for testing
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false
    } 
}