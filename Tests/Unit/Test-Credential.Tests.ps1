
$ModulePath = Resolve-Path -Path "$PSScriptRoot\..\..\Modules" | ForEach-Object Path
$ModuleName = Get-ChildItem -Path $ModulePath | Select-Object -First 1 -ExpandProperty BaseName

Remove-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue
Import-Module -Name "$ModulePath\$ModuleName" -Force

Describe 'Test-Credential' {

    $expectedUsername = 'SecurityFever'
    $expectedPassword = ConvertTo-SecureString -String 'Pa$$w0rd' -AsPlainText -Force

    $expectedCredential = New-Object -TypeName PSCredential -ArgumentList $expectedUsername, $expectedPassword

    foreach ($method in 'StartProcess', 'ActiveDirectory')
    {
        Context "Method $method" {

            BeforeAll {

                Write-Verbose "Create local test account $expectedUsername"

                New-LocalUser -Name $expectedUsername -Password $expectedPassword
            }

            Mock 'New-Object' -ModuleName $ModuleName -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectoryEntry' -and $ArgumentList[1] -eq $expectedUsername } {
                return @{ distinguishedName = 'DC=contoso,DC=com' }
            }

            Mock 'New-Object' -ModuleName $ModuleName -ParameterFilter { $TypeName -eq 'System.DirectoryServices.DirectoryEntry' -and $ArgumentList[1] -ne $expectedUsername } {
                throw 'Logon failure: unknown user name or bad password'
            }

            It 'should return true for valid credentials' {

                # Arrange
                $expectedResult = $true

                # Act
                $actualResult = Test-Credential -Credential $expectedCredential -Method $method -Quiet

                # Assert
                $actualResult | Should Be $expectedResult
            }

            It 'should return true for valid username and password' {

                # Arrange
                $expectedResult = $true

                # Act
                $actualResult = Test-Credential -Username $expectedUsername -Password $expectedPassword -Method $method -Quiet

                # Assert
                $actualResult | Should Be $expectedResult
            }

            It 'should return a credential object for valid credentials' {

                # Act
                $actualResult = Test-Credential -Credential $expectedCredential -Method $method

                # Assert
                $actualResult | Should BeOfType 'System.Management.Automation.PSCredential'
                $actualResult.GetNetworkCredential().UserName | Should Be $expectedCredential.GetNetworkCredential().UserName
                $actualResult.GetNetworkCredential().Password | Should Be $expectedCredential.GetNetworkCredential().Password
            }

            It 'should return a credential object for valid username and password' {

                # Act
                $actualResult = Test-Credential -Username $expectedUsername -Password $expectedPassword -Method $method

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
                $actualResult = Test-Credential -Credential $invalidCredential -Method $method -Quiet

                # Assert
                $actualResult | Should Be $expectedResult
            }

            It 'should return false for invalid username and password' {

                # Arrange
                $invalidUsername = 'DoesNotExist'
                $invalidPassword = ConvertTo-SecureString -String 'TheWrongPassword' -AsPlainText -Force
                $expectedResult  = $false

                # Act
                $actualResult = Test-Credential -Username $invalidUsername -Password $invalidPassword -Method $method -Quiet

                # Assert
                $actualResult | Should Be $expectedResult
            }

            It 'should throw an exception for invalid credentials' {

                # Arrange
                $invalidCredential = New-Object -TypeName PSCredential -ArgumentList 'DoesNotExist', (ConvertTo-SecureString -String 'TheWrongPassword' -AsPlainText -Force)

                # Act
                { Test-Credential -Credential $invalidCredential -Method $method } | Should Throw
            }

            It 'should throw an exception for invalid username and password' {

                # Arrange
                $invalidUsername = 'DoesNotExist'
                $invalidPassword = ConvertTo-SecureString -String 'TheWrongPassword' -AsPlainText -Force

                # Act
                { Test-Credential -Username $invalidUsername -Password $invalidPassword -Method $method } | Should Throw
            }

            AfterAll {

                Write-Verbose 'Remove local test account'

                Remove-LocalUser -Name $expectedUsername
            }
        }
    }
}
