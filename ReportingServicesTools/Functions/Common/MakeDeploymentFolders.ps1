function MakeDeploymentFolders {
    param($RsFolder,$ReportPortal)
    $tree=$null
    $tree
    $Base='/'
    ($RsFolder.substring(1,$RsFolder.length-1)).split('/') | foreach{
            $Folder = $_
            $tree += "/"+$Folder
            try{
                Get-RsRestItem -ReportPortalUri $ReportPortal -RsItem $tree| ft -AutoSize
            }
            catch{
                Write-Warning "Folder $tree does not exist";
                New-RsRestFolder -ReportPortalUri $ReportPortal -RsFolder $Base -FolderName $Folder -Verbose
            }
            $Base=$tree
        }
}