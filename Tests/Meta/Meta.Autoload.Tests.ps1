
Describe 'Meta Autoload' {

    $baseUri = 'https://raw.githubusercontent.com/claudiospizzi/PowerShellModuleBase/dev/Tests/Meta'

    $testFiles = Get-ChildItem -Path $PSScriptRoot -Exclude 'Meta.Autoload.Tests.ps1' | ForEach-Object Name

    foreach ($testFile in $testFiles)
    {
        Context "File $testFile" {

            It 'should download the latest version' {

                { Invoke-WebRequest -Uri "$baseUri/$testFile" -OutFile "$PSScriptRoot\$testFile" -ErrorAction Stop } | Should Not Throw
            }
        }
    }
}
