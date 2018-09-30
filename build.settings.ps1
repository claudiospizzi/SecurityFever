
Properties {

    $ModuleNames    = 'SecurityFever'

    $SourceNames    = 'SecurityFever'

    $GalleryEnabled = $true
    $GalleryKey     = Use-VaultSecureString -TargetName 'PowerShell Gallery Key (claudiospizzi)'

    $GitHubEnabled  = $true
    $GitHubRepoName = 'claudiospizzi/SecurityFever'
    $GitHubToken    = Use-VaultSecureString -TargetName 'GitHub Token (claudiospizzi)'
}
