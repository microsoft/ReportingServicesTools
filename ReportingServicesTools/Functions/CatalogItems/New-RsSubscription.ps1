Function New-RsSubscription {
    <#
        .SYNOPSIS
            This script creates a new reporting subscription.
        
        .DESCRIPTION
            This script creates a new reporting subscription based on the parameters provided. NOTE: A new subscriptionId will be generated.
                    
        .PARAMETER Path
            Specify the path to the destination report.
        
        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance. Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server. Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Proxy
            Report server proxy to use. Use "New-RsWebServiceProxy" to generate a proxy object for reuse. Useful when repeatedly having to connect to multiple different Report Server.

        .PARAMETER Description
            The description of the schedule.

        .PARAMETER EventType
            The event which triggers the schedule. Specify either 'TimedSubscription' or 'SnapshotUpdated'.
            Default: 'TimedSubscription'.

        .PARAMETER Destination
            The delivery destination. Specify either 'FileShare', 'Email' or (not yet supported) 'DocumentLibrary'.

        .PARAMETER Schedule
            Either a shared schedule ID or an XML block representing the desired schedule. You can use "New-RsScheduleXML" function to generate the required XML. 
            Required if -EventType 'TimedSubscription' has been used.

        .PARAMETER To
            Use with -Destination 'Email' to specify email addresses.

        .PARAMETER CC
            Use with -Destination 'Email' to specify CC email addresses.

        .PARAMETER BCC
            Use with -Destination 'Email' to specify BCC email addresses.

        .PARAMETER ExcludeReport
            Use with -Destination 'Email' to exclude the report from the email.
            
        .PARAMETER Subject
            Use with -Destination 'Email' to specify the subject line of the email.

        .PARAMETER DestinationPath
            Use with -Destination 'FileShare' to specify the destination location of the generated report. Must be a UNC path.

        .PARAMETER FileName
            Use with -Destination 'FileShare' to specify the filename of the generated report.

        .PARAMETER RenderFormat
            Specify the output format of the report. Must be one of 'PDF','MHTML','IMAGE','CSV','XML','EXCELOPENXML','ATOM','PPTX','WORDOPENXML'
        
        .EXAMPLE
            New-RsSubscription -ReportServerUri 'http://localhost/ReportServer' -Path '/path/to/my/Report' -Description 'Daily to folder' -Destination 'FileShare' -Schedule (New-RsScheduleXML -Daily 1) -DestinationPath '\\Myserver\folder' -FileName 'MyReport' -RenderFormat 'PDF'

            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/ReportServer_sql14 using current user's credentials and create a subscription for report '/path/to/my/Report'
            that outputs the report in PDF format to the specified file share path and name on a daily basis at the current time.

        .EXAMPLE
            New-RsSubscription -ReportServerUri 'http://localhost/ReportServer' -Path '/path/to/my/Report' -Description 'Fortnightly by email' -Destination 'Email' -Schedule (New-RsScheduleXML -Weekly -Interval 2 -DaysOfWeek Saturday) -Subject 'Fortnightly report' -To 'test@someaddress.com' -RenderFormat 'WordOpenXML'

            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/ReportServer_sql14 using current user's credentials and create a subscription for report '/path/to/my/Report'
            that outputs the report in Word format by email to the specified recipient every other Saturday at the current time.
    #>
    
    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium',DefaultParameterSetName='FileShare')]
    Param(
        [string]
        $ReportServerUri,
        
        [System.Management.Automation.PSCredential]
        $Credential,

        $Proxy,

        [Alias('ReportPath','ItemPath')]
        [Parameter(Mandatory=$True)]
        [string]
        $Path,

        [string]
        $Description,

        [ValidateSet('TimedSubscription','SnapshotUpdated')] 
        [string]
        $EventType = 'TimedSubscription',

        [Parameter(Mandatory=$True)]
        [ValidateSet('DocumentLibrary','Email','FileShare')] 
        [string]
        $Destination,

        [string]
        $Schedule,

        [Parameter(ParameterSetName='Email',Mandatory=$True)]
        [string]
        $To,

        [Parameter(ParameterSetName='Email')]
        [string]
        $CC,

        [Parameter(ParameterSetName='Email')]
        [string]
        $BCC,

        [Parameter(ParameterSetName='Email')]
        [switch]
        $ExcludeReport,

        [Parameter(ParameterSetName='Email',Mandatory=$True)]
        [string]
        $Subject,

        [Parameter(ParameterSetName='FileShare',Mandatory=$True)]
        [string]
        $DestinationPath,

        [Parameter(ParameterSetName='FileShare',Mandatory=$True)]
        [string]
        $Filename,

        [Parameter(Mandatory=$True)]
        [ValidateSet('PDF','MHTML','IMAGE','CSV','XML','EXCELOPENXML','ATOM','PPTX','WORDOPENXML')]
        [string]
        $RenderFormat = 'PDF'
    )
    Begin {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }
    Process {

        If ([System.String]::IsNullOrEmpty($Path)) {
            Throw 'No report Path was specified! You need to specify -Path variable.'
        }

        If ($Destination -eq 'DocumentLibrary') { Throw 'DocumentLibrary is not yet supported by this cmdlet. Sorry!' }
        
        Try {
            Write-Verbose "Validating if destination exists..."
                
            if (((Get-RsFolderContent -Proxy $Proxy -RsFolder ((Split-Path $Path -Parent).Replace('\','/')) | Where-Object Path -eq $Path).Count) -eq 0){
                Write-Warning "Can't find the report $Path. Skipping."
                Continue
            }            
            
            $Namespace = $Proxy.GetType().NameSpace
        
            $Params = Switch ($Destination) {
                'DocumentLibrary' { 
                    @{
                        # Not yet supported
                    } 
                }
                'Email' {
                    @{
                        TO = $To
                        CC = $CC
                        BCC = $BCC
                        IncludeReport = (-not $ExcludeReport)
                        Subject = $Subject
                        RenderFormat = $RenderFormat
                    }
                }
                'FileShare' {
                    @{
                        PATH = $DestinationPath
                        FILENAME = $Filename
                        RENDER_FORMAT = $RenderFormat
                    }
                }
            }
    
            $ParameterValues = @()

            $Params.GetEnumerator() | ForEach-Object {
                $ParameterValues = $ParameterValues + (New-Object "$Namespace.ParameterValue" -Property @{ Name = $_.Name; Value = $_.Value })
            }
            
            $ExtensionSettings = New-Object "$Namespace.ExtensionSettings" -Property @{ Extension = "Report Server $Destination"; ParameterValues = $ParameterValues }
        
            $MatchData = $Schedule
            $Parameters = $Null

            Write-Verbose "Creating Subscription..."

            If ($PSCmdlet.ShouldProcess($Path, "Creating new subscription")) {
                $subscriptionId = $Proxy.CreateSubscription($Path,$ExtensionSettings,$Description,$EventType,$MatchData,$Parameters)

                [pscustomobject]@{
                    NewSubscriptionId = $subscriptionId
                }
            }

            Write-Verbose "Subscription created successfully! Generated subscriptionId: $subscriptionId"

        } Catch {
            Throw (New-Object System.Exception("Exception occurred while creating subscription! $($_.Exception.Message)", $_.Exception))
        }
    }
}