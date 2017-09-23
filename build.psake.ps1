
. $PSScriptRoot\build.settings.ps1

# Default task
Task Default -depends Build, Test


## Build tasks

# Overall build task
Task Build -depends Init, Clean, Compile, Stage, Merge

# Create release and test folders
Task Init -requiredVariables ReleasePath, PesterPath, ScriptAnalyzerPath {

    if (!(Test-Path -Path $ReleasePath))
    {
        New-Item -Path $ReleasePath -ItemType Directory -Verbose:$VerbosePreference > $null
    }

    if (!(Test-Path -Path $PesterPath))
    {
        New-Item -Path $PesterPath -ItemType Directory -Verbose:$VerbosePreference > $null
    }

    if (!(Test-Path -Path $ScriptAnalyzerPath))
    {
        New-Item -Path $ScriptAnalyzerPath -ItemType Directory -Verbose:$VerbosePreference > $null
    }
}

# Remove any items in the release and test folders
Task Clean -depends Init -requiredVariables ReleasePath, PesterPath, ScriptAnalyzerPath {

    Get-ChildItem -Path $ReleasePath | Remove-Item -Recurse -Force -Verbose:$VerbosePreference

    Get-ChildItem -Path $PesterPath | Remove-Item -Recurse -Force -Verbose:$VerbosePreference

    Get-ChildItem -Path $ScriptAnalyzerPath | Remove-Item -Recurse -Force -Verbose:$VerbosePreference
}

# Compile C# solutions
Task Compile -depends Clean -requiredVariables SourceEnabled, SourcePath, SourceNames {

    $msBuildPath = 'C:\Windows\Microsoft.NET\Framework\v4.0.30319'

    if (!$SourceEnabled)
    {
        return
    }

    if ($Env:Path -notlike "*$msBuildPath*")
    {
        $Env:Path = "$msBuildPath;$Env:Path"
    }

    foreach ($sourceName in $SourceNames)
    {
        $msBuildLog = (MSBuild.exe "$SourcePath\$sourceName.sln" /target:Build /p:Configuration=Release /verbosity:m)

        $msBuildLog | ForEach-Object { Write-Verbose $_ }
    }
}

# Copy all required module files to the release folder
Task Stage -depends Compile -requiredVariables ReleasePath, ModulePath, ModuleNames {

    foreach ($moduleName in $ModuleNames)
    {
        foreach ($item in (Get-ChildItem -Path "$ModulePath\$moduleName" -Exclude 'Functions', 'Helpers'))
        {
            Copy-Item -Path $item.FullName -Destination "$ReleasePath\$moduleName\$($item.Name)" -Recurse -Verbose:$VerbosePreference
        }
    }
}

# Merge the module by copying all helper and cmdlet functions to the psm1 file
Task Merge -depends Stage -requiredVariables ReleasePath, ModulePath, ModuleNames {

    foreach ($moduleName in $ModuleNames)
    {
        try
        {
            $moduleContent = New-Object -TypeName 'System.Collections.Generic.List[System.String]'

            # Load code for all function files
            foreach ($function in (Get-ChildItem -Path "$ModulePath\$moduleName\Functions" -Filter '*.ps1' -File -ErrorAction 'SilentlyContinue'))
            {
                $moduleContent.Add((Get-Content -Path $function.FullName -Raw))
            }

            # Load code for all helpers files
            foreach ($function in (Get-ChildItem -Path "$ModulePath\$moduleName\Helpers" -Filter '*.ps1' -File -ErrorAction 'SilentlyContinue'))
            {
                $moduleContent.Add((Get-Content -Path $function.FullName -Raw))
            }

            # Load code of the module file itself
            $moduleContent.Add((Get-Content -Path "$ModulePath\$moduleName\$moduleName.psm1" | Select-Object -Skip 15) -join "`r`n")

            # Concatenate whole code into the module file
            $moduleContent | Set-Content -Path "$ReleasePath\$moduleName\$moduleName.psm1" -Encoding UTF8 -Verbose:$VerbosePreference

            # Compress
            Compress-Archive -Path "$ReleasePath\$moduleName" -DestinationPath "$ReleasePath\$moduleName.zip" -Verbose:$VerbosePreference

            # Publish AppVeyor artifacts
            if ($env:APPVEYOR)
            {
                Push-AppveyorArtifact -Path "$ReleasePath\$moduleName.zip" -DeploymentName $moduleName -Verbose:$VerbosePreference
            }
        }
        catch
        {
            Assert -conditionToCheck $false -failureMessage "Build failed: $_"
        }
    }
}


## Test tasks

# Overall test task
Task Test -depends Build, Pester, ScriptAnalyzer

# Invoke Pester tests and return result as NUnit XML file
Task Pester -requiredVariables ReleasePath, ModuleNames, PesterPath, PesterFile {

    if (!(Get-Module -Name 'Pester' -ListAvailable))
    {
        Write-Warning "Pester module is not installed. Skipping $($psake.context.currentTaskName) task."
        return
    }

    Import-Module -Name 'Pester'

    foreach ($moduleName in $ModuleNames)
    {
        $modulePesterFile = Join-Path -Path $PesterPath -ChildPath "$moduleName-$PesterFile"

        powershell.exe -NoLogo -NoProfile -NonInteractive -Command "Set-Location -Path '$ReleasePath\$moduleName'; Invoke-Pester -OutputFile '$modulePesterFile' -OutputFormat 'NUnitXml'"

        $testResults = [Xml] (Get-Content -Path $modulePesterFile)

        Assert -conditionToCheck ($testResults.'test-results'.failures -eq 0) -failureMessage "One or more Pester tests failed, build cannot continue."

        # Publish AppVeyor test results
        if ($env:APPVEYOR)
        {
            $webClient = New-Object -TypeName 'System.Net.WebClient'
            $webClient.UploadFile("https://ci.appveyor.com/api/testresults/nunit/$env:APPVEYOR_JOB_ID", $modulePesterFile)
        }
    }
}

# Invoke Script Analyzer tests and stop if any test fails
Task ScriptAnalyzer -requiredVariables ReleasePath, ModulePath, ModuleNames, ScriptAnalyzerPath, ScriptAnalyzerFile, ScriptAnalyzerRules {

    if (!(Get-Module -Name 'PSScriptAnalyzer' -ListAvailable))
    {
        Write-Warning "PSScriptAnalyzer module is not installed. Skipping $($psake.context.currentTaskName) task."
        return
    }

    Import-Module -Name 'PSScriptAnalyzer'

    foreach ($moduleName in $ModuleNames)
    {
        $moduleScriptAnalyzerFile = Join-Path -Path $ScriptAnalyzerPath -ChildPath "$moduleName-$ScriptAnalyzerFile"

        $analyzeResults = Invoke-ScriptAnalyzer -Path "$ModulePath\$moduleName" -IncludeRule $ScriptAnalyzerRules -Recurse
        $analyzeResults | ConvertTo-Json | Out-File -FilePath $moduleScriptAnalyzerFile -Encoding UTF8

        Show-ScriptAnalyzerResult -ModuleName $moduleName -Rule $ScriptAnalyzerRules -Result $analyzeResults

        Assert -conditionToCheck ($analyzeResults.Count -eq 0) -failureMessage "One or more Script Analyzer tests failed, build cannot continue."
    }
}


## Deploy tasks

# Overall deploy task
Task Deploy -depends Test, Gallery, GitHub

# Deploy to the public PowerShell Gallery
Task Gallery -requiredVariables ReleasePath, ModuleNames, GalleryEnabled, GalleryName, GallerySource, GalleryPublish, GalleryKey {

    if (!$GalleryEnabled)
    {
        return
    }

    # Register the target PowerShell Gallery, if it does not exist
    if ($null -eq (Get-PSRepository -Name $GalleryName -ErrorAction SilentlyContinue))
    {
        Register-PSRepository -Name $GalleryName -SourceLocation $GallerySource -PublishLocation $GalleryPublish
    }

    foreach ($moduleName in $ModuleNames)
    {
        $moduleVersion = (Import-PowerShellDataFile -Path "$ReleasePath\$moduleName\$moduleName.psd1").ModuleVersion
        $releaseNotes  = Get-ReleaseNote -Version $moduleVersion

        Publish-Module -Path "$ReleasePath\$moduleName" -Repository $GalleryName -NuGetApiKey $GalleryKey -ReleaseNotes $releaseNotes
    }
}

# Deploy a release to the GitHub repository
Task GitHub -requiredVariables ReleasePath, ModuleNames, GitHubEnabled, GitHubRepoName, GitHubKey {

    if (!$GitHubEnabled)
    {
        return
    }

    foreach ($moduleName in $ModuleNames)
    {
        $moduleVersion = (Import-PowerShellDataFile -Path "$ReleasePath\$moduleName\$moduleName.psd1").ModuleVersion
        $releaseNotes  = Get-ReleaseNote -Version $moduleVersion

        # Create GitHub release
        $releaseParams = @{
            Method  = 'Post'
            Uri     = "https://api.github.com/repos/claudiospizzi/$GitHubRepoName/releases"
            Headers = @{
                'Accept'        = 'application/vnd.github.v3+json'
                'Authorization' = "token $GitHubKey"
            }
            Body   = @{
                tag_name         = $moduleVersion
                target_commitish = 'master'
                name             = "$moduleName v$moduleVersion"
                body             = ($releaseNotes -join "`n")
                draft            = $false
                prerelease       = $false
            } | ConvertTo-Json
        }
        $release = Invoke-RestMethod @releaseParams -ErrorAction Stop

        # Upload artifact to GitHub
        $artifactParams = @{
            Method          = 'Post'
            Uri             = "https://uploads.github.com/repos/claudiospizzi/$GitHubRepoName/releases/$($release.id)/assets?name=$moduleName-$moduleVersion.zip"
            Headers         = @{
                'Accept'        = 'application/vnd.github.v3+json'
                'Authorization' = "token $GitHubKey"
                'Content-Type'  = 'application/zip'
            }
            InFile          = "$ReleasePath\$ModuleName.zip"
        }
        $artifact = Invoke-RestMethod @artifactParams -ErrorAction Stop
    }
}


## Helper functions

# Show the Script Analyzer results on the host
function Show-ScriptAnalyzerResult($ModuleName, $Rule, $Result)
{
    $colorMap = @{
        Error       = 'Red'
        Warning     = 'Yellow'
        Information = 'Blue'
    }

    Write-Host "Module $ModuleName" -ForegroundColor Magenta

    foreach ($currentRule in $Rule)
    {
        Write-Host "   Rule $($currentRule.RuleName)" -ForegroundColor Magenta

        foreach ($record in $Result.Where({$_.RuleName -eq $currentRule.RuleName}))
        {
            Write-Host "    [-] $($record.Severity): $($record.Message)" -ForegroundColor $colorMap[[String]$record.Severity]
            Write-Host "      at $($record.ScriptPath): line $($record.Line)" -ForegroundColor $colorMap[[String]$record.Severity]

        }
    }

    Write-Host "Script Analyzer completed"
    Write-Host "Rules: $($Rule.Count) Failed: $($analyzeResults.Count)"
}

# Extract the Release Notes from the CHANGELOG.md file
function Get-ReleaseNote($Version)
{
    $changelogFile = Join-Path -Path $PSScriptRoot -ChildPath 'CHANGELOG.md'

    $releaseNotes = @()

    $isCurrentVersion = $false

    foreach ($line in (Get-Content -Path $changelogFile))
    {
        if ($line -eq "## $Version")
        {
            $isCurrentVersion = $true
        }
        elseif ($line -like '## *')
        {
            $isCurrentVersion = $false
        }

        if ($isCurrentVersion -and $line -like '- *')
        {
            $releaseNotes += $line
        }
    }

    Write-Output $releaseNotes
}
