
Properties {

    $ModulePath  = Join-Path -Path $PSScriptRoot -ChildPath 'Modules'
    $ModuleNames = Get-ChildItem -Path $ModulePath | Select-Object -ExpandProperty 'BaseName' -First 1

    $SourceEnabled = $true
    $SourcePath    = Join-Path -Path $PSScriptRoot -ChildPath 'Sources'
    $SourceNames   = Get-ChildItem -Path $SourcePath -Filter '*.sln' | Select-Object -ExpandProperty 'BaseName' -First 1

    $ReleasePath = Join-Path -Path $PSScriptRoot -ChildPath 'bin'

    $PesterPath = Join-Path -Path $PSScriptRoot -ChildPath 'tst'
    $PesterFile = 'pester.xml'

    $ScriptAnalyzerPath  = Join-Path -Path $PSScriptRoot -ChildPath 'tst'
    $ScriptAnalyzerFile  = 'scriptanalyzer.json'
    $ScriptAnalyzerRules = Get-ScriptAnalyzerRule | Where-Object { $_.RuleName -ne 'PSAvoidUsingConvertToSecureStringWithPlainText' }

    $GalleryEnabled = $true
    $GalleryName    = 'PSGallery'
    $GallerySource  = 'https://www.powershellgallery.com/api/v2/'
    $GalleryPublish = 'https://www.powershellgallery.com/api/v2/package/'
    $GalleryKey     = ''

    $GitHubEnabled  = $true
    $GitHubRepoName = Split-Path -Path $PSScriptRoot -Leaf
    $GitHubKey      = ''
}
