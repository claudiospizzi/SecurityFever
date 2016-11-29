
$ModulePath = Resolve-Path -Path "$PSScriptRoot\..\..\Modules" | ForEach-Object Path
$ModuleName = Get-ChildItem -Path $ModulePath | Select-Object -First 1 -ExpandProperty BaseName

Remove-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue
Import-Module -Name "$ModulePath\$ModuleName" -Force

Describe 'Test-Credential' {

    $expectedUsername = 'SecurityFever'
    $expectedPassword = ConvertTo-SecureString -String 'Pa$$w0rd' -AsPlainText -Force

    $expectedCredential = New-Object -TypeName PSCredential -ArgumentList $expectedUsername, $expectedPassword

    Context 'Method StartProcess' {

        BeforeAll {

            Write-Verbose "Create local test account $expectedUsername"

            New-LocalUser -Name $expectedUsername -Password $expectedPassword -Verbose
        }

        It 'should return true for valid credentials' {

            # Arrange
            $expectedResult = $true

            # Act
            $actualResult = Test-Credential -Credential $expectedCredential -Method StartProcess -Quiet

            # Assert
            $actualResult | Should Be $expectedResult
        }

        It 'should return true for valid username and password' {

            # Arrange
            $expectedResult = $true

            # Act
            $actualResult = Test-Credential -Username $expectedUsername -Password $expectedPassword -Method StartProcess -Quiet

            # Assert
            $actualResult | Should Be $expectedResult
        }

        It 'should return a credential object for valid credentials' {

            # Act
            $actualResult = Test-Credential -Credential $expectedCredential -Method StartProcess

            # Assert
            $actualResult | Should BeOfType 'System.Management.Automation.PSCredential'
            $actualResult.GetNetworkCredential().UserName | Should Be $expectedCredential.GetNetworkCredential().UserName
            $actualResult.GetNetworkCredential().Password | Should Be $expectedCredential.GetNetworkCredential().Password
        }

        It 'should return a credential object for valid username and password' {

            # Act
            $actualResult = Test-Credential -Username $expectedUsername -Password $expectedPassword -Method StartProcess

            # Assert
            $actualResult | Should BeOfType 'System.Management.Automation.PSCredential'
            $actualResult.GetNetworkCredential().UserName | Should Be $expectedCredential.GetNetworkCredential().UserName
            $actualResult.GetNetworkCredential().Password | Should Be $expectedCredential.GetNetworkCredential().Password
        }

        It 'should return false for invalid credentials' {

            # Arrange
            $invalidCredential = New-Object -TypeName PSCredential -ArgumentList 'DoesNotExist', (ConvertTo-SecureString -String 'TheWrongPassword' -AsPlainText -Force)
            $expectedResult    = $false

            # Act
            $actualResult = Test-Credential -Credential $invalidCredential -Method StartProcess -Quiet

            # Assert
            $actualResult | Should Be $expectedResult
        }

        It 'should return false for invalid username and password' {

            # Arrange
            $invalidUsername = 'DoesNotExist'
            $invalidPassword = ConvertTo-SecureString -String 'TheWrongPassword' -AsPlainText -Force
            $expectedResult  = $false

            # Act
            $actualResult = Test-Credential -Username $invalidUsername -Password $invalidPassword -Method StartProcess -Quiet

            # Assert
            $actualResult | Should Be $expectedResult
        }

        It 'should throw an exception for invalid credentials' {

            # Arrange
            $invalidCredential = New-Object -TypeName PSCredential -ArgumentList 'DoesNotExist', (ConvertTo-SecureString -String 'TheWrongPassword' -AsPlainText -Force)

            # Act
            { Test-Credential -Credential $invalidCredential -Method StartProcess } | Should Throw
        }

        It 'should throw an exception for invalid username and password' {

            # Arrange
            $invalidUsername = 'DoesNotExist'
            $invalidPassword = ConvertTo-SecureString -String 'TheWrongPassword' -AsPlainText -Force

            # Act
            { Test-Credential -Username $invalidUsername -Password $invalidPassword -Method StartProcess } | Should Throw
        }

        AfterAll {

            Write-Verbose 'Remove local test account'

            Remove-LocalUser -Name $expectedUsername -Verbose
        }
    }
}
