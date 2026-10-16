# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

. "$PSScriptRoot\..\Common\Wait-RsTestRefreshHistory.ps1"

Describe 'Waiting for refresh history completion' {
    BeforeEach {
        $script:historyCalls = 0
        Mock Start-Sleep {}
    }

    It 'Waits for the first execution to finish before allowing another refresh' {
        $result = @(Wait-RsTestRefreshHistory -ExpectedCount 1 -GetHistory {
            $script:historyCalls++
            [pscustomobject]@{ Id = 1; Status = if ($script:historyCalls -eq 1) { 'InProgress' } else { 'Completed' } }
        })
        $script:historyCalls | Should Be 2
        $result.Count | Should Be 1
        $result[0].Status | Should Be 'Completed'
        Assert-MockCalled Start-Sleep -Times 1 -Exactly -Scope It
    }

    It 'Accepts failed executions as terminal history without claiming refresh success' {
        $result = @(Wait-RsTestRefreshHistory -ExpectedCount 1 -GetHistory {
            [pscustomobject]@{ Id = 1; Status = 'Failed' }
        })
        $result[0].Status | Should Be 'Failed'
        Assert-MockCalled Start-Sleep -Times 0 -Exactly -Scope It
    }

    It 'Waits for both history entries and the second terminal state' {
        $result = @(Wait-RsTestRefreshHistory -ExpectedCount 2 -GetHistory {
            $script:historyCalls++
            [pscustomobject]@{ Id = 1; Status = 'Completed' }
            if ($script:historyCalls -ge 2) {
                [pscustomobject]@{ Id = 2; Status = if ($script:historyCalls -eq 2) { 'InProgress' } else { 'Failed' } }
            }
        })
        $script:historyCalls | Should Be 3
        $result.Count | Should Be 2
        Assert-MockCalled Start-Sleep -Times 2 -Exactly -Scope It
    }

    It 'Does not treat null history as one completed entry' {
        { Wait-RsTestRefreshHistory -ExpectedCount 1 -TimeoutSeconds 0 -GetHistory { $null } } |
            Should Throw 'received 0'
    }

    It 'Fails explicitly when an execution never completes' {
        { Wait-RsTestRefreshHistory -ExpectedCount 1 -TimeoutSeconds 0 -GetHistory {
            [pscustomobject]@{ Id = 1; Status = 'InProgress' }
        } } | Should Throw 'unfinished 1'
    }

    It 'Does not silently accept unknown or missing statuses' {
        { Wait-RsTestRefreshHistory -ExpectedCount 1 -TimeoutSeconds 0 -GetHistory {
            [pscustomobject]@{ Id = 1 }
        } } | Should Throw 'unfinished 1'
    }

    It 'Retains the exact history count requirement' {
        { Wait-RsTestRefreshHistory -ExpectedCount 1 -GetHistory {
            [pscustomobject]@{ Id = 1; Status = 'Completed' }
            [pscustomobject]@{ Id = 2; Status = 'Completed' }
        } } | Should Throw 'received 2'
    }

    It 'Propagates history retrieval errors' {
        { Wait-RsTestRefreshHistory -ExpectedCount 1 -GetHistory { throw 'history request failed' } } |
            Should Throw 'history request failed'
    }
}
