[CmdletBinding()]
param (
    [string]$Path,
    [string]$Version = 'master'
)

& {
# Path is a container; only its ReportingServicesTools child is replaced.
# Windows PowerShell 3.0 requires .NET Framework 4.5 for synchronous ZIP extraction.
function Read-InstallerManifest([string]$ModulePath)
{
    $manifest = Join-Path $ModulePath 'ReportingServicesTools.psd1'
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($manifest, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -ne 0 -or $ast.BeginBlock -or $ast.ProcessBlock -or
        $ast.EndBlock.Traps.Count -gt 0 -or $ast.EndBlock.Statements.Count -ne 1 -or
        $ast.EndBlock.Statements[0] -isnot [System.Management.Automation.Language.PipelineAst] -or
        $ast.EndBlock.Statements[0].PipelineElements.Count -ne 1 -or
        $ast.EndBlock.Statements[0].PipelineElements[0].Expression -isnot [System.Management.Automation.Language.HashtableAst])
    {
        throw "Invalid module manifest: $manifest"
    }
    # SafeGetValue accepts constant data, not commands or script execution.
    $data = $ast.EndBlock.Statements[0].PipelineElements[0].Expression.SafeGetValue()
    if ($data -isnot [System.Collections.IDictionary] -or
        $data.GUID -ne '9d139310-ce45-41ce-8e8b-d76335aa1789' -or
        $data.RootModule -ne 'ReportingServicesTools.psm1' -or
        -not $data.ModuleVersion -or
        -not (Test-Path -LiteralPath (Join-Path $ModulePath 'ReportingServicesTools.psm1') -PathType Leaf))
    {
        throw "Not a ReportingServicesTools installation: $ModulePath"
    }
    $null = [version]$data.ModuleVersion
}

function Assert-InstallerDirectory([string]$Directory)
{
    $current = $Directory
    while ($current)
    {
        if (Test-Path -LiteralPath $current)
        {
            $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
            if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
                (Test-Path -LiteralPath (Join-Path $current '.git')) -or
                (Test-Path -LiteralPath (Join-Path $current 'Install.ps1')))
            {
                throw "Unsafe installation directory: $Directory"
            }
        }
        $current = Split-Path -Path $current -Parent
    }
}

function Get-InstallerFiles([string]$Directory)
{
    foreach ($item in Get-ChildItem -LiteralPath $Directory -Force -ErrorAction Stop)
    {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
        {
            throw "Installation contains a symbolic link or junction: $($item.FullName)"
        }
        $item
        if ($item.PSIsContainer) { Get-InstallerFiles $item.FullName }
    }
}

$defaultPath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'
if ([string]::IsNullOrWhiteSpace($Path)) { $Path = $defaultPath }
$Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
$Path = [IO.Path]::GetFullPath($Path).TrimEnd('\')
$defaultPath = [IO.Path]::GetFullPath($defaultPath).TrimEnd('\')
if ($Path -eq [IO.Path]::GetPathRoot($Path).TrimEnd('\') -or
    -not (Split-Path -Path $Path -Parent) -or
    $Path -eq [Environment]::GetFolderPath('UserProfile') -or
    $Path -eq [Environment]::GetFolderPath('MyDocuments') -or
    $Path -eq $env:SystemRoot -or $Path -eq $env:ProgramFiles -or
    $Path -eq ${env:ProgramFiles(x86)})
{
    throw "Unsafe installation container: $Path"
}
Assert-InstallerDirectory $Path
$modulePath = Join-Path $Path 'ReportingServicesTools'
if (Test-Path -LiteralPath $modulePath)
{
    Assert-InstallerDirectory $modulePath
    $null = @(Get-InstallerFiles $modulePath)
    Read-InstallerManifest $modulePath
}
if ((Test-Path -LiteralPath $Path) -and $Path -ne $defaultPath)
{
    $otherItems = @(Get-ChildItem -LiteralPath $Path -Force -ErrorAction Stop |
        Where-Object { $_.Name -ne 'ReportingServicesTools' })
    if ($otherItems.Count -ne 0)
    {
        throw "The installation container must be empty or contain only a ReportingServicesTools installation: $Path"
    }
}

$stage = $null
$createdContainer = $false
$backedUp = $false
$replacementStarted = $false
$preserveStage = $false
$previousModule = @(Get-Module -Name ReportingServicesTools)
$securityProtocol = [Net.ServicePointManager]::SecurityProtocol
try
{
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
    if (-not (Test-Path -LiteralPath $Path))
    {
        $null = New-Item -Path $Path -ItemType Directory -ErrorAction Stop
        $createdContainer = $true
    }
    $stage = Join-Path $Path ('.rst-install-' + [guid]::NewGuid().ToString('N'))
    $null = New-Item -Path $stage -ItemType Directory -ErrorAction Stop
    $zipFile = Join-Path $stage 'download.zip'
    $expanded = Join-Path $stage 'expanded'
    [Net.ServicePointManager]::SecurityProtocol = $securityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $url = "https://github.com/Microsoft/ReportingServicesTools/archive/$Version.zip"
    Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing -ErrorAction Stop

    $archive = [IO.Compression.ZipFile]::OpenRead($zipFile)
    try
    {
        $roots = @()
        foreach ($entry in $archive.Entries)
        {
            $name = $entry.FullName.Replace('\', '/')
            if ($name -match '(^/|[<>:"|?*]|//|(^|/)\.\.?(/|$)|[ .](/|$))' -or
                $name -match '(^|/)(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|/|$)' -or
                (($entry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000)
            {
                throw "Unsafe archive entry: $name"
            }
            $roots += $name.Split('/')[0]
        }
        $roots = @($roots | Select-Object -Unique)
        if ($roots.Count -ne 1 -or [string]::IsNullOrWhiteSpace($roots[0]))
        {
            throw 'The archive must contain exactly one repository root directory.'
        }
    }
    finally { $archive.Dispose() }
    [IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $expanded)
    $candidate = Join-Path (Join-Path $expanded $roots[0]) 'ReportingServicesTools'
    Read-InstallerManifest $candidate
    # A GUID does not establish ownership of extra files in an installation.
    # Reject them rather than deleting user content or guessing how to migrate it.
    if (Test-Path -LiteralPath $modulePath)
    {
        foreach ($item in Get-InstallerFiles $modulePath)
        {
            $relative = $item.FullName.Substring($modulePath.Length + 1)
            $candidateItem = Join-Path $candidate $relative
            $kind = 'Leaf'
            if ($item.PSIsContainer) { $kind = 'Container' }
            if (-not (Test-Path -LiteralPath $candidateItem -PathType $kind))
            {
                throw "Existing installation contains content absent from the archive; move it aside before updating: $($item.FullName)"
            }
        }
    }

    $backup = Join-Path $stage 'previous'
    try
    {
        if ($previousModule.Count -gt 0) { Remove-Module -Name ReportingServicesTools -ErrorAction Stop }
        if (Test-Path -LiteralPath $modulePath)
        {
            Move-Item -LiteralPath $modulePath -Destination $backup -ErrorAction Stop
            $backedUp = $true
        }
        $replacementStarted = $true
        Move-Item -LiteralPath $candidate -Destination $modulePath -ErrorAction Stop
        Read-InstallerManifest $modulePath
        Import-Module (Join-Path $modulePath 'ReportingServicesTools.psd1') -Global -Force -ErrorAction Stop
    }
    catch
    {
        $replacementError = $_
        try
        {
            if (-not $backedUp -and (Test-Path -LiteralPath $backup))
            {
                $backedUp = $true
            }
            if ($replacementStarted -and (Test-Path -LiteralPath $modulePath))
            {
                Remove-Module -Name ReportingServicesTools -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $modulePath -Recurse -Force -ErrorAction Stop
            }
            if ($backedUp) { Move-Item -LiteralPath $backup -Destination $modulePath -ErrorAction Stop }
            if ($previousModule.Count -gt 0)
            {
                foreach ($module in $previousModule)
                {
                    $previousPath = $module.Path
                    if (-not $previousPath) { $previousPath = Join-Path $modulePath 'ReportingServicesTools.psd1' }
                    Import-Module $previousPath -Global -Force -ErrorAction Stop
                }
            }
        }
        catch
        {
            $preserveStage = $true
            throw "Installation failed: $replacementError. Rollback failed: $_. Recovery files retained at $stage"
        }
        throw $replacementError
    }
    Write-Output "ReportingServicesTools was installed in $modulePath."
    Get-Command -Module ReportingServicesTools
}
finally
{
    [Net.ServicePointManager]::SecurityProtocol = $securityProtocol
    if ($stage -and -not $preserveStage -and (Test-Path -LiteralPath $stage))
    {
        Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction Stop
    }
    if ($createdContainer -and -not $preserveStage -and
        @(Get-ChildItem -LiteralPath $Path -Force -ErrorAction Stop).Count -eq 0)
    {
        Remove-Item -LiteralPath $Path -ErrorAction Stop
    }
}
}
