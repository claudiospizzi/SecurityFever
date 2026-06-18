<#
    .SYNOPSIS
        Root module file.

    .DESCRIPTION
        The root module file loads all functions and helpers into the module
        context.
#>

[CmdletBinding()]
param
(
    # Enable debug mode for the module. This will allow to debug the module
    # functions and helpers using breakpoints but will slow down module loading
    # due to the slow dot-sourcing.
    [Parameter(Mandatory = $false)]
    [System.Boolean]
    $DebugModule = $false
)


## Module Core

# Module behavior
Set-StrictMode -Version 'Latest'
$Script:ErrorActionPreference = 'Stop'
$Script:ProgressPreference    = 'SilentlyContinue'


# Module metadata
$Script:PSModulePath    = [System.IO.Path]::GetDirectoryName($PSCommandPath)
$Script:PSModuleName    = [System.IO.Path]::GetFileName($PSCommandPath).Split('.')[0]
$Script:PSModuleVersion = (Import-PowerShellDataFile -Path "$Script:PSModulePath\$Script:PSModuleName.psd1")['ModuleVersion']


## Module Loader

# Get and add all .NET source code files as types (internal)
Get-ChildItem -Path "$Script:PSModulePath\Sources" -Filter '*.cs' -File -Recurse |
    ForEach-Object { Add-Type -Path $_.FullName }

# Get and dot source all functions
Get-ChildItem -Path "$Script:PSModulePath\Helpers", "$Script:PSModulePath\Functions" -Filter '*.ps1' -File -Recurse |
    ForEach-Object {
        if ($DebugModule -or $Env:PWSH_DEBUG_MODULE -eq 'true')
        {
            . $_.FullName
        }
        else
        {
            . ([System.Management.Automation.ScriptBlock]::Create(
                [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
            ))
        }
    }


## Module Context

# Path to the module configuration
$Script:ConfigurationPath = Join-Path -Path $PSScriptRoot -ChildPath 'Configurations'

# Add the impersonation context variables
$Script:ImpersonationContext = $null
$Script:PSReadlineHistorySaveStyle = $null
