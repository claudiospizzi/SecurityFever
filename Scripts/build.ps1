<#
    .SYNOPSIS
    Build the PowerShell module and upload the artifact to AppVeyor.

    .DESCRIPTION
    Build a PowerShell module means creating a ZIP file with the necessary
    files. If needed, the created ZIP file can be uploaded to the current
    running AppVeyor build.
#>

[CmdletBinding()]
param
(
    # The PowerShell module project root path, derived from the current script
    # path by default.
    [Parameter(Mandatory = $false)]
    [System.String]
    $ProjectPath = ($PSScriptRoot | Split-Path),

    # The build stating path for the PowerShell module, where the ZIP file is
    # created. In the user temporary folder by default.
    [Parameter(Mandatory = $false)]
    [System.String]
    $StagingPath = $Env:TEMP,

    # Option to enable the AppVeyor specific build tasks.
    [Parameter(Mandatory = $false)]
    [Switch]
    $AppVeyor,

    # The dynamically created AppVeyor build number.
    [Parameter(Mandatory = $false)]
    [System.String]
    $AppVeyorBuildNumber = $env:APPVEYOR_BUILD_NUMBER
)


## PREPARE

# Extract the module name from the sources folder, anything else from the module
# definition file.
$ModuleName    = (Get-ChildItem -Path "$ProjectPath\Sources" | Select-Object -First 1 -ExpandProperty Name)
$ModuleVersion = (Import-PowerShellDataFile -Path "$ProjectPath\Sources\$ModuleName\$ModuleName.psd1").ModuleVersion



## BUILD

Write-Verbose '** BUILD'

# Create a file catalog for the module folder. The catalog file will contain
# hashes for all files. This is used to validate the whole module content.
New-FileCatalog -Path "$ProjectPath\Sources\$ModuleName" -CatalogFilePath "$ProjectPath\Sources\$ModuleName\$ModuleName.cat" -CatalogVersion 2.0

# In case of PowerShell, creating a build means zipping the requried files.
# Thanks to the project structure, all requried but no extra files are in
# the sources folder.
Compress-Archive -Path "$ProjectPath\Sources\$ModuleName" -DestinationPath "$StagingPath\$ModuleName-$ModuleVersion.zip" -Force -Verbose:$VerbosePreference


## BUILD (APPVEYOR)

if ($AppVeyor.IsPresent)
{
    Write-Verbose '** BUILD (APPVEYOR)'

    # Use the provided cmdlet to push the artifact to AppVeyor.
    Push-AppveyorArtifact -Path "$StagingPath\$ModuleName-$ModuleVersion.zip" -DeploymentName 'Module' -Verbose:$VerbosePreference
}
