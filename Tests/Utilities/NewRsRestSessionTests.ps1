# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Get-TestUser() {
    if (-not $env:RsUser) {
        throw 'Environment variable RsUser is not defined!'
    }
    return $env:RsUser
}

Describe "New-RsRestSession" { 
    Context "Create a new session object" {
        It "Should work for default Url" {
            $session = New-RsRestSession -Verbose
            $session | Should Not BeNullOrEmpty
            $session.Headers | Should Not BeNullOrEmpty
            $session.Headers['X-XSRF-TOKEN'] | Should Not BeNullOrEmpty
        }

        It "Should work for explicit Url" {
            $session = New-RsRestSession -ReportPortalUri 'http://localhost/reports' -Verbose
            $session | Should Not BeNullOrEmpty
            $session.Headers | Should Not BeNullOrEmpty
            $session.Headers['X-XSRF-TOKEN'] | Should Not BeNullOrEmpty
        }

        It "Shouldn't work when incorrect Url is specified" {
            { New-RsRestSession -ReportPortalUri 'http://localhost/reportserver' -Verbose } | Should Throw "Invalid Report Portal Uri specified! Please make sure ReportPortalUri is the URL to the Report Portal!"
        }
    }
}