#Requires -Version 5.0

<#
    .SYNOPSIS
    Release the PowerShell module and upload the artifact to AppVeyor.

    .DESCRIPTION
    Use the GitHub REST api to create a new release for the version tag and
    upload the ZIP module artifact to the release. In addition, publish the
    module to the PowerShell Gallery.
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
    $AppVeyor,

    # The securely stored GitHub token
    [Parameter(Mandatory = $false)]
    [System.String]
    $GitHubToken = $env:GitHubToken,

    # The securely stored PowerShell Gallery key
    [Parameter(Mandatory = $false)]
    [System.String]
    $PSGalleryKey = $env:PSGalleryKey
)


## PREPARE

# Extract the module name from the modules folder, anything else from the module
# definition file.
$ModuleName    = (Get-ChildItem -Path "$ProjectPath\Modules" | Select-Object -First 1 -ExpandProperty Name)
$ModuleVersion = (Import-PowerShellDataFile -Path "$ProjectPath\Modules\$ModuleName\$ModuleName.psd1").ModuleVersion


## RELEASE (APPVEYOR)

if ($AppVeyor.IsPresent)
{
    if ($env:APPVEYOR_REPO_TAG -eq 'true' -and $env:APPVEYOR_REPO_BRANCH -eq 'master')
    {
        Write-Verbose '** RELEASE (APPVEYOR)'

        $releaseVersion = $env:APPVEYOR_REPO_TAG_NAME
        $releaseName    = "$ModuleName v$releaseVersion"
        $releaseNotes   = $env:APPVEYOR_REPO_COMMIT_MESSAGE + $env:APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED + " "
        $releaseAsset   = "$ModuleName-$releaseVersion.zip"

        # Check it the module and release (tag) version match
        if ($ModuleVersion -ne $releaseVersion)
        {
            throw "Module and release (tag) version do not match!"
        }


        Write-Verbose '** RELEASE (APPVEYOR) [GITHUB]'

        # Create GitHub release
        $releaseGitHubReleaseParam = @{
            Method  = 'Post'
            Uri     = "https://api.github.com/repos/claudiospizzi/$ModuleName/releases"
            Headers = @{
                'Accept'        = 'application/vnd.github.v3+json'
                'Authorization' = "token $GitHubToken"
            }
            Body   = @{
                tag_name         = $releaseVersion
                target_commitish = 'master'
                name             = $releaseName
                body             = $releaseNotes
                draft            = $false
                prerelease       = $false
            } | ConvertTo-Json
        }
        $releaseGitHubRelease = Invoke-RestMethod @releaseGitHubReleaseParam -ErrorAction Stop

        # Upload artifact to GitHub
        $releaseGitHubArtifactParam = @{
            Method          = 'Post'
            Uri             = "https://uploads.github.com/repos/claudiospizzi/$ModuleName/releases/$($releaseGitHubRelease.id)/assets?name=$ModuleName-$releaseVersion.zip"
            Headers         = @{
                'Accept'        = 'application/vnd.github.v3+json'
                'Authorization' = "token $GitHubToken"
                'Content-Type'  = 'application/zip'
            }
            InFile          = "$StagingPath\$ModuleName-$ModuleVersion.zip"
        }
        $releaseGitHubArtifact = Invoke-RestMethod @releaseGitHubArtifactParam -ErrorAction Stop


        Write-Verbose '** RELEASE (APPVEYOR) [PSGALLERY]'

        # Update the module path
        $env:PSModulePath += ';' + "$ProjectPath\Modules"

        # Publish to module to the PowerShell Gallery
        Publish-Module -Name $ModuleName -RequiredVersion $releaseVersion -NuGetApiKey $PSGalleryKey -ErrorAction Stop
    }
}
