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

$tag = $env:APPVEYOR_REPO_TAG_NAME
$versionPattern = '\A(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*))?\z'
$releaseVersion = $null
if ($tag -cnotmatch $versionPattern -or -not [version]::TryParse($tag, [ref]$releaseVersion))
{
    throw "Invalid release tag '$tag'. Use a numeric major.minor.patch[.revision] version without a prefix or prerelease suffix."
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

$modulePath = Join-Path $RepositoryPath 'ReportingServicesTools'
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
$null = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop

Write-Host "Validated release $tag from tested commit $headCommit."
if ($Phase -eq 'Publish')
{
    if ([string]::IsNullOrWhiteSpace($env:galleryPublishingKey))
    {
        throw 'galleryPublishingKey is required to publish the validated tag release.'
    }
    Publish-Module -Path $modulePath -NuGetApiKey $env:galleryPublishingKey -ErrorAction Stop
}
