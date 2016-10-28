#Requires -Version 5.0
#Requires -Modules Pester, PSScriptAnalyzer

<#
    .SYNOPSIS
    Test the PowerShell module with Pester and upload the results to AppVeyor.

    .DESCRIPTION
    Using Pester to execute all tests within the Tests folder. The tests result
    is dropped as NUnit XML file in the staging path. The test results can be
    uploaded to AppVeyor.
#>

[CmdletBinding()]
param
(
    # The PowerShell module project root path, derived from the current script
    # path by default.
    [Parameter(Mandatory = $false)]
    [System.String]
    $ProjectPath = ($PSScriptRoot | Split-Path),

    # The test stating path for the PowerShell module, where the NUnit test
    # result file is created. In the user temporary folder by default.
    [Parameter(Mandatory = $false)]
    [System.String]
    $StagingPath = $Env:TEMP,

    # Option to enable the AppVeyor specific build tasks.
    [Parameter(Mandatory = $false)]
    [Switch]
    $AppVeyor,

    # The dynamically created AppVeyor build job id.
    [Parameter(Mandatory = $false)]
    [System.String]
    $AppVeyorBuildJobId = $env:APPVEYOR_JOB_ID
)


## PREPARE

# Extract the module name from the modules folder, anything else from the module
# definition file.
$ModuleName    = (Get-ChildItem -Path "$ProjectPath\Modules" | Select-Object -First 1 -ExpandProperty Name)
$ModuleVersion = (Import-PowerShellDataFile -Path "$ProjectPath\Modules\$ModuleName\$ModuleName.psd1").ModuleVersion


## TEST

Write-Verbose "** TEST"

# Preload the meta tests
Invoke-Pester -Path "$ProjectPath\Tests" -TestName 'Meta Autoload'

# Use the Pester invoke command to execte all tests.
$TestResults = Invoke-Pester -Path "$ProjectPath\Tests" -OutputFormat NUnitXml -OutputFile "$StagingPath\$ModuleName-$ModuleVersion.NUnit.xml" -PassThru


## TEST (APPVEYOR)

if ($AppVeyor.IsPresent)
{
    Write-Verbose "** TEST (APPVEYOR)"

    $Source = "$StagingPath\$ModuleName-$ModuleVersion.NUnit.xml"
    $Target = "https://ci.appveyor.com/api/testresults/nunit/$AppVeyorBuildJobId"

    Write-Verbose "Upload $Source to $Target"

    $WebClient = New-Object -TypeName 'System.Net.WebClient'
    $WebClient.UploadFile($Target, $Source)

    # Finally, throw an exception if any test have failed
    if ($TestResults.FailedCount -gt 0)
    {
        throw "$($TestResults.FailedCount) test(s) failed!"
    }
}
