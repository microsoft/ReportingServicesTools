# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

#Not in use right now - need email configuration on the report server

Describe 'New-RsScheduleXML' {

    $CurrentDate = Get-Date

    Context 'New-RsScheduleXML -Once' {
        
        $Schedule = New-RsScheduleXML -Once -Start $CurrentDate
        
        It 'Should return valid schedule XML' {
            @($Schedule).Count | Should Be 1
            $Schedule | Should BeOfType [String]
            { [xml]$Schedule } | Should Not Throw
        }
    }

    Context 'New-RsScheduleXML -Minute' {
        
        $Schedule = New-RsScheduleXML -Minute -Interval 90 -Start $CurrentDate
        
        It 'Should return valid schedule XML' {
            @($Schedule).Count | Should Be 1
            $Schedule | Should BeOfType [String]
            { [xml]$Schedule } | Should Not Throw
        }
    }

    Context 'New-RsScheduleXML -Daily' {
        
        $Schedule = New-RsScheduleXML -Daily -Interval 3 -Start $CurrentDate
        
        It 'Should return valid schedule XML' {
            @($Schedule).Count | Should Be 1
            $Schedule | Should BeOfType [String]
            { [xml]$Schedule } | Should Not Throw
        }
    }

    Context 'New-RsScheduleXML -Weekly' {
        
        $Schedule = New-RsScheduleXML -Weekly -Interval 2 -DaysOfWeek Monday,Tuesday,Wednesday -Start $CurrentDate
        
        It 'Should return valid schedule XML' {
            @($Schedule).Count | Should Be 1
            $Schedule | Should BeOfType [String]
            { [xml]$Schedule } | Should Not Throw
        }
    }

    Context 'New-RsScheduleXML -Monthly' {
        
        $Schedule = New-RsScheduleXML -Monthly -Months January,February,March -DaysOfMonth '1,2,3-7' -Start $CurrentDate
        
        It 'Should return valid schedule XML' {
            @($Schedule).Count | Should Be 1
            $Schedule | Should BeOfType [String]
            { [xml]$Schedule } | Should Not Throw
        }
    }

    Context 'New-RsScheduleXML -MonthlyDayOfWeek' {
        
        $Schedule = New-RsScheduleXML -MonthlyDayOfWeek -DaysOfWeek Thursday,Friday,Saturday,Sunday -Months April,May,June -WeekOfMonth LastWeek -Start $CurrentDate
        
        It 'Should return valid schedule XML' {
            @($Schedule).Count | Should Be 1
            $Schedule | Should BeOfType [String]
            { [xml]$Schedule } | Should Not Throw
        }
    }

    Context 'New-RsScheduleXML -End' {
        
        $Schedule = New-RsScheduleXML -End $CurrentDate
        
        It 'Should return valid schedule XML' {
            @($Schedule).Count | Should Be 1
            $Schedule | Should BeOfType [String]
            { [xml]$Schedule } | Should Not Throw
        }
    }
}