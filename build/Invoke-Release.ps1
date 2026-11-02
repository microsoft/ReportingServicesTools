[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet('Validate', 'Publish')]
    [string]$Phase,

    [string]$RepositoryPath = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'

if ($env:APPVEYOR_REPO_TAG -ne 'true')
{
    Write-Host 'Not a tag build; skipping release.'
    return
}

function Invoke-ReleaseGit
{
    param ([string[]]$Arguments)

    try
    {
        $output = & git -C $RepositoryPath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    catch
    {
        throw "Release git $($Arguments -join ' ') failed: $_"
    }
    if ($exitCode -ne 0)
    {
        throw "Release git $($Arguments -join ' ') failed (exit $exitCode): $($output -join ' ')"
    }
    $output
}

function Get-ReleaseFileInventory
{
    param ([string]$Directory)

    foreach ($entry in (Get-ChildItem -LiteralPath $Directory -Force -ErrorAction Stop | Sort-Object Name))
    {
        if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint)
        {
            throw "Release package contains a symbolic link or junction: '$($entry.FullName)'. Use regular package files."
        }
        if ($entry.PSIsContainer)
        {
            Get-ReleaseFileInventory -Directory $entry.FullName
        }
        else
        {
            [ordered]@{
                Path = $entry.FullName.Substring($packagePrefix.Length)
                SHA256 = (Get-FileHash -LiteralPath $entry.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
            }
        }
    }
}

# Keep the pre-test inventory outside the published package and Git's worktree checks.
$gitDirectory = Invoke-ReleaseGit -Arguments @('rev-parse', '--absolute-git-dir')
$inventoryPath = Join-Path $gitDirectory 'rst-tested-package.json'
if ($Phase -eq 'Validate' -and (Test-Path -LiteralPath $inventoryPath))
{
    Remove-Item -LiteralPath $inventoryPath -Force -ErrorAction Stop
}

$tag = $env:APPVEYOR_REPO_TAG_NAME
$versionPattern = '\A(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*))?\z'
$releaseVersion = $null
if ($tag -cnotmatch $versionPattern -or -not [version]::TryParse($tag, [ref]$releaseVersion))
{
    throw "Invalid release tag '$tag'. Use canonical numeric major.minor.patch[.revision] components without leading zeroes, a prefix, or a prerelease suffix. Legacy zero-padded tags such as 0.06.3 are not supported for releases."
}
if ($env:APPVEYOR_REPO_COMMIT -notmatch '\A[0-9a-f]{40}\z')
{
    throw 'APPVEYOR_REPO_COMMIT must contain the full tested commit SHA for a tag release.'
}

$headCommit = Invoke-ReleaseGit -Arguments @('rev-parse', '--verify', 'HEAD')
if ($headCommit -ne $env:APPVEYOR_REPO_COMMIT)
{
    throw "Release checkout mismatch: HEAD is $headCommit, but APPVEYOR_REPO_COMMIT is $env:APPVEYOR_REPO_COMMIT. Rebuild the tagged commit; do not switch branches during deployment."
}
$tagCommit = Invoke-ReleaseGit -Arguments @('rev-parse', '--verify', "refs/tags/$tag^{commit}")
if ($tagCommit -ne $headCommit)
{
    throw "Release tag '$tag' points to $tagCommit, not the tested checkout $headCommit."
}

$trackedChanges = @(Invoke-ReleaseGit -Arguments @('status', '--porcelain', '--untracked-files=no'))
$packageChanges = @(Invoke-ReleaseGit -Arguments @('status', '--porcelain', '--untracked-files=all', '--ignored', '--', 'ReportingServicesTools'))
if ($trackedChanges.Count -gt 0 -or $packageChanges.Count -gt 0)
{
    throw "Release source differs from the tagged commit (including untracked or ignored package files). Use a clean checkout and rerun tests. Changes: $(($trackedChanges + $packageChanges) -join '; ')"
}

$modulePath = [IO.Path]::GetFullPath((Join-Path $RepositoryPath 'ReportingServicesTools'))
$manifestPath = Join-Path $modulePath 'ReportingServicesTools.psd1'
$manifest = Import-PowerShellDataFile -LiteralPath $manifestPath -ErrorAction Stop
if ($manifest.ModuleVersion -cne $tag)
{
    throw "Release tag '$tag' does not match committed ModuleVersion '$($manifest.ModuleVersion)'. The source manifest may lag PowerShell Gallery. Choose an unused release version, commit that ModuleVersion, then tag that commit and rebuild. Deployment never stamps versions or updates master."
}
if ($manifest.PrivateData.PSData.Prerelease)
{
    throw 'Prerelease metadata is not supported by this numeric-tag release flow. Commit a stable manifest before tagging.'
}

# Test-ModuleManifest on Windows PowerShell can accept a nonexistent RootModule.
$rootModule = $manifest.RootModule
if ($rootModule -isnot [string] -or [string]::IsNullOrWhiteSpace($rootModule))
{
    throw 'Release RootModule must name an existing file inside the module package; it cannot be absent or empty.'
}
if ([IO.Path]::IsPathRooted($rootModule) -or $rootModule.Contains(':'))
{
    throw "Release RootModule '$rootModule' must be a relative file path inside the module package."
}
if ($rootModule -match '(^|[\\/])\.\.([\\/]|$)')
{
    throw "Release RootModule '$rootModule' resolves outside the module package or uses parent traversal. Use a package-relative path without '..' components."
}
$rootPath = [IO.Path]::GetFullPath([IO.Path]::Combine($modulePath, $rootModule))
$packagePrefix = $modulePath + [IO.Path]::DirectorySeparatorChar
$pathComparison = [StringComparison]::Ordinal
if ([IO.Path]::DirectorySeparatorChar -eq '\')
{
    $pathComparison = [StringComparison]::OrdinalIgnoreCase
}
if (-not $rootPath.StartsWith($packagePrefix, $pathComparison))
{
    throw "Release RootModule '$rootModule' resolves outside the module package."
}

# Inspect each component before descending so a junction cannot escape containment.
$pathToCheck = $modulePath
$pathParts = @('') + $rootPath.Substring($packagePrefix.Length).Split([IO.Path]::DirectorySeparatorChar)
foreach ($part in $pathParts)
{
    if ($part) { $pathToCheck = Join-Path $pathToCheck $part }
    if (-not (Test-Path -LiteralPath $pathToCheck))
    {
        throw "Release RootModule file is missing: '$rootModule'. Commit the file inside the module package before tagging."
    }
    $item = Get-Item -LiteralPath $pathToCheck -Force -ErrorAction Stop
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
    {
        throw "Release RootModule path contains a symbolic link or junction: '$pathToCheck'. Use regular package files."
    }
}
if ($item.PSIsContainer)
{
    throw "Release RootModule '$rootModule' must be a file, not a directory."
}
$null = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop

$inventory = [ordered]@{
    Schema = 1
    Commit = $headCommit
    Tag = $tag
    JobId = $env:APPVEYOR_JOB_ID
    Files = @(Get-ReleaseFileInventory -Directory $modulePath)
} | ConvertTo-Json -Depth 6 -Compress

Write-Host "Validated release $tag from tested commit $headCommit."
if ($Phase -eq 'Validate')
{
    [IO.File]::WriteAllText($inventoryPath, $inventory)
}
if ($Phase -eq 'Publish')
{
    if ([string]::IsNullOrWhiteSpace($env:galleryPublishingKey))
    {
        throw 'galleryPublishingKey is required to publish the validated tag release.'
    }
    if (-not (Test-Path -LiteralPath $inventoryPath -PathType Leaf))
    {
        throw 'Pre-test release byte inventory is missing. Run validation before tests in this build before publishing.'
    }
    if (-not [string]::Equals([IO.File]::ReadAllText($inventoryPath), $inventory, [StringComparison]::Ordinal))
    {
        throw 'Release package bytes or build identity differ from the pre-test inventory. Rebuild and rerun tests; Git status alone does not detect normalized line-ending changes.'
    }
    Publish-Module -Path $modulePath -NuGetApiKey $env:galleryPublishingKey -ErrorAction Stop
}
