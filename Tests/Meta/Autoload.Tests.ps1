
# Audoload latest meta test files from the master branch of the 
# claudiospizzi/PowerShellModuleBase repository. It will only update the
# existing placeholder files and not download new meta test files.

Describe 'Meta Autoload' {

    $baseUri = 'https://raw.githubusercontent.com/claudiospizzi/PowerShellModuleBase/master/Tests/Meta'

    $testFiles = Get-ChildItem -Path $PSScriptRoot -Exclude 'Autoload.Tests.ps1' | ForEach-Object Name

    foreach ($testFile in $testFiles)
    {
        Context "File $testFile" {

            It 'should download the latest version' {

                { Invoke-WebRequest -Uri "$baseUri/$testFile" -OutFile "$PSScriptRoot\$testFile" -ErrorAction Stop } | Should Not Throw
            }
        }
    }
}
