
Properties {

    $ModuleNames = 'SecurityFever'

    $SourceNames = 'SecurityFever'

    $GalleryEnabled = $true
    $GalleryKey     = Get-VaultSecureString -TargetName 'PS-SecureString-GalleryKey' | Unprotect-SecureString

    $GitHubEnabled  = $true
    $GitHubRepoName = 'claudiospizzi/SecurityFever'
    $GitHubKey      = Get-VaultSecureString -TargetName 'PS-SecureString-GitHubToken' | Unprotect-SecureString
}
