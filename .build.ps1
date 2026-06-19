
# Import build tasks
. InvokeBuildHelperTasks

# Build configuration
$IBHConfig.GalleryTask.TokenCallback    = { Get-BuildSecret -EnvironmentVariable 'PS_GALLERY_KEY' -CredentialManager 'PowerShell Gallery Key (claudiospizzi)' }
$IBHConfig.RepositoryTask.TokenCallback = { Get-BuildSecret -EnvironmentVariable 'GITHUB_TOKEN' -CredentialManager 'GitHub Token (claudiospizzi)' }
