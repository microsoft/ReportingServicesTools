﻿Function New-RsScheduleXML {
    <#
        .SYNOPSIS
            This script creates an XML string representation of a subscription schedule.
        
        .DESCRIPTION
            This script creates an XML string representation of a subscription schedule for consumption by the 
            "New-RsSubscription" functions -Schedule parameter.
                    
        .PARAMETER Minute
            Run from the date and time specified by -Start by the number of minutes specified by -Interval
        
        .PARAMETER Daily
            Run daily at the date and time specified by -Start and by the day frequency specified by -Interval
        
        .PARAMETER Weekly
            Run weekly on all days or specific days as specified by -DaysOfWeek
                
        .PARAMETER Monthly
            Run monthly on all months or specific months specified by -Months
        
        .PARAMETER MonthlyDayOfWeek
            Run monthly on a week of the month as specified by -WeekOfMonth and on days as specified by -DaysOfWeek
        
        .PARAMETER Once
            Run once at the time and date specified by -Start
        
        .PARAMETER Interval
            A number representing the minutes, days or weeks interval when used with -Minute -Daily or -Weekly respectively.
        
        .PARAMETER DaysOfWeek
            One or days of the week by name, e.g 'Sunday','Tuesday','Thursday','Saturday'

        .PARAMETER Months
            One or more months by name, e.g 'March','June','September','December'

        .PARAMETER DaysOfMonth
            A single string representing the dates of the month, e.g: '1,3,5,10-15'
        
        .PARAMETER WeekOfMonth
            The week of the month as specified as FirstWeek, SecondWeek, ThirdWeek, FourthWeek or LastWeek.
        
        .PARAMETER Start
            The date and time the schedule should start. Default: now

        .PARAMETER End
            The date and time the schedule should end.

        .EXAMPLE
            New-RsScheduleXML -Once -Start '01/02/2017 12:34'

            Description
            -----------
            Creates an XML string to schedule a subscription to run once at the date/time specified.

        .EXAMPLE
            New-RsScheduleXML -Minute -Interval 90 -Start '21:00'

            Description
            -----------
            Creates an XML string to schedule a subscription to run every 90 minutes starting at 9pm.

        .EXAMPLE
            New-RsScheduleXML -Daily -Interval 5

            Description
            -----------
            Creates an XML string to schedule a subscription to run every 5 days starting at the current date/time.

        .EXAMPLE
            New-RsScheduleXML -Weekly -Interval 2 -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday

            Description
            -----------
            Creates an XML string to schedule a subscription to run every 2 weeks on weekdays at the current time.
       
       .EXAMPLE
            New-RsScheduleXML -Monthly -DaysOfMonth '1-15,20' -Months January,March,May -Start 5pm -End 12/12/2017

            Description
            -----------
            Creates an XML string to schedule a subscription to run on the 1st-15th and 20th of January, March and 
            May at 5pm until 12th December 2017.
            
            Note that -DaysOfMonth is always provided a single string.

        .EXAMPLE
            New-RsScheduleXML -MonthlyDayOfWeek -DaysOfWeek Saturday -WeekOfMonth LastWeek -Months January,July

            Description
            -----------
            Creates an XML string to schedule a subscription to run on the last Saturday of January and July.
    #>

    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low',DefaultParameterSetName='Once')]
    [OutputType(‘System.String’)]
    Param(
        [Parameter(ParameterSetName='Minute')]
        [Switch]      
        $Minute,
        
        [Parameter(ParameterSetName='Daily')]
        [Switch]      
        $Daily,

        [Parameter(ParameterSetName='Weekly')]
        [Switch]      
        $Weekly,

        [Parameter(ParameterSetName='Monthly')]
        [Switch]      
        $Monthly,

        [Parameter(ParameterSetName='MonthlyDOW')]
        [Switch]      
        $MonthlyDayOfWeek,
        
        [Parameter(ParameterSetName='Once')]
        [Switch]      
        $Once,

        [Parameter(ParameterSetName='Minute',Mandatory=$True,Position=0)]
        [Parameter(ParameterSetName='Daily',Mandatory=$True,Position=0)]
        [Parameter(ParameterSetName='Weekly',Mandatory=$True,Position=0)]
        [Int]
        $Interval = 1,

        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='MonthlyDOW')]
        [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
        [String[]]
        $DaysOfWeek,

        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='MonthlyDOW')]
        [ValidateSet('January','February','March','April','May','June','July','August','September','October','November','December')]
        [String[]]
        $Months,

        [Parameter(ParameterSetName='Monthly',Mandatory=$True)]
        [String]
        $DaysOfMonth,

        [Parameter(ParameterSetName='MonthlyDOW',Mandatory=$True)]
        [ValidateSet('FirstWeek','SecondWeek','ThirdWeek','FourthWeek','LastWeek')]
        [String]
        $WeekOfMonth,

        [DateTime]
        $Start = (Get-Date),

        [DateTime]
        $End

    )
    Process {
        $Schedule = $null
        If ($Minute)           { $Schedule = 'Minute' }
        If ($Daily)            { $Schedule = 'Daily' }
        If ($Weekly)           { $Schedule = 'Weekly' }
        If ($Monthly)          { $Schedule = 'Monthly' }
        If ($MonthlyDayOfWeek) { $Schedule = 'MonthlyDOW' }

        $StartDateTime = Get-Date $Start -Format s

        If ($End) { $EndDateTime = Get-Date $End -Format s }
        
        $Recurrence = Switch ($Schedule) {
            'Minute'     { @{ MinutesInterval = $Interval } }
            'Daily'      { @{ DaysInterval    = $Interval } }
            'Weekly'     { @{ WeeksInterval   = $Interval } }
            'Monthly'    { @{ Days            = $DaysOfMonth } }
            'MonthlyDOW' { @{ WhichWeek       = $WeekOfMonth } }
            default      { $null }
        }

        If ($Recurrence) { $ScheduleXML     = $Recurrence.GetEnumerator() | ForEach-Object { If ($_.Value) { "<$($_.Name)>$($_.Value)</$($_.Name)>`n" } } }
        If ($DaysOfWeek) { $DaysOfWeekXML   = $DaysOfWeek | ForEach-Object -Begin { "<DaysOfWeek>`n" } { "<$_>$True</$_>`n" } -End  { "</DaysOfWeek>`n" } }
        If ($Months)     { $MonthsOfYearXML = $Months     | ForEach-Object -Begin { "<MonthsOfYear>`n" } { "<$_>$True</$_>`n" } -End  { "</MonthsOfYear>`n" } }

        If ($PSCmdlet.ShouldProcess("Outputting Subscription Schedule XML")) {
            $XML =  "<ScheduleDefinition>"
            $XML += "<StartDateTime>$StartDateTime</StartDateTime>"
            If ($EndDateTime)     { $XML += "<EndDate>$EndDateTime</EndDate>" }
            If ($Schedule)        { $XML += "<$Schedule`Recurrence>" }
            If ($ScheduleXML)     { $XML += $ScheduleXML }
            If ($DaysOfWeekXML)   { $XML += $DaysOfWeekXML }
            If ($MonthsOfYearXML) { $XML += $MonthsOfYearXML }
            If ($Schedule)        { $XML += "</$Schedule`Recurrence>" }
            $XML += "</ScheduleDefinition>"

            $XML
        }
    }
}