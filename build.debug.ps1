
# Append module path for auto-loading
$Env:PSModulePath = "$PSScriptRoot\Modules;$Env:PSModulePath"

# Import all modules for the debugging session
Get-ChildItem -Path "$PSScriptRoot\Modules" -Directory | ForEach-Object { Import-Module $_.BaseName }

# Now, stop the debugger at this point
Set-PSBreakpoint -Script "$PSScriptRoot\build.debug.ps1" -Line 10 | Out-Null
Write-Debug 'Stop debugger'

<# ------------------ PLACE DEBUG COMMANDS AFTER THIS LINE ------------------ #>
