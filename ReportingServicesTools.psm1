$scripts =  Get-ChildItem "$PSScriptRoot\Functions" -Recurse -Include *.ps1
foreach ($script in $scripts) { . $script }