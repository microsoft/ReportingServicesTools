# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsScheduleXml
{
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
            New-RsScheduleXml -Once -Start '01/02/2017 12:34'

            Description
            -----------
            Creates an XML string to schedule a subscription to run once at the date/time specified.

        .EXAMPLE
            New-RsScheduleXml -Minute -Interval 90 -Start '21:00'

            Description
            -----------
            Creates an XML string to schedule a subscription to run every 90 minutes starting at 9pm.

        .EXAMPLE
            New-RsScheduleXml -Daily -Interval 5

            Description
            -----------
            Creates an XML string to schedule a subscription to run every 5 days starting at the current date/time.

        .EXAMPLE
            New-RsScheduleXml -Weekly -Interval 2 -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday

            Description
            -----------
            Creates an XML string to schedule a subscription to run every 2 weeks on weekdays at the current time.
       
       .EXAMPLE
            New-RsScheduleXml -Monthly -DaysOfMonth '1-15,20' -Months January,March,May -Start 5pm -End 12/12/2017

            Description
            -----------
            Creates an XML string to schedule a subscription to run on the 1st-15th and 20th of January, March and 
            May at 5pm until 12th December 2017.
            
            Note that -DaysOfMonth is always provided a single string.

        .EXAMPLE
            New-RsScheduleXml -MonthlyDayOfWeek -DaysOfWeek Saturday -WeekOfMonth LastWeek -Months January,July

            Description
            -----------
            Creates an XML string to schedule a subscription to run on the last Saturday of January and July.
    #>

    [cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact='Low', DefaultParameterSetName='Once')]
    [OutputType(‘System.String’)]
    param
    (
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

        [Parameter(ParameterSetName='Minute',Position=0)]
        [Parameter(ParameterSetName='Daily',Position=0)]
        [Parameter(ParameterSetName='Weekly',Position=0)]
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

        [ValidateNotNullOrEmpty()]
        [DateTime]
        $Start = (Get-Date),

        [DateTime]
        $End
    )

    Process {
        $StartDateTime = (Get-Date $Start -Format s)

        if ($End) 
        { 
            $EndDateTime = (Get-Date $End -Format s)
        }

        $Schedule = $PSCmdlet.ParameterSetName

        switch ($Schedule) {
            'Minute'     { $ScheduleXML = "<MinutesInterval>$Interval</MinutesInterval>`n" }
            'Daily'      { $ScheduleXML = "<DaysInterval>$Interval</DaysInterval>`n" }
            'Weekly'     { $ScheduleXML = "<WeeksInterval>$Interval</WeeksInterval>`n" }
            'Monthly'    { $ScheduleXML = "<Days>$DaysOfMonth</Days>`n" }
            'MonthlyDOW' { $ScheduleXML = "<WhichWeek>$WeekOfMonth</WhichWeek>`n" }
            default      { $ScheduleXML = $null }
        }
        
        if ($DaysOfWeek) 
        {
            $DaysOfWeekXML = "<DaysOfWeek>`n"
            $DaysOfWeek | ForEach-Object { $DaysOfWeekXML = $DaysOfWeekXML + "<$_>$True</$_>`n" }
            $DaysOfWeekXML = $DaysOfWeekXML + "</DaysOfWeek>`n"
        }
        
        if ($Months) 
        {
            $MonthsOfYearXML = "<MonthsOfYear>`n"
            $Months | ForEach-Object { $MonthsOfYearXML = $MonthsOfYearXML + "<$_>$True</$_>`n" } 
            $MonthsOfYearXML = $MonthsOfYearXML + "</MonthsOfYear>`n"
        }

        $XML =  '<ScheduleDefinition>'
        $XML = $XML + "<StartDateTime>$StartDateTime</StartDateTime>"
        
        if ($EndDateTime)     { $XML = $XML + "<EndDate>$EndDateTime</EndDate>" }
        if ($ScheduleXML)     { $XML = $XML + "<$Schedule`Recurrence>" }
        if ($ScheduleXML)     { $XML = $XML + $ScheduleXML }
        if ($DaysOfWeekXML)   { $XML = $XML + $DaysOfWeekXML }
        if ($MonthsOfYearXML) { $XML = $XML + $MonthsOfYearXML }
        if ($ScheduleXML)     { $XML = $XML + "</$Schedule`Recurrence>" }
        
        $XML = $XML + '</ScheduleDefinition>'

        if ($PSCmdlet.ShouldProcess('Outputting Subscription Schedule XML')) 
        {
            $XML
        }
    }
}