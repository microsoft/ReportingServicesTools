# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsRestItemDataSources
{
    <#
        .SYNOPSIS
            This script updates data sources related to a catalog item from the Report Server

        .DESCRIPTION
            This script updates data sources related to a catalog item from the Report Server

        .PARAMETER RsItem
            Specify the updated OData payload which was fetched via Get-RsRestItemDataSources.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Set-RsRestItemDataSources -RsItem $myReport

            Description
            -----------
            Updates data sources using the specified $myReport OData Payload.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [object]
        $RsItem,

        [string]
        $ReportPortalUri,

        [Alias('ApiVersion')]
        [ValidateSet("v2.0")]
        [string]
        $RestApiVersion = "v2.0",

        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )
    Begin
    {
        $WebSession = New-RsRestSessionHelper -BoundParameters $PSBoundParameters
        $ReportPortalUri = Get-RsPortalUriHelper -WebSession $WebSession
        $dataSourcesUri = $ReportPortalUri + "api/$RestApiVersion/{0}({1})/DataSources"
    }
    Process
    {
        if ($RsItem.Type -ne "Report" -and
            $RsItem.Type -ne "PowerBIReport" -and
            $RsItem.Type -ne "DataSet")
        {
            throw 'Invalid item specified! Currently you can update item data sources only for Report, PowerBIReport and Dataset.'
        }

        try
        {
            $dataSourcesUri = [String]::Format($dataSourcesUri, $RsItem.Type + "s", $RsItem.Id)

            # Depth needs to be specified otherwise whenever DataModelDataSource is present
            # Supported Auth Types will not be serialized correctly
            $payloadJson = ConvertTo-Json -InputObject $RsItem.DataSources -Depth 3

            if ($RsItem.Type -eq "DataSet" -or $RsItem.Type -eq "Report")
            {
                $method = "PUT"
            }
            else
            {
                $method = "PATCH"
            }

            Write-Verbose "Updating data sources for $($RsItem.Name)..."
            if ($Credential -ne $null)
            {
                Invoke-WebRequest -Uri $dataSourcesUri -Method $method -Body $payloadJson -ContentType "application/json" -WebSession $WebSession -Credential $Credential -Verbose:$false | Out-Null
            }
            else
            {
                Invoke-WebRequest -Uri $dataSourcesUri -Method $method -Body $payloadJson -ContentType "application/json" -WebSession $WebSession -UseDefaultCredentials -Verbose:$false | Out-Null
            }
            Write-Verbose "Data sources were updated successfully!"
        }
        catch
        {
            throw (New-Object System.Exception("Failed to update data sources for '$($RsItem.Name)': $($_.Exception.Message)", $_.Exception))
        }
    }
}