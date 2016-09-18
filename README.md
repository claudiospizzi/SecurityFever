[![AppVeyor - master](https://img.shields.io/appveyor/ci/claudiospizzi/SecurityFever/master.svg)](https://ci.appveyor.com/project/claudiospizzi/SecurityFever/branch/master)
[![AppVeyor - dev](https://img.shields.io/appveyor/ci/claudiospizzi/SecurityFever/dev.svg)](https://ci.appveyor.com/project/claudiospizzi/SecurityFever/branch/dev)
[![GitHub - Release](https://img.shields.io/github/release/claudiospizzi/SecurityFever.svg)](https://github.com/claudiospizzi/SecurityFever/releases)
[![PowerShell Gallery - SecurityFever](https://img.shields.io/badge/PowerShell_Gallery-SecurityFever-0072C6.svg)](https://www.powershellgallery.com/packages/SecurityFever)


# SecurityFever PowerShell Module

PowerShell Module with additional custom functions and cmdlets related to
Windows and application security.


## Introduction

tbd


## Versions

### unreleased

* ...


## Contribute

Please feel free to contribute by opening new issues or providing pull requests.
For the best development experience, open this project as a folder in Visual
Studio Code and ensure that the PowerShell extension is installed.

* [Visual Studio Code](https://code.visualstudio.com/)
* [PowerShell Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)

This module is tested with the PowerShell testing framework Pester. To run all
tests, just start the included test script `.\Scripts\test.ps1` or invoke Pester
directly with the `Invoke-Pester` cmdlet. The tests will automatically download
the latest meta test from the claudiospizzi/PowerShellModuleBase repository.
