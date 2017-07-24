# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsSubscription
{
    <#
        .SYNOPSIS
            This script set a new reporting subscription.
        
        .DESCRIPTION
            This script set a new reporting subscription based on the info of an existing subscription (retrieved using Get-RsSubscription).
            You can choose a specific report or pass a folder. When using a folder, the report must have the same name.
            NOTE: A new subscriptionId will be generated.
                    
        .PARAMETER Path
            Specify the path to the destination report. Can't be used with -RsFolder parameter.
        
        .PARAMETER RsFolder
            Specify the folder where the destination reports exists. Can't be used with -Path parameter.

        .PARAMETER Subscription
            A object with all subscritpion configurations. The default output of Get-RsSubscription. You must piping it to this command.
        
        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Credential
            Specify the password to use when connecting to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.
        
        .EXAMPLE
            Get-RsSubscription -ReportServerUri 'http://localhost/ReportServer_sql14' -Path '/path/to/my/oldReport' | Set-RsSubscription -ReportServerUri 'http://remote-machine:8080/reportserver_sql16' -Path '/path/to/newReport'
            
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/ReportServer_sql14 using current user's credentials get all subscriptions from report '/path/to/my/oldReport'
            and pipe the results to Set-RsSubscription which will create a new subscription on report '/path/to/newReport' located at Report Server 'http://remote-machine:8080/reportserver_sql16'

        
        .EXAMPLE
            Get-RsSubscription -ReportServerUri 'http://localhost/ReportServer_sql14' -Path '/path/to/my/oldReport' | Set-RsSubscription -ReportServerUri 'http://remote-machine:8080/reportserver_sql16' -RsFolder '/New Folder'
            
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/ReportServer_sql14 using current user's credentials get all subscriptions from report '/path/to/my/oldReport'
            and pipe the results to Set-RsSubscription which will create a new subscription on each report that exists with the same name on the destination folder '/New Folder' located at Report Server 'http://remote-machine:8080/reportserver_sql16'


        .EXAMPLE
            $paths = Get-RsCatalogItems -ReportServerUri 'http://localhost/ReportServer_sql14' -RsFolder /Origin | Where-Object TypeName -eq "Report" | Select-Object -ExpandProperty Path
            Get-RsSubscription -ReportServerUri 'http://localhost/ReportServer_sql14' -Path $paths | Set-RsSubscription -ReportServerUri 'http://remote-machine:8080/reportserver_sql16' -RsFolder '/New Folder'

            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/ReportServer_sql14 using current user's credentials get all the paths from all reports at '/Origin' folder.
            Then it uses the $paths variable to get all existing subscriptions and pipe the results to Set-RsSubscription which will create a new subscription on each report that exists with the same name on the destination folder '/New Folder' located at Report Server 'http://remote-machine:8080/reportserver_sql16'
    #>
    
    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [string]
        $ReportServerUri,

        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy,

        [Alias('ReportPath','ItemPath')]
        [Parameter(ParameterSetName='Report', Mandatory=$True)]
        [string]
        $Path,

        [Alias('Folder')]
        [Parameter(ParameterSetName='Folder', Mandatory=$True)]
        [string]
        $RsFolder,

        [Parameter(Mandatory = $True, ValueFromPipeline=$true)]
        [object[]]
        $Subscription
    )
    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }
    
    Process
    {
        #region Input Validation
        if ([System.String]::IsNullOrEmpty($Path) -and [System.String]::IsNullOrEmpty($RsFolder)) 
        {
            throw 'No Folder or report Path was specified! You need to specify -RsFolder or -Path variable.'
        }
        #endregion Input Validation

        try {
            $parameters = $null

            foreach ($sub in $Subscription) 
            {
                if ($RsFolder) {
                    $Path = "$RsFolder/$($sub.Report)"
                }
                
                Write-Verbose "Validating if destination exists..."
                
                try 
                {
                    $object = Get-RsItemReference -Proxy $Proxy -Path $Path -ErrorAction SilentlyContinue
                }
                catch
                {
                    Write-Warning "Can't find the report $Path. Skipping. $($_.Exception.Message)"
                    Continue
                }
                
                Write-Verbose "Creating Subscription..."

                if ($PSCmdlet.ShouldProcess($Path, "Creating new subscription")) {
                    $subscriptionId = $Proxy.CreateSubscription($Path, $sub.DeliverySettings, $sub.Description, $sub.EventType, $sub.MatchData, $parameters)
                }

                [pscustomobject]@{
                    NewSubscriptionId = $subscriptionId
                    DestinationReport = $Path
                    OriginalReport    = $sub.Path
                }
                Write-Verbose "Subscription created successfully! Generated subscriptionId: $subscriptionId"
            }
        }
        catch
        {
            throw (New-Object System.Exception("Exception occurred while creating subscription! $($_.Exception.Message)", $_.Exception))
        }
    }
}
