[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/SecurityFever?label=PowerShell%20Gallery&logo=PowerShell)](https://www.powershellgallery.com/packages/SecurityFever)
[![Gallery Downloads](https://img.shields.io/powershellgallery/dt/SecurityFever?label=Downloads&logo=PowerShell)](https://www.powershellgallery.com/packages/SecurityFever)
[![GitHub Release](https://img.shields.io/github/v/release/claudiospizzi/SecurityFever?label=Release&logo=GitHub&sort=semver)](https://github.com/claudiospizzi/SecurityFever/releases)
[![GitHub CI Build](https://img.shields.io/github/actions/workflow/status/claudiospizzi/SecurityFever/ci.yml?label=CI%20Build&logo=GitHub)](https://github.com/claudiospizzi/SecurityFever/actions/workflows/ci.yml)

# SecurityFever PowerShell Module

PowerShell Module with custom functions and cmdlets related to Windows and
application security.

## Introduction

This is a PowerShell Module with functions and cmdlets related to Windows and
application security. It unites multiple handy tools into one module.

You can invoke PowerShell scripts or script blocks in an elevated context with
**sudo** or test your credentials against the local system or an Active
Directory domain with **Test-Credential**.

With the security activity and audit policy cmdlets, you can get the security
related configuration of security audit events in the **Audit Policy** and check
the latest activity on the target computer.

With the **Vault** cmdlets, you can interact with the Windows Credential Manager
to store and received PowerShell credentials and secure strings.

The **Impersonation** cmdlets allow you to impersonate another user in the
current session. With this, you can execute certain commands as another user
account.

## Features

### Windows Credential Manager (Vault)

* **Get-VaultEntry**  
  With this cmdlet, the entires form the Windows Credential Manager vault can be
  retrieved. The entries contain a PSCredential object and all additional
  metadata like target name, type and persistence location.

* **Get-VaultCredential**  
  This cmdlet works similar like the Get-VaultEntry, but returns only a native
  PSCredential object without additional metadata. This is useful if just the
  simple PSCredential object is required.

* **Get-VaultSecureString**  
  This cmdlet works similar like the Get-VaultEntry, but returns only a native
  secure string object containing the password without additional metadata. This
  is useful if just the simple secure string object is required.

* **New-VaultEntry**  
  Create a new entry in the Windows Credential Manager vault.
  The credential type and persist location can be specified. By default, a
  generic entry with no special purpose is created on the local machine persist
  location. It will not override existing entries.

* **Update-VaultEntry**  
  Update an existing entry in the Windows Credential Manager vault. The
  credential target name and type are required to identify the entry to update.
  The persist location and the credentials (or username/password) can be
  updated.

* **Remove-VaultEntry**  
  Remove an existing entry in the Windows Credential Manager vault. The cmdlet
  accepts pipeline input with credential entry objects.

* **Use-VaultCredential**  
  Get the PSCredential object from the Windows Credential Manager vault or query
  the caller to enter the credentials. These credentials will be stored in the
  vault.

* **Use-VaultCredential**  
  The cmdlet works similar like the Use-VaultCredential, but returns only a
  native secure string object containing the password without additional
  metadata. This is useful if just the simple secure string object is required.

### Certificate

* **Convert-Certificate**  
  Command to convert certificate files between various formats. This is useful
  to replace openssl and have a PowerShell nativ method.

* **New-DomainSignedCertificate**  
  Command to create a new certificate signed by the domain CA. It's able to
  create subject, dns name, ip addresses and a friendly name for the
  certificate. The output can be Windows (DER) or Linux (PEM) compatible.

* **Get-CertificatePrivateKeyPermission**  
  Return all permissions entries of a certificate private key.

* **Add-CertificatePrivateKeyPermission**  
  Add a permission entry on the certificate private key.

### Credential

* **New-Password**  
  Generate a new random and secure password.

* **Test-Credential**  
  With this cmdlet, credential objects or username and password pairs can be
  tested, if they are valid. With the method parameter, it's possible to choose
  how the credentials are validated (start process, Active Directory). Be aware,
  multiple testing with wrong credentials can lock out the used account
  depending on your security settings.

### Secure String

* **Protect-String**  
  Convert a string into a secure string.

* **Unprotect-SecureString**  
  Convert a secure string into a string.

### System Audit

* **Get-SystemAudit**  
  Get all audit changes on the target system. This will combine the result of
  the commands below.

* **Get-SystemAuditFileSystem**  
  Get file system related audit changes on the target system.

* **Get-SystemAuditGroupPolicy**  
  Get group policy related audit changes on the target system.

* **Get-SystemAuditMsiInstaller**  
  Get MSI installer related audit changes on the target system.

* **Get-SystemAuditPowerCycle**  
  Get power cycle related audit changes on the target system.

* **Get-SystemAuditUserSession**  
  Get user session related audit changes on the target system.

* **Get-SystemAuditWindowsService**  
  Get Windows service related audit changes on the target system.

### Audit Policy

* **Get-SecurityAuditPolicy**  
  List the current local security audit policy settings. It will execute the
  auditpol.exe command and parse the result into objects.

* **Get-SecurityAuditPolicySetting**  
  Return the value of one security audit policy setting. It will use the
  Get-SecurityAuditPolicy cmdlet and just filter and expand the result.

### Impersonation

* **Get-ImpersonationContext**  
  Get the current impersonation context and the active windows identity.

* **Push-ImpersonationContext**  
  Create a new impersonation context by using the specified credentials. All
  following commands will be executed as the specified user until the context
  is closed.

* **Pop-ImpersonationContext**  
  Leave the current impersonation context.

### Trusted Hosts List

* **Get-TrustedHost**  
  Get trusted host list entries.

* **Add-TrustedHost**  
  Add an entry to the trusted host list.

* **Remove-TrustedHost**  
  Remove an entry from the trusted host list.

### Other / Common

* **Get-TimeBasedOneTimePassword**  
  Generate a Time-Base One-Time Password based on RFC 6238. The aliases Get-TOTP
  or totp can also be used.

* **New-TimeBasedOneTimeSharedSecret**  
  Generate a shared secret for the Time-Base One-Time algorithm RFC 6238.

* **Invoke-Elevated**  
  Invoke a script block or an executable in an elevated session. It will handle
  the parameter passing into the elevated session and return the result as
  object to the caller. Because it's running in a different elevated process,
  XML serialization is used to return the result. The cmdlet has the alias
  **sudo**, as used on *nix systems.

* **Start-Monitor**  
   Start a PowerShell monitoring based on a script block. The script block will
   evaluate on a schedule like every second and throw an alert if the condition
   is not met. It can play a beep sound.

## Versions

Please find all versions in the [GitHub Releases] section and the release notes
in the [CHANGELOG.md] file.

## Installation

Use the following command to install the module from the [PowerShell Gallery],
if the PackageManagement and PowerShellGet modules are available:

```powershell
# Download and install the module
Install-Module -Name 'SecurityFever'
```

Alternatively, download the latest release from GitHub and install the module
manually on your local system:

1. Download the latest release from GitHub as a ZIP file: [GitHub Releases]
2. Extract the module and install it: [Installing a PowerShell Module]

## Requirements

The following minimum requirements are necessary to use this module, or in other
words are used to test this module:

* Windows PowerShell 3.0
* Windows Server 2008 R2 / Windows 7

## Contribute

Please feel free to contribute by opening new issues or providing pull requests.
For the best development experience, open this project as a folder in Visual
Studio Code and ensure that the PowerShell extension is installed.

* [Visual Studio Code] with the [PowerShell Extension]
* [Pester], [PSScriptAnalyzer], [InvokeBuild] and [InvokeBuildHelper] modules

[PowerShell Gallery]: https://www.powershellgallery.com/packages/InvokeBuildHelper
[GitHub Releases]: https://github.com/claudiospizzi/PSInvokeBuildHelper/releases
[Installing a PowerShell Module]: https://msdn.microsoft.com/en-us/library/dd878350

[CHANGELOG.md]: CHANGELOG.md

[Visual Studio Code]: https://code.visualstudio.com/
[PowerShell Extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell
[Pester]: https://www.powershellgallery.com/packages/Pester
[PSScriptAnalyzer]: https://www.powershellgallery.com/packages/PSScriptAnalyzer
[InvokeBuild]: https://www.powershellgallery.com/packages/InvokeBuild
[InvokeBuildHelper]: https://www.powershellgallery.com/packages/InvokeBuildHelper
