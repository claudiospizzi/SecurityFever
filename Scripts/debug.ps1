
# Get and dot source all helper functions (private)
Split-Path -Path $PSScriptRoot |
    Join-Path -ChildPath 'Sources\SecurityFever\Helpers' |
        Get-ChildItem -Include '*.ps1' -Exclude '*.Tests.*' -Recurse |
            ForEach-Object { . $_.FullName }

# Get and dot source all external functions (public)
Split-Path -Path $PSScriptRoot |
    Join-Path -ChildPath 'Sources\SecurityFever\Functions' |
        Get-ChildItem -Include '*.ps1' -Exclude '*.Tests.*' -Recurse |
            ForEach-Object { . $_.FullName }

# Execute deubg
Get-SecurityAuditPolicy
