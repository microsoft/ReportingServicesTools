# Octopus deploy module export
$mainScript = "$PSScriptRoot\ReportingServicesTools.Designer.ps1"
@('# AUTO GENERATED SCRIPT') | sc -path $mainScript 
gc "$PSScriptRoot\Libraries\library.ps1" | ac -path $mainScript

$mainScript

$scripts =  Get-ChildItem "$PSScriptRoot\Functions" -Recurse -Include *.ps1
foreach ($script in $scripts) { gc $script | ac -path $mainScript }