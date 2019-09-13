
# Append module path for auto-loading
$Env:PSModulePath = "$PSScriptRoot\Modules;$Env:PSModulePath"

# Import all modules for the debugging session
Get-ChildItem -Path "$PSScriptRoot\Modules" -Directory | ForEach-Object { Remove-Module $_.BaseName -ErrorAction 'SilentlyContinue' }
Get-ChildItem -Path "$PSScriptRoot\Modules" -Directory | ForEach-Object { Import-Module $_.BaseName }

<# ------------------ PLACE DEBUG COMMANDS AFTER THIS LINE ------------------ #>
