Describe "New-RsFolder" {
    Context "Creat Folder with minimun parameters"{
        $folderName = 'SutFolderMinParameters' + [guid]::NewGuid()
        $folderPath = '/'
        New-RsFolder -Path $folderPath -FolderName $folderName
        $folderList = Get-RsFolderContent -RsFolder /
        $folderCount = ($folderList | where name -eq $folderName).Count
        It "Should be a new folder" {
            $folderCount | Should Be 1
        }
    }
    Context "Create a subfolder"{
        # Create folder to create the path
        $folderPathName = 'SutPathSubFolder' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderPathName
        $folderPath = '/'+ $folderPathName
        # Search for the folder path existence 
        $folderList = Get-RsFolderContent -RsFolder /
        $folderPathCount = ($folderList | where path -eq $folderPath).Count
        # Section to test the New-RsFolder
        $folderName = 'SutSubFolder' + [guid]::NewGuid()
        New-RsFolder -Path $folderPath -FolderName $folderName 
        # Test if the folder was created
        $newFolderList = Get-RsFolderContent -RsFolder / -Recurse
        $path = $folderPath + '/' + $folderName
        $folderCount = ($newFolderList | where path -eq $path).Count
        It "Should exist the folder to be used as the path"{
            $folderPathCount | Should be 1
        }
        It "Should be a new folder"{
            $folderCount | Should be 1    
        }
    }
     Context "Create a folder with proxy"{
        # Declaring the parameters name, path and proxy
        $folderName = 'SutFolderParameterProxy' + [guid]::NewGuid()
        $folderPath = '/'
        $proxy = New-RsWebServiceProxy 
        # Creating the folder with the parameters name, path and proxy
        New-RsFolder -Path $folderPath -FolderName $folderName -Proxy $proxy
        # Test if the folder was created
        $folderList = Get-RsFolderContent -RsFolder /
        $folderCount = ($folderList | where name -eq $folderName).Count
        It "Should be a new folder with the parameter proxy"{
            $folderCount | Should be 1    
        }
    }
    Context "Create a folder with ReportServerUri"{
        # Declaring the parameters name, path and ReportServerUri
        $folderName = 'SutFolderParameterReportServerUri' + [guid]::NewGuid()
        $folderPath = '/'
        $folderReportServerUri = 'http://localhost/reportserver'
        # Creating the folder with the parameters name, path, ReportServerUri
        New-RsFolder -ReportServerUri $folderReportServerUri -Path $folderPath -FolderName $folderName
        # Test if the folder was created
        $folderList = Get-RsFolderContent -RsFolder /
        $folderCount = ($folderList | where name -eq $folderName).Count
        It "Should be a new folder with the parameter ReportServerUri" {
            $folderCount | Should Be 1
        }
    }
    Context "Create a folder with all the parameters except credentials"{
        # Declaring the parameters name, path and ReportServerUri
        $folderName = 'SutFolderParameterReportServerUri' + [guid]::NewGuid()
        $folderPath = '/'
        $folderReportServerUri = 'http://localhost/reportserver'
        $proxy = New-RsWebServiceProxy 
        # Creating the folder with the parameters name, path, ReportServerUri and proxy
        New-RsFolder -ReportServerUri $folderReportServerUri -Path $folderPath -FolderName $folderName -Proxy $proxy
        # Test if the folder was created
        $folderList = Get-RsFolderContent -RsFolder /
        $folderCount = ($folderList | where name -eq $folderName).Count
        It "Should be a new folder with all parameters except credentials" {
            $folderCount | Should Be 1
        }
    } 
}