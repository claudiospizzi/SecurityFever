@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'SecurityFever.psm1'

    # Version number of this module.
    ModuleVersion = '3.0.0'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID = '6BAE79AD-CE6B-4969-933A-0C37EE3708FA'

    # Author of this module
    Author = 'Claudio Spizzi'

    # Company or vendor of this module
    # CompanyName = ''

    # Copyright statement for this module
    Copyright = 'Copyright (c) 2019 by Claudio Spizzi. Licensed under MIT license.'

    # Description of the functionality provided by this module
    Description = 'PowerShell Module with custom functions and cmdlets related to Windows and application security.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '3.0'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @(
        'Assemblies\SecurityFever.dll'
        'Assemblies\QRCoder.dll'
    )

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @(
        'SecurityFever.Xml.Types.ps1xml'
    )

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @(
        'SecurityFever.Xml.Format.ps1xml'
    )

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        # Audit Policy
        'Get-SecurityAuditPolicy'
        'Get-SecurityAuditPolicySetting'
        # Certificate
        'Convert-Certificate'
        'New-DomainSignedCertificate'
        'Add-CertificatePrivateKeyPermission'
        'Get-CertificatePrivateKeyPermission'
        # Common
        'Get-TimeBasedOneTimePassword'
        'New-TimeBasedOneTimeSharedSecret'
        'Invoke-Elevated'
        'Start-Monitor'
        # Credential
        'New-Password'
        'Test-Credential'
        # Impersonation
        'Get-ImpersonationContext'
        'Pop-ImpersonationContext'
        'Push-ImpersonationContext'
        # SecureString
        'Protect-String'
        'Unprotect-SecureString'
        # System Audit
        'Get-SystemAudit'
        'Get-SystemAuditFileSystem'
        'Get-SystemAuditGroupPolicy'
        'Get-SystemAuditMsiInstaller'
        'Get-SystemAuditPowerCycle'
        'Get-SystemAuditUserSession'
        'Get-SystemAuditWindowsService'
        # TrustedHost
        'Add-TrustedHost'
        'Get-TrustedHost'
        'Remove-TrustedHost'
        # Vault
        'Get-VaultCredential'
        'Get-VaultEntry'
        'Get-VaultSecureString'
        'New-VaultEntry'
        'Remove-VaultEntry'
        'Update-VaultEntry'
        'Use-VaultCredential'
        'Use-VaultSecureString'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    # CmdletsToExport = @()

    # Variables to export from this module
    # VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @(
        'sudo'
        'cred'
        'Get-TOTP'
        'New-TOTPSharedSecret'
    )

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('PSModule', 'Security', 'CredentialManager', 'Impersonation', 'TOTP')

            # A URL to the license for this module.
            LicenseUri = 'https://raw.githubusercontent.com/claudiospizzi/SecurityFever/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/claudiospizzi/SecurityFever'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
