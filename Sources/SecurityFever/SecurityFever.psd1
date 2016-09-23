@{
    RootModule         = 'SecurityFever.psm1'
    ModuleVersion      = '0.0.0'
    GUID               = '6BAE79AD-CE6B-4969-933A-0C37EE3708FA'
    Author             = 'Claudio Spizzi'
    Copyright          = 'Copyright (c) 2016 by Claudio Spizzi. Licensed under MIT license.'
    Description        = 'PowerShell Module with additional custom functions and cmdlets related to Windows and application security.'
    PowerShellVersion  = '3.0'
    RequiredModules    = @()
    ScriptsToProcess   = @()
    TypesToProcess     = @(
        'Resources\SecurityFever.Types.ps1xml'
    )
    FormatsToProcess   = @(
        'Resources\SecurityFever.Formats.ps1xml'
    )
    FunctionsToExport  = @(
        'Get-SecurityActivity'
        'Get-SecurityAuditPolicy'
        'Get-SecurityAuditPolicySetting'
        'Invoke-Elevated'
        'Test-Credential'
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
