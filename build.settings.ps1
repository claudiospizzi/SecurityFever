
Properties {

    $ModuleNames = 'SecurityFever'

    $SourceNames = 'SecurityFever'

    $GalleryEnabled = $true
    $GalleryKey     = Get-VaultSecureString -TargetName 'PS-SecureString-GalleryKey'

    $GitHubEnabled  = $true
    $GitHubRepoName = 'claudiospizzi/SecurityFever'
    $GitHubToken    = Get-VaultSecureString -TargetName 'PS-SecureString-GitHubToken'
}
