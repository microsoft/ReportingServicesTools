# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

Function Export-RsSubscription {
    <#
        .SYNOPSIS
            This script exports one or more subscriptions that have been retrieved via Get-RsSubscription.
        
        .DESCRIPTION
            This script exports subscriptions to an XML file. it is essentially just a wrapper around Export-CliXML
            and that function can be used directly in place of this one. This function only exists to compliment 
            Import-RsSubscription.
                    
        .PARAMETER Path
            The path to save the XML formatted file that will contain the exported subscription/s. 
        
        .PARAMETER Subscription
            One or more subscription objects, typically retrieved via Get-RsSubscription.

        .EXAMPLE
            Get-RsSubscription -path '/path/to/my/report' | Export-RsSubscription .\MySubscriptions.xml

            Description
            -----------
            This command will export the current set of subscriptions contained in '/path/to/my/report' to an 
            XML file named MySubscriptions.xml.
    #>
        
    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    Param(
        [Parameter(Mandatory=$True,Position=0)]
        [string]
        $Path,

        [Parameter(Mandatory = $True, ValueFromPipeline=$true)]
        [object]
        $Subscription
    )
    Begin {
        $Subscriptions = @()
    }
    Process {
        Write-Verbose 'Collating subscription..'
        $Subscriptions = $Subscriptions + $Subscription
    }
    End {
        If ($PSCmdlet.ShouldProcess($Path, "Exporting subscriptions")) {
            Write-Verbose "Exporting subscriptions to $Path..."
            $Subscriptions | Export-Clixml $Path
        }
    }
}