
# Import build tasks
. InvokeBuildHelperTasks

# Build configuration
$IBHConfig.RepositoryTask.Token = Use-VaultSecureString -TargetName 'GitHub Token (claudiospizzi)'
$IBHConfig.GalleryTask.Token    = Use-VaultSecureString -TargetName 'PowerShell Gallery Key (claudiospizzi)'
