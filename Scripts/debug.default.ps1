
# Get and dot source all helper functions (private)
Split-Path -Path $PSScriptRoot |
    Join-Path -ChildPath 'Modules\SecurityFever\Helpers' |
        Get-ChildItem -Include '*.ps1' -Exclude '*.Tests.*' -Recurse |
            ForEach-Object { . $_.FullName }

# Get and dot source all external functions (public)
Split-Path -Path $PSScriptRoot |
    Join-Path -ChildPath 'Modules\SecurityFever\Functions' |
        Get-ChildItem -Include '*.ps1' -Exclude '*.Tests.*' -Recurse |
            ForEach-Object { . $_.FullName }

# Update format data
Update-FormatData "$PSScriptRoot\..\Modules\SecurityFever\Resources\SecurityFever.Formats.ps1xml"

# Update type data
Update-TypeData "$PSScriptRoot\..\Modules\SecurityFever\Resources\SecurityFever.Types.ps1xml"

# Execute deubg
# ToDo...
