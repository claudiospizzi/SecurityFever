
Properties {

    $ModulePath  = Join-Path -Path $PSScriptRoot -ChildPath 'Modules'
    $ModuleNames = Get-ChildItem -Path $ModulePath | Select-Object -ExpandProperty 'BaseName' -First 1

    $SourcePath  = Join-Path -Path $PSScriptRoot -ChildPath 'Sources'
    $SourceNames = Get-ChildItem -Path $SourcePath -Filter '*.sln' | Select-Object -ExpandProperty 'BaseName' -First 1

    $ReleasePath = Join-Path -Path $PSScriptRoot -ChildPath 'bin'

    $TestPath = Join-Path -Path $PSScriptRoot -ChildPath 'tst'
    $TestFile = 'pester.xml'

    $MSBuildPath = 'C:\Windows\Microsoft.NET\Framework\v4.0.30319'

    $AnalyzePath  = Join-Path -Path $PSScriptRoot -ChildPath 'tst'
    $AnalyzeFile  = 'scriptanalyzer.json'
    $AnalyzeRules = Get-ScriptAnalyzerRule

    $GalleryEnabled = $true
    $GalleryName    = 'PSGallery'
    $GallerySource  = 'https://www.powershellgallery.com/api/v2/'
    $GalleryPublish = 'https://www.powershellgallery.com/api/v2/package/'
    $GalleryKey     = ''

    $GitHubEnabled  = $true
    $GitHubRepoName = Split-Path -Path $PSScriptRoot -Leaf
    $GitHubKey      = ''
}
