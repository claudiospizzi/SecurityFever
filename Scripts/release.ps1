<#
    .SYNOPSIS
    ...

    .DESCRIPTION
    ...
    ...
    ...
#>

[CmdletBinding()]
param
(
    # The PowerShell module project root path, derived from the current script
    # path by default.
    [Parameter(Mandatory = $false)]
    [System.String]
    $ProjectPath = ($PSScriptRoot | Split-Path),

    # The release stating path for the PowerShell module, where the ZIP file is
    # created. In the user temporary folder by default.
    [Parameter(Mandatory = $false)]
    [System.String]
    $StagingPath = $Env:TEMP,

    # Option to enable the AppVeyor specific release tasks.
    [Parameter(Mandatory = $false)]
    [Switch]
    $AppVeyor
)


## PREPARE

# Extract the module name from the sources folder, anything else from the module
# definition file.
$ModuleName    = (Get-ChildItem -Path "$ProjectPath\Sources" | Select-Object -First 1 -ExpandProperty Name)
$ModuleVersion = (Import-PowerShellDataFile -Path "$ProjectPath\Sources\$ModuleName\$ModuleName.psd1").ModuleVersion





