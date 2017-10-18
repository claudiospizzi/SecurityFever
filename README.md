[![PowerShell Gallery - SecurityFever](https://img.shields.io/badge/PowerShell_Gallery-SecurityFever-0072C6.svg)](https://www.powershellgallery.com/packages/SecurityFever)
[![GitHub - Release](https://img.shields.io/github/release/claudiospizzi/SecurityFever.svg)](https://github.com/claudiospizzi/SecurityFever/releases)
[![AppVeyor - master](https://img.shields.io/appveyor/ci/claudiospizzi/SecurityFever/master.svg)](https://ci.appveyor.com/project/claudiospizzi/SecurityFever/branch/master)
[![AppVeyor - dev](https://img.shields.io/appveyor/ci/claudiospizzi/SecurityFever/master.svg)](https://ci.appveyor.com/project/claudiospizzi/SecurityFever/branch/dev)


# SecurityFever PowerShell Module

PowerShell Module with custom functions and cmdlets related to Windows and
application security.


## Introduction

This is a personal PowerShell Module by Claudio Spizzi. It is used to unite all
personal security related functions and cmdlets into one module.

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

* **Get-VaultEntryCredential**  
  This cmdlet works similar like the Get-VaultEntry, but returns only a native
  PSCredential object without additional metadata. This is useful if just the
  simple PSCredential object is required.

* **Get-VaultEntrySecureString**  
  This cmdlet works similar like the Get-VaultEntry, but returns only a native
  secure string object containing the password without additional metadata. This
  is useful if just the simple secure string object is required.

* **New-VaultEntry**  
  Create a new entry in the Windows Credential Manager vault. The credential
  type and persist location can be specified. By default, a generic entry with
  no special purpose is created on the local machine persist location. It will
  not override existing entries.

* **Update-VaultEntry**  
  Update an existing entry in the Windows Credential Manager vault. The
  credential target name and type are required to identify the entry to update.
  The persist location and the credentials (or username/password) can be
  updated.

* **Remove-VaultEntry**  
  Remove an existing entry in the Windows Credential Manager vault. The cmdlet
  accepts pipeline input with credential entry objects.

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

### Other

* **Invoke-Elevated**  
  Invoke a script block or an executable in an elevated session. It will handle
  the parameter passing into the elevated session and return the result as
  object to the caller. Because it's running in a different elevated process,
  XML serialization is used to return the result. The cmdlet has the alias
  **sudo**, as used on *nix systems.

* **Invoke-PowerShell**  
  Start a new PowerShell Console session with alternative credentials. The
  cmdlet has the alias **posh**.

* **Test-Credential**  
  With this cmdlet, credential objects or username and password pairs can be
  tested, if they are valid. With the method parameter, it's possible to choose
  how the credentials are validated (start process, Active Directory). Be aware,
  multiple testing with wrong credentials can lock out the used account
  depending on your security settings. 

* **Get-SecurityActivity**  
  Get security and life-cycle related events on the target computer like start
  up / shutdown, user log on / log off, workstation locked /unlocked, session
  reconnected / disconnected and screen saver invoke / dismiss.

* **Get-TrustedHost**  
  Get trusted host list entries.

* **Add-TrustedHost**  
  Add an entry to the trusted host list.

* **Remove-TrustedHost**  
  Remove an entry from the trusted host list.


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
* [Pester], [PSScriptAnalyzer] and [psake] PowerShell Modules

To release a new version in the PowerShell Gallery and the GitHub Releases
section by using the release pipeline on AppVeyor, use the following procedure:

1. Commit all changes in the dev branch
2. Push the commits to GitHub
3. Merge all commits to the master branch
4. Update the version number and release notes in the module manifest and CHANGELOG.md
5. Commit all changes in the master branch (comment: Version x.y.z)
6. Push the commits to GitHub
7. Tag the last commit with the version number
8. Push the tag to GitHub



[PowerShell Gallery]: https://www.powershellgallery.com/packages/SecurityFever
[GitHub Releases]: https://github.com/claudiospizzi/SecurityFever/releases
[Installing a PowerShell Module]: https://msdn.microsoft.com/en-us/library/dd878350

[CHANGELOG.md]: CHANGELOG.md

[Visual Studio Code]: https://code.visualstudio.com/
[PowerShell Extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell
[Pester]: https://www.powershellgallery.com/packages/Pester
[PSScriptAnalyzer]: https://www.powershellgallery.com/packages/PSScriptAnalyzer
[psake]: https://www.powershellgallery.com/packages/psake
