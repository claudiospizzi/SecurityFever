
Properties {

    $ModulePath  = Join-Path -Path $PSScriptRoot -ChildPath 'Modules'
    $ModuleNames = Get-ChildItem -Path $ModulePath | Select-Object -ExpandProperty 'BaseName' -First 1

    $SourceEnabled = Test-Path -Path "$PSScriptRoot\Sources"
    $SourcePath    = $(if ($SourceEnabled) { "$PSScriptRoot\Sources" } else { '' })
    $SourceNames   = $(if ($SourceEnabled) { Get-ChildItem -Path $SourcePath -Filter '*.sln' | Select-Object -ExpandProperty 'BaseName' -First 1 } else { '' })

    $ReleasePath = Join-Path -Path $PSScriptRoot -ChildPath 'bin'

    $PesterPath = Join-Path -Path $PSScriptRoot -ChildPath 'tst'
    $PesterFile = 'pester.xml'

    $ScriptAnalyzerPath  = Join-Path -Path $PSScriptRoot -ChildPath 'tst'
    $ScriptAnalyzerFile  = 'scriptanalyzer.json'
    $ScriptAnalyzerRules = Get-ScriptAnalyzerRule

    $GalleryEnabled = $true
    $GalleryName    = 'PSGallery'
    $GallerySource  = 'https://www.powershellgallery.com/api/v2/'
    $GalleryPublish = 'https://www.powershellgallery.com/api/v2/package/'
    $GalleryKey     = $Env:PSGalleryKey

    $GitHubEnabled  = $true
    $GitHubRepoName = Split-Path -Path $PSScriptRoot -Leaf
    $GitHubKey      = $Env:GitHubToken
}
