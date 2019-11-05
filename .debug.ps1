
Get-ChildItem -Path $PSScriptRoot -Directory |
ForEach-Object { '{0}\{1}.psd1'-f $_.FullName, $_.Name } |
    Where-Object { Test-Path -Path $_ } |
        Import-Module -Verbose -Force

<# ------------------ PLACE DEBUG COMMANDS AFTER THIS LINE ------------------ #>
