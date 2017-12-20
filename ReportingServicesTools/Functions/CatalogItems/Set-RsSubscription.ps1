# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Set-RsSubscription
{
  <#
        .SYNOPSIS
            This script will update subscriptions piped from Get-RsSubscriptions

        .DESCRIPTION
            This script will take the custom object producted by get-RSSubscription and use the data to update the 
            matchdata xml to either a new startdatetime, enddate, or owner.

        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.

        .PARAMETER StartDateTime
            StartDateTime to change Start Date and Time of subscription.
        
        .PARAMETER EndDate
            Used to change the EndDate of subscription. 

        .PARAMETER Owner
            Used to change the owner of a subscription. 
            
          
        .EXAMPLE
            Get-RsSubscription -path '/Finance/ImportantReports' | Set-RsSubscription -EndDate 9/9/2099

            Description
            -----------
            Update all subscriptions on localhost associated with '/finance/ImportantReports' to have an EndDate of 9/9/2099

        .EXAMPLE
            Get-RsSubscription -path '/Finance/ImportantReports' | Set-RsSubscription -StartDateTime "1/9/2017 9am"

            Description
            -----------
            Update all subscriptions on localhost associated with '/finance/ImportantReports' to have a startdate of 1/9/2017 and time of 9am
        
        .EXAMPLE
            Get-RsSubscription -path '/Finance/ImportantReports' | Set-RsSubscription -Owner "Warren"

            Description
            -----------
            Update all subscriptions on localhost associated with '/finance/ImportantReports' to have an owner of "Warren".
            The user being updated needs to have the correct permissions in order to successfully update the owner.
        
    #>
    
  [CmdletBinding()]
  param (
    [string]
    $ReportServerUri,
    
    [System.Management.Automation.PSCredential]
    $Credential,

    $Proxy,

    [parameter(Mandatory = $false)]
    [DateTime]$StartDateTime,

    [parameter(Mandatory = $false)]
    [DateTime]$EndDate,

    [parameter(Mandatory = $False)]
    [string]$Owner,

    [Parameter(Mandatory=$true,ValueFromPipeLine)]
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

    if ($owner){
    $proxy.ChangeSubscriptionOwner($SubProperties.subscriptionID,$owner)
    }

            
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

