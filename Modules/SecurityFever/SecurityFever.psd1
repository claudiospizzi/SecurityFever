@{
    RootModule         = 'SecurityFever.psm1'
    ModuleVersion      = '1.0.2'
    GUID               = '6BAE79AD-CE6B-4969-933A-0C37EE3708FA'
    Author             = 'Claudio Spizzi'
    Copyright          = 'Copyright (c) 2016 by Claudio Spizzi. Licensed under MIT license.'
    Description        = 'PowerShell Module with additional custom functions and cmdlets related to Windows and application security.'
    PowerShellVersion  = '3.0'
    RequiredModules    = @()
    RequiredAssemblies = @(
        'SecurityFever.dll'
    )
    ScriptsToProcess   = @()
    TypesToProcess     = @(
        'Resources\SecurityFever.Types.ps1xml'
    )
    FormatsToProcess   = @(
        'Resources\SecurityFever.Formats.ps1xml'
    )
    FunctionsToExport  = @(
        'Invoke-Elevated'
        'Test-Credential'
        'Get-VaultEntry'
        'Get-VaultEntryCredential'
        'Get-VaultEntrySecureString'
        'New-VaultEntry'
        'Update-VaultEntry'
        'Remove-VaultEntry'
        'Get-SecurityActivity'
        'Get-SecurityAuditPolicy'
        'Get-SecurityAuditPolicySetting'
    )
    CmdletsToExport    = @()
    VariablesToExport  = @()
    AliasesToExport    = @(
        'sudo'
    )
    PrivateData        = @{
        PSData             = @{
            Tags               = @('PSModule', 'Security')
            LicenseUri         = 'https://raw.githubusercontent.com/claudiospizzi/SecurityFever/master/LICENSE'
            ProjectUri         = 'https://github.com/claudiospizzi/SecurityFever'
            ExternalModuleDependencies = @()
        }
    }
}
