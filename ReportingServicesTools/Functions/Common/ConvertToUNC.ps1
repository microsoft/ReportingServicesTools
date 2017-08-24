# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function ConvertTo-UNCPath
{
    <#
        .SYNOPSIS
            This script creates a valid UNC path.
        
        .DESCRIPTION
            This script substitute the Resolve-Path cmdlet that can't handle UNC paths correctly
        
        .PARAMETER Path
            The UNC path to resolve

        .EXAMPLE
            Resolve-UNCPath "\\server\folder"

            Description
            -----------
            Will retrieve, using the Join-Path, the correct format "\\server\folder" otherwise would return "Microsoft.PowerShell.Core\FileSystem::\\server\folder" and fail

    #>

    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$True)]
        [String]$Path
    )
    
    return (Resolve-Path -Path $Path).ProviderPath
}

function ConvertTo-UNCFilePath
{
    <#
        .SYNOPSIS
            This script creates a valid UNC path.
        
        .DESCRIPTION
            This script substitute the Resolve-Path cmdlet that can't handle UNC paths correctly
        
        .PARAMETER Path
            The UNC path to resolve

        .EXAMPLE
            Resolve-UNCFilePath "\\server\folder\report.rdl"

            Description
            -----------
            Will retrieve, using the Join-Path, the correct format "\\server\folder\report.rdl" otherwise would return "Microsoft.PowerShell.Core\FileSystem::\\server\folder\report.rdl" and fail

    #>

    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$True)]
        [String]$FilePath
    )
    
    return Join-Path -Path (Resolve-Path -Path (Split-Path -Parent $FilePath)).ProviderPath -ChildPath (Split-Path -Leaf $FilePath)
}
