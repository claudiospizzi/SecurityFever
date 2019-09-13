<#
    .SYNOPSIS
        PowerShell module build script based on psake.

    .DESCRIPTION
        This psake build script supports building PowerShell manifest modules
        which contain PowerShell script functions and optionally binary .NET C#
        libraries. The build script contains the following tasks.

        - Task Verify
          Before any build task runs, verify that the build scripts are current.

        - Task Init
          Create folders, which are used by the build system: /tst and /bin.

        - Task Clean
          Cleans the content of build paths to ensure no side effects of
          previous build with the current build.

        - Task Compile
          If required, compile the Visual Studio solutions. Ensure that the
          build system copies the result into the target module folder.

        - Task Stage
          Copy all module files to the build directory excluding the class,
          function, helper and test files. These files get merged in the .psm1
          file.

        - Task Merge
          Copy the content of all .ps1 files within the classes, functions and
          helpers folders to the .psm1 file. This ensures a faster loading time
          for the module, but still a nice development experience with one
          function per file. This is optional and can be controlled by the
          setting $ModuleMerge.

        - Task Pester
          Invoke all Pester tests within the module and ensure that all tests
          pass before the build script continues.

        - Task ScriptAnalyzer
          Invoke all Script Analyzer rules against the PowerShell script files
          and ensure, that they do not break any rule.

        - Task Gallery
          This task will publish the module to a PowerShell Gallery. The task is
          not part of the default tasks, it needs to be called manually if
          needed during a deployment.

        - Task GitHub
          This task will publish the module to the GitHub Releases. The task is
          not part of the default tasks, it needs to be called manually if
          needed during a deployment.

        The tasks are grouped to the following task groups. The deploy task is
        not part of the default tasks, this must be invoked manually.

        - Group Default
          Task to group the other groups Build and Test. This will be invoked by
          default, if Invoke-psake is invoked.

        - Group Build
          The build task group will invoke the tasks Init, Clean, Compile, Stage
          and Merge. The output is stored in /bin.

        - Group Test
          All tasks to verify the integrity of the module with the tasks Pester
          and ScriptAnalyzer.

        - Group Deploy
          Tasks to deploy the module to the PowerShell Gallery and/or GitHub.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi
#>


# Suppress some rules for this build file
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()


## Configuration and Default task

# Load project configuration
. "$PSScriptRoot\build.settings.ps1"

# Default build configuration
Properties {

    # Option to disbale the build script verification
    $VerifyBuildSystem   = $true

    # Module configuration: Location and option to enable the merge
    $ModulePath          = Join-Path -Path $PSScriptRoot -ChildPath 'Modules'
    $ModuleNames         = ''
    $ModuleMerge         = $false

    # Source configuration: Visual Studio projects to compile
    $SourcePath          = Join-Path -Path $PSScriptRoot -ChildPath 'Sources'
    $SourceNames         = ''
    $SourcePublish       = ''

    # Path were the release files are stored
    $ReleasePath         = Join-Path -Path $PSScriptRoot -ChildPath 'bin'

    # Configure the Pester test execution
    $PesterPath          = Join-Path -Path $PSScriptRoot -ChildPath 'tst'
    $PesterFile          = 'pester.xml'

    # Configure the Script Analyzer rules
    $ScriptAnalyzerPath  = Join-Path -Path $PSScriptRoot -ChildPath 'tst'
    $ScriptAnalyzerFile  = 'scriptanalyzer.json'
    $ScriptAnalyzerRules = Get-ScriptAnalyzerRule

    # Define if the module is published to the PowerShell Gallery
    $GalleryEnabled      = $false
    $GalleryName         = 'PSGallery'
    $GallerySource       = 'https://www.powershellgallery.com/api/v2/'
    $GalleryPublish      = 'https://www.powershellgallery.com/api/v2/package/'
    $GalleryKey          = ''

    # Define if the module is published to the GitHub Releases section
    $GitHubEnabled       = $false
    $GitHubRepoName      = ''
    $GitHubToken         = ''
}

# Default task
Task Default -depends Build, Test


## Build tasks

# Overall build  task
Task Build -depends Verify, Init, Clean, Compile, Stage, Merge

# Verify the build system
Task Verify -requiredVariables VerifyBuildSystem {

    if ($VerifyBuildSystem)
    {
        $files = 'build.psake.ps1'

        foreach ($file in $files)
        {
            # Download reference file
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/claudiospizzi/PSModuleTemplate/master/Template/$file" -OutFile "$Env:Temp\$file"

            # Get content (don't compare hashes, because of new line chars)
            $expected = Get-Content -Path "$Env:Temp\$file"
            $actual   = Get-Content -Path "$PSScriptRoot\$file"

            # Compare objects
            Assert -conditionToCheck ($null -eq (Compare-Object -ReferenceObject $expected -DifferenceObject $actual)) -failureMessage "The file '$file' is not current. Please update the file and restart the build."
        }
    }
    else
    {
        Write-Warning 'Build system is not verified!'
    }
}

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
Task Clean -depends Init -requiredVariables ReleasePath, PesterPath, ScriptAnalyzerPath, SourcePath, SourceNames {

    Get-ChildItem -Path $ReleasePath | Remove-Item -Recurse -Force -Verbose:$VerbosePreference

    Get-ChildItem -Path $PesterPath | Remove-Item -Recurse -Force -Verbose:$VerbosePreference

    Get-ChildItem -Path $ScriptAnalyzerPath | Remove-Item -Recurse -Force -Verbose:$VerbosePreference

    if ($null -ne $SourceNames -and -not [string]::IsNullOrEmpty($SourceNames))
    {
        $msBuildPath = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin'

        if ($Env:Path -notlike "*$msBuildPath*")
        {
            $Env:Path = "$msBuildPath;$Env:Path"
        }

        foreach ($sourceName in $SourceNames)
        {
            $msBuildLog = (MSBuild.exe "$SourcePath\$sourceName\$sourceName.sln" /target:Clean /p:Configuration=Release)

            $msBuildLog | ForEach-Object { Write-Verbose $_ }
        }
    }
}

# Compile C# solutions
Task Compile -depends Clean -requiredVariables SourcePath, SourcePublish, SourceNames {

    if ($null -ne $SourceNames -and -not [string]::IsNullOrEmpty($SourceNames))
    {
        $msBuildPath = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin'

        if ($Env:Path -notlike "*$msBuildPath*")
        {
            $Env:Path = "$msBuildPath;$Env:Path"
        }

        foreach ($sourceName in $SourceNames)
        {
            $nuGetLog = (nuget.exe restore "Sources\$sourceName")

            $nuGetLog | ForEach-Object { Write-Verbose $_ }

            if ([String]::IsNullOrEmpty($SourcePublish))
            {
                $msBuildLog = (MSBuild.exe "$SourcePath\$sourceName\$sourceName.sln" /target:Build /p:Configuration=Release /verbosity:m)
            }
            else
            {
                $msBuildLog = (MSBuild.exe "$SourcePath\$sourceName\$sourceName.sln" /target:Build /p:Configuration=Release /p:DeployOnBuild=true /p:PublishProfile=$SourcePublish /verbosity:m)
            }

            $msBuildLog | ForEach-Object { Write-Verbose $_ }
        }
    }
}

# Copy all required module files to the release folder
Task Stage -depends Compile -requiredVariables ReleasePath, ModulePath, ModuleNames, ModuleMerge {

    if ($null -ne $ModuleNames -and -not [string]::IsNullOrEmpty($ModuleNames))
    {
        foreach ($moduleName in $ModuleNames)
        {
            New-Item -Path "$ReleasePath\$moduleName" -ItemType 'Directory' | Out-Null

            # If the module is merged, exclude the module definition file and
            # all classes, functions and helpers.
            $excludePath = @()
            if ($ModuleMerge)
            {
                $excludePath += "$moduleName.psd1", 'Classes', 'Functions', 'Helpers'
            }

            foreach ($item in (Get-ChildItem -Path "$ModulePath\$moduleName" -Exclude $excludePath))
            {
                Copy-Item -Path $item.FullName -Destination "$ReleasePath\$moduleName\$($item.Name)" -Recurse -Verbose:$VerbosePreference
            }
        }
    }
}

# Merge the module by copying all helper and cmdlet functions to the psm1 file
Task Merge -depends Stage -requiredVariables ReleasePath, ModulePath, ModuleNames, ModuleMerge {

    if ($null -ne $ModuleNames -and -not [string]::IsNullOrEmpty($ModuleNames))
    {
        foreach ($moduleName in $ModuleNames)
        {
            try
            {
                if ($ModuleMerge)
                {
                    $moduleContent    = New-Object -TypeName 'System.Collections.Generic.List[System.String]'
                    $moduleDefinition = New-Object -TypeName 'System.Collections.Generic.List[System.String]'

                    # Load code of the module namespace loader
                    if ((Get-Content -Path "$ModulePath\$moduleName\$moduleName.psm1" -Raw) -match '#region Namepsace Loader[\r\n](?<NamespaceLoader>[\S\s]*)[\r\n]#endregion Namepsace Loader')
                    {
                        $moduleContent.Add($matches['NamespaceLoader'])
                    }

                    # Load code for all class files
                    foreach ($file in (Get-ChildItem -Path "$ModulePath\$moduleName\Classes" -Filter '*.ps1' -Recurse -File -ErrorAction 'SilentlyContinue'))
                    {
                        $moduleContent.Add((Get-Content -Path $file.FullName -Raw))
                    }

                    # Load code for all function files
                    foreach ($file in (Get-ChildItem -Path "$ModulePath\$moduleName\Functions" -Filter '*.ps1' -Recurse -File -ErrorAction 'SilentlyContinue'))
                    {
                        $moduleContent.Add((Get-Content -Path $file.FullName -Raw))
                    }

                    # Load code for all helpers files
                    foreach ($file in (Get-ChildItem -Path "$ModulePath\$moduleName\Helpers" -Filter '*.ps1' -Recurse -File -ErrorAction 'SilentlyContinue'))
                    {
                        $moduleContent.Add((Get-Content -Path $file.FullName -Raw))
                    }

                    # Load code of the module namespace loader
                    if ((Get-Content -Path "$ModulePath\$moduleName\$moduleName.psm1" -Raw) -match '#region Module Configuration[\r\n](?<ModuleConfiguration>[\S\s]*)#endregion Module Configuration')
                    {
                        $moduleContent.Add($matches['ModuleConfiguration'])
                    }

                    # Concatenate whole code into the module file
                    $moduleContent | Set-Content -Path "$ReleasePath\$moduleName\$moduleName.psm1" -Encoding UTF8 -Verbose:$VerbosePreference

                    # Load the current content of the mudile definition
                    $moduleDefinitionProcess = $true
                    foreach ($moduleDefinitionLine in (Get-Content -Path "$ModulePath\$moduleName\$moduleName.psd1"))
                    {
                        if ($moduleDefinitionLine -like '*ScriptsToProcess*')
                        {
                            $moduleDefinition.Add('    # ScriptsToProcess = @()')
                            $moduleDefinitionProcess = $false
                        }

                        if ($moduleDefinitionProcess)
                        {
                            $moduleDefinition.Add($moduleDefinitionLine)
                        }

                        if ($moduleDefinitionLine -like '*)*')
                        {
                            $moduleDefinitionProcess = $true
                        }
                    }

                    # Save the updated module definition
                    $moduleDefinition | Set-Content -Path "$ReleasePath\$moduleName\$moduleName.psd1" -Encoding UTF8 -Verbose:$VerbosePreference
                }

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

        # Invoke script analyzer on the module but exclude all examples
        $analyzeResults = Invoke-ScriptAnalyzer -Path "$ReleasePath\$moduleName" -IncludeRule $ScriptAnalyzerRules -Recurse
        $analyzeResults = $analyzeResults | Where-Object { $_.ScriptPath -notlike "$releasePath\$moduleName\Examples\*" }
        $analyzeResults | ConvertTo-Json | Out-File -FilePath $moduleScriptAnalyzerFile -Encoding UTF8

        Show-ScriptAnalyzerResult -ModuleName $moduleName -Rule $ScriptAnalyzerRules -Result $analyzeResults

        Assert -conditionToCheck ($analyzeResults.Where({$_.Severity -ne 0}).Count -eq 0) -failureMessage "One or more Script Analyzer tests failed, build cannot continue."
    }
}


## Deploy tasks

# Overall deploy task
Task Deploy -depends Test, GitHub, Gallery

# Deploy a release to the GitHub repository
Task GitHub -requiredVariables ReleasePath, ModuleNames, GitHubEnabled, GitHubRepoName, GitHubToken {

    if (!$GitHubEnabled)
    {
        return
    }

    if ([String]::IsNullOrEmpty($GitHubToken))
    {
        throw 'GitHub key is null or empty!'
    }

    Test-GitRepo @($ModuleNames)[0]

    $plainGitHubToken = $GitHubToken | Unprotect-SecureString

    foreach ($moduleName in $ModuleNames)
    {
        $moduleVersion = (Import-PowerShellDataFile -Path "$ReleasePath\$moduleName\$moduleName.psd1").ModuleVersion
        $releaseNotes  = Get-ReleaseNote -Version $moduleVersion

        # Add TLS 1.2 for GitHub
        if (([Net.ServicePointManager]::SecurityProtocol -band [Net.SecurityProtocolType]::Tls12) -ne [Net.SecurityProtocolType]::Tls12)
        {
            [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
        }

        # Create GitHub release
        $releaseParams = @{
            Method  = 'Post'
            Uri     = "https://api.github.com/repos/$GitHubRepoName/releases"
            Headers = @{
                'Accept'        = 'application/vnd.github.v3+json'
                'Authorization' = "token $plainGitHubToken"
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
            Uri             = "https://uploads.github.com/repos/$GitHubRepoName/releases/$($release.id)/assets?name=$moduleName-$moduleVersion.zip"
            Headers         = @{
                'Accept'        = 'application/vnd.github.v3+json'
                'Authorization' = "token $plainGitHubToken"
                'Content-Type'  = 'application/zip'
            }
            InFile          = "$ReleasePath\$ModuleName.zip"
        }
        $artifact = Invoke-RestMethod @artifactParams -ErrorAction Stop
    }
}

# Deploy to the public PowerShell Gallery
Task Gallery -requiredVariables ReleasePath, ModuleNames, GalleryEnabled, GalleryName, GallerySource, GalleryPublish, GalleryKey {

    if (!$GalleryEnabled)
    {
        return
    }

    if ([String]::IsNullOrEmpty($GalleryKey))
    {
        throw 'PowerShell Gallery key is null or empty!'
    }

    Test-GitRepo @($ModuleNames)[0]

    # Register the target PowerShell Gallery, if it does not exist
    if ($null -eq (Get-PSRepository -Name $GalleryName -ErrorAction SilentlyContinue))
    {
        Register-PSRepository -Name $GalleryName -SourceLocation $GallerySource -PublishLocation $GalleryPublish
    }

    foreach ($moduleName in $ModuleNames)
    {
        $moduleVersion = (Import-PowerShellDataFile -Path "$ReleasePath\$moduleName\$moduleName.psd1").ModuleVersion
        $releaseNotes  = Get-ReleaseNote -Version $moduleVersion

        $plainGalleryKey = $GalleryKey | Unprotect-SecureString

        Publish-Module -Path "$ReleasePath\$moduleName" -Repository $GalleryName -NuGetApiKey $plainGalleryKey -ReleaseNotes $releaseNotes
    }
}


## Helper functions

# Check if the git repo is ready for a deployment
function Test-GitRepo($ModuleName)
{
    $gitStatus = Get-GitStatus
    if ($gitStatus.Branch -ne 'master')
    {
        throw "Git Exception: $($gitStatus.Branch) is checked out, switch to master branch!  (git checkout master)"
    }

    if ($gitStatus.AheadBy -ne 0)
    {
        throw "Git Exception: master branch is ahead by $($gitStatus.AheadBy)!  (git push)"
    }

    $version = (Import-PowerShellDataFile -Path "$ReleasePath\$ModuleName\$ModuleName.psd1").ModuleVersion

    $localTag = (git describe --tags)
    if ($version -ne $localTag)
    {
        throw "Git Exception: Tag $localTag not matches module version $version!  (git tag $version)"
    }

    $remoteTag = (git ls-remote origin "refs/tags/$version")
    if ($remoteTag -notlike "*refs/tags/$version")
    {
        throw "Git Exception: Local tag $localTag not found on origin remote!  (git push --tag)"
    }
}

# Check if a source branch is merged to the target branch
function Get-GitMergeStatus($Branch)
{
    $mergedBranches = (git.exe branch --merged "$Branch")

    foreach ($mergedBranch in $mergedBranches)
    {
        $mergedBranch = $mergedBranch.Trim('* ')

        Write-Output $mergedBranch
    }
}

# Show the Script Analyzer results on the host
function Show-ScriptAnalyzerResult($ModuleName, $Rule, $Result)
{
    $colorMap = @{
        ParseError  = 'DarkRed'
        Error       = 'Red'
        Warning     = 'Yellow'
        Information = 'Cyan'
    }

    Write-Host "`nModule $ModuleName" -ForegroundColor Green

    foreach ($currentRule in $Rule)
    {
        Write-Host "`n   Rule $($currentRule.RuleName)" -ForegroundColor Green

        $records = $Result.Where({$_.RuleName -eq $currentRule.RuleName})

        if ($records.Count -eq 0)
        {
            Write-Host "    [+] No rule violation found" -ForegroundColor DarkGreen
        }
        else
        {
            foreach ($record in $records)
            {
                Write-Host "    [-] $($record.Severity): $($record.Message)" -ForegroundColor $colorMap[[String]$record.Severity]
                Write-Host "      at $($record.ScriptPath): line $($record.Line)" -ForegroundColor $colorMap[[String]$record.Severity]
            }
        }
    }

    Write-Host "`nScript Analyzer completed"
    Write-Host "Rules: $($Rule.Count) Findings: $($analyzeResults.Count)"
}

# Extract the Release Notes from the CHANGELOG.md file
function Get-ReleaseNote($Version)
{
    $changelogFile = Join-Path -Path $PSScriptRoot -ChildPath 'CHANGELOG.md'

    $releaseNotes = @('Release Notes:')

    $isCurrentVersion = $false

    foreach ($line in (Get-Content -Path $changelogFile))
    {
        if ($line -like "## $Version - ????-??-??")
        {
            $isCurrentVersion = $true
        }
        elseif ($line -like '## *')
        {
            $isCurrentVersion = $false
        }

        if ($isCurrentVersion -and ($line.StartsWith('* ') -or $line.StartsWith('- ')))
        {
            $releaseNotes += $line
        }
    }

    Write-Output $releaseNotes
}
