
$modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
$moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
Import-Module -Name "$modulePath\$moduleName" -Force

Describe 'Add-TrustedHost' {

    Context 'Not Administrator' {

        Mock 'Test-AdministratorRole' -ModuleName $moduleName {
            throw 'Access denied. Please start this functions as an administrator.'
        }

        It 'should throw an exception' {

            # Arrange, Act, Assert
            { Add-TrustedHost -ComputerName $Env:COMPUTERNAME } | Should Throw
        }
    }

    Context 'Is Administrator' {

        Mock 'Test-AdministratorRole' -ModuleName $moduleName {
            # Return nothing, so the function will continue
        }

        Mock 'Get-Item' -ModuleName $ModuleName {
            [PSCustomObject] @{ Value = '10.0.0.1' }
        }

        Mock 'Set-Item' -ModuleName $ModuleName -Verifiable -ParameterFilter {
            $Path -eq 'WSMan:\localhost\Client\TrustedHosts' -and $Value -eq '10.0.0.1,SERVER,*.contoso.com'
        } { }

        It 'should add two entries via parameter' {

            # Arrange
            $list = 'SERVER', '*.contoso.com'

            # Act
            Add-TrustedHost -ComputerName $list

            # Assert
            Assert-MockCalled 'Set-Item' -ModuleName $moduleName -Times 1 -Exactly
        }

        It 'should add two entries via pipeline' {

            # Arrange
            $list = 'SERVER', '*.contoso.com'

            # Act
            $list | Add-TrustedHost

            # Assert
            Assert-MockCalled 'Set-Item' -ModuleName $moduleName -Times 2 -Exactly
        }
    }
}