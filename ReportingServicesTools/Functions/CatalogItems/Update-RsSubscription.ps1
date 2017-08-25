# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Update-RsSubscription
{
  <#
        .SYNOPSIS
            This script will update subscriptions piped from get-RsSubscriptions

        .DESCRIPTION
            This script will take the custom object producted by get-RSSubscription and use the data to update the 
            matchdata xml to either a new startdatetime, or enddate.

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
            $proxy = "http://ssrs-t-1234/Reportserver"
            Get-RsSubscription -ReportServerUri $proxy -path '/Finance/ImportantReports' | 
            where description -eq 'super important' | Update-RsSubscription -ReportServerUri $proxy -EndDate 9/9/2099

            assign proxy to variable for reuse.
            use get-rsssubscripion to find the 'super important' report in my /finance/importantreports path. Then Pipe the results
            to update-RsSubscription where we reuse the same $proxy to update the EndDate to 9/9/2099.

        .EXAMPLE
            $proxy = "http://ssrs-t-1234/Reportserver"

            [psobject]$subscriptions = Get-RsSubscription -ReportServerUri $proxy -path '/Finance/ImportantReports' | where description -eq 'super important' 
            $subscriptions | Update-RsSubscription -ReportServerUri $proxy -EndDate 9/9/2099 -StartDate 1/1/2016

            assign proxy to variable for reuse. 
            Then create a psobject variable to store the objects created from get-RSSubscription.
            Then Pipe the results to Update-RSSubscription where we reuse the same $proxy to update the EndDate to 9/9/2999 and StartDate to 1/1/2016
        
    #>
    
  [CmdletBinding()]
  param (
    [string]
    $ReportServerUri,
    [Alias('ReportServerCredentials')]
    [System.Management.Automation.PSCredential]
    $Credential,
    $Proxy,
    [parameter(Mandatory = $false)]
    [DateTime]$StartDateTime,
    [parameter(Mandatory = $false)]
    [DateTime]$EndDate,
    [Parameter(Mandatory = $true, ValueFromPipeLine)]
    [PSCustomObject[]]$SubProperties
        
  )
    
  Begin
  {
    $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    
  }
  Process
  {
    Write-Verbose "Updating Subscriptions..."
    try
    {
      [xml]$XMLMatch = $SubProperties.MatchData
            
      if ($StartDateTime)
      {
        $XMLMatch.ScheduleDefinition.StartDateTime.InnerText = $StartDateTime
      }
    
      if ($EndDate)
      {
        #check to see if end date exists as a node
        $EndExists = $XMLMatch.SelectNodes("//*") | Select-Object name | Where-Object name -eq "EndDate"
        #if no enddate create child node
        if ($EndExists -eq $null)
        {
          $child = $XMLMatch.CreateElement("EndDate")
          $child.InnerText = $EndDate
        
          $XMLMatch.ScheduleDefinition.AppendChild($child)
        
        }
        else
        {
          #if enddate node exists update  
          $XMLMatch.ScheduleDefinition.EndDate.InnerText = $EndDate         
        } 
        
      }
    
      if ($StartDateTime -ne $null -or $EndDate -ne $null)
      {
        $null = $Proxy.SetSubscriptionProperties($SubProperties.subscriptionID, $SubProperties.DeliverySettings, $SubProperties.Description, $SubProperties.EventType, $XMLMatch.OuterXml, $SubProperties.Values) 
        Write-Verbose "subscription $($SubProperties.subscriptionId) for $($SubProperties.report) report successfully updated!"
      }
    }
    Catch
    {
      throw (New-Object System.Exception("Exception while updating subscription(s)! $($_.Exception.Message)", $_.Exception))
    }
    
  }
}

