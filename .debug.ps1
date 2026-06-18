<#
    .SYNOPSIS
        PowerShell module debug script for Visual Studio Code. This file should
        be left as it is. Duplicated this file as .debug.temp.ps1 and add custom
        debug commands. The debugging session can be started from VS Code by the
        command 'Debug: Start Debugging' or pressing F5.
#>

# Load all modules in the repository
Get-ChildItem -Path $PSScriptRoot -Directory |
    ForEach-Object { '{0}\{1}.psd1'-f $_.FullName, $_.Name } |
        Where-Object { Test-Path -Path $_ } |
            Import-Module -Verbose -Force

# Place module debug commands after this line
