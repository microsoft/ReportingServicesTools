[CmdletBinding()]
param (
    [string]$Path
)

$localpath = $(Join-Path -Path (Split-Path -Path $profile) -ChildPath '\Modules\ReportingServicesTools')

try
{
    if ($Path.length -eq 0)
    {
        if ($PSCommandPath.Length -gt 0)
        {
            $path = Split-Path $PSCommandPath
            if ($path -match "github")
            {
                $path = $localpath
            }
        }
        else
        {
            $path = $localpath
        }
    }
}
catch
{
    $path = $localpath
}

if ($path.length -eq 0)
{
    $path = $localpath
}

if ((Get-Command -Module ReportingServicesTools).count -ne 0)
{
    Write-Output "Removing existing ReportingServiceTools Module..."
    Remove-Module ReportingServicesTools -ErrorAction Stop
}

$url = 'https://github.com/Microsoft/ReportingServicesTools/archive/master.zip'

$temp = ([System.IO.Path]::GetTempPath()).TrimEnd("\")
$zipfile = "$temp\ReportingServicesTools.zip"

if (!(Test-Path -Path $path))
{
    try
    {
        Write-Output "Creating directory: $path..."
        New-Item -Path $path -ItemType Directory | Out-Null
    }
    catch
    {
        throw "Can't create $Path. You may need to Run as Administrator!"
    }
}
else
{
    try
    {
        Write-Output "Deleting previously installed module..."
        Remove-Item -Path "$path\*" -Force -Recurse
    }
    catch
    {
        throw "Can't delete $Path. You may need to Run as Administrator!"
    }
}

Write-Output "Downloading archive from ReportingServiceTools GitHub..."
try
{
    Invoke-WebRequest $url -OutFile $zipfile
}
catch
{
    #try with default proxy and usersettings
    Write-Output "...Probably using a proxy for internet access. Trying default proxy settings..."
    (New-Object System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    Invoke-WebRequest $url -OutFile $zipfile -ErrorAction Stop
}

# Unblock if there's a block
Unblock-File $zipfile -ErrorAction SilentlyContinue

# Keep it backwards compatible
Write-Output "Unzipping archive..."
$shell = New-Object -COM Shell.Application
$zipPackage = $shell.NameSpace($zipfile)
$destinationFolder = $shell.NameSpace($temp)
$destinationFolder.CopyHere($zipPackage.Items())
Move-Item -Path "$temp\ReportingServicesTools-master\*" $path
Write-Output "ReportingServicesTools has been successfully downloaded to $path!"

Write-Output "Cleaning up..."
Remove-Item -Path "$temp\ReportingServicesTools-master"
Remove-Item -Path $zipfile

Write-Output "Importing ReportingServicesTools Module..."
Import-Module "$path\ReportingServicesTools\ReportingServicesTools.psd1" -Force
Write-Output "ReportingServicesTools Module was successfully imported!"

Get-Command -Module ReportingServicesTools
Write-Output "`n`nIf you experience any function missing errors after update, please restart PowerShell or reload your profile."
