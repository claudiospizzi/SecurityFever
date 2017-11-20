# Changelog

All notable changes to this project will be documented in this file.

The format is mainly based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).


## 2.0.0 - 2017-10-18

* Added: Cmdlets to push and pop an impersonation context
* Changed: Rename TrustedHosts commands to singular noun


## 1.3.0 - 2017-09-24

* Added: WSMan TrustedHosts list manipulation commands


## 1.2.0 - 2017-07-20

* Added: Invoke-PowerShell function with (alias: posh)


## 1.1.0 - 2016-12-05

* Added: Cmdlets for the Windows Credential Manager Vault
* Changed: Add verbose output to Test-Credential


## 1.0.2 - 2016-11-29

* Fixed: Wrong output in quiet mode in Test-Credential
* Fixed: Failing Active Directory verification method in Test-Credential
* Fixed: Add unit tests in Test-Credential


## 1.0.1 - 2016-10-18

* Changed: Support positional parameter and pipeline input in Test-Credential
* Changed: Replace -Throw with -Quiet in Test-Credential
* Changed: Remove 'run as admin' requirement for remote calls in Get-SecurityActivity
* Changed: Add 'After' parameter to narrow down event span Get-SecurityActivity
* Fixed: Fix issues with for inaccessible working directory in Test-Credential
* Fixed: Suppression in script analyzer tests


## 1.0.0 - 2016-10-17

* Added: Get-SecurityActivity cmdlet to get security and life-cycle events
* Added: Get-SecurityAuditPolicy cmdlet to get current audit policy settings
* Added: Get-SecurityAuditPolicySetting cmdlet to get current audit policy settings
* Added: Invoke-Elevated cmdlet to execute elevated scripts (alias: sudo)
* Added: Test-Credential cmdlet for local and Active Directory verification
