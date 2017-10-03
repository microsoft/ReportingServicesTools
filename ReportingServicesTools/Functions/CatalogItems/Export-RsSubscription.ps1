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
        [object[]]
        $Subscription 
    )

    If ($PSCmdlet.ShouldProcess($Path, "Exporting subscriptions")) {
        Write-Verbose "Exporting Subscriptions to $Path..."
        $Subscription | Export-Clixml $Path
    }
}