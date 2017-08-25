Fixes # 66.

Changes proposed in this pull request:
 - update/add existing subscription enddate
 - update startdatetime of existing subscription
 - 

How to test this code:
 - 
$proxy = "http://SSRS/Reportserver"
get-rssubscription -ReportServerUri $proxy -path '/Operations/REPORT' | Update-RsSubscription -ReportServerUri $proxy -EndDate 9/10/2020  -StartDateTime 7/1/2015

 - 
 - 

Has been tested on (remove any that don't apply):
 - Powershell 3 and above
 - Windows 7 and above
 - SQL Server 2012 and above
