[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [AllowNull()]
    [AllowEmptyCollection()]
    [object[]]$Result,

    [Parameter(Mandatory = $true)]
    [string]$Name,

    # Require every discovered test to pass; skipped, pending and inconclusive tests are failures.
    [switch]$RequireAllPassed
)

$ErrorActionPreference = 'Stop'

$results = @($Result | Where-Object { $null -ne $_ })
if ($results.Count -eq 0) {
    throw "$Name did not return a Pester result; refusing to treat it as passed."
}

$counts = @{}
foreach ($property in @('TotalCount', 'PassedCount', 'FailedCount', 'SkippedCount', 'PendingCount', 'InconclusiveCount')) {
    $total = 0
    foreach ($item in $results) {
        $member = $item.PSObject.Properties[$property]
        if ($null -eq $member -or $null -eq $member.Value) {
            throw "$Name returned a Pester result without $property; refusing to treat it as passed."
        }
        $total += [int]$member.Value
    }
    $counts[$property] = $total
}

$summary = "total $($counts.TotalCount), passed $($counts.PassedCount), failed $($counts.FailedCount), skipped $($counts.SkippedCount), pending $($counts.PendingCount), inconclusive $($counts.InconclusiveCount)"

if ($counts.FailedCount -gt 0) {
    throw "$Name found $($counts.FailedCount) failed tests ($summary)."
}
if ($counts.TotalCount -le 0) {
    throw "$Name ran no tests ($summary)."
}
if ($counts.PassedCount -le 0) {
    throw "$Name did not pass any tests ($summary)."
}
if ($RequireAllPassed) {
    $notPassed = $counts.SkippedCount + $counts.PendingCount + $counts.InconclusiveCount
    if ($notPassed -gt 0 -or $counts.PassedCount -ne $counts.TotalCount) {
        throw "$Name must pass every test, but not all tests passed ($summary)."
    }
}

Write-Host "$Name passed ($summary)."
