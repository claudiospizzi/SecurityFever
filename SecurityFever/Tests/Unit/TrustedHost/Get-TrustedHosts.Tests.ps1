
$modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
$moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
Import-Module -Name "$modulePath\$moduleName" -Force

Describe 'Get-TrustedHost' {

    Context 'Empty Value' {

        Mock 'Get-Item' -ModuleName $ModuleName {
            [PSCustomObject] @{ Value = $null }
        }

        It 'should return no entries' {

            # Arrange
            $expected = @()

            # Act
            $actual = @(Get-TrustedHost)

            # Assert
            $actual.Count | Should Be $expected.Count
        }
    }

    Context 'One Entry' {

        Mock 'Get-Item' -ModuleName $ModuleName {
            [PSCustomObject] @{ Value = '10.0.0.1' }
        }

        It 'should return one entry' {

            # Arrange
            $expected = @(
                '10.0.0.1'
            )

            # Act
            $actual = @(Get-TrustedHost)

            # Assert
            $actual.Count | Should Be $expected.Count
            $actual[0] | Should Be $expected[0]
        }
    }

    Context 'One Entry' {

        Mock 'Get-Item' -ModuleName $ModuleName {
            [PSCustomObject] @{ Value = '10.0.0.1,LON-DC01,*.contoso.com' }
        }

        It 'should return three entries' {

            # Arrange
            $expected = @(
                '10.0.0.1'
                'LON-DC01'
                '*.contoso.com'
            )

            # Act
            $actual = @(Get-TrustedHost)

            # Assert
            $actual.Count | Should Be $expected.Count
            $actual[0] | Should Be $expected[0]
            $actual[1] | Should Be $expected[1]
            $actual[2] | Should Be $expected[2]
        }
    }
}