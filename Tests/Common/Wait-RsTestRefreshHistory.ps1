# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Wait-RsTestRefreshHistory
{
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]
        $GetHistory,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 100)]
        [int]
        $ExpectedCount,

        [ValidateRange(0, 600)]
        [int]
        $TimeoutSeconds = 120
    )

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    do
    {
        $history = @(& $GetHistory | Where-Object { $null -ne $_ })
        if ($history.Count -gt $ExpectedCount)
        {
            throw "Expected $ExpectedCount refresh history entries, but received $($history.Count)."
        }
        $unfinished = @($history | Where-Object { $_.Status -notin 'Completed', 'Failed' })
        if ($history.Count -eq $ExpectedCount -and $unfinished.Count -eq 0)
        {
            return $history
        }
        if ($timer.Elapsed.TotalSeconds -ge $TimeoutSeconds)
        {
            throw "Timed out waiting for $ExpectedCount terminal refresh history entries; received $($history.Count), unfinished $($unfinished.Count)."
        }
        Start-Sleep -Seconds 1
    } while ($true)
}
