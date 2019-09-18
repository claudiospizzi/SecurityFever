[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Select-Object -ExpandProperty Path
$moduleName = Resolve-Path -Path "$PSScriptRoot\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
Import-Module -Name "$modulePath\$moduleName" -Force

Describe 'Test-Credential' {

    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(([Security.Principal.WindowsBuiltInRole]::Administrator))

    $expectedUsername = 'SecurityFever'
    $expectedPassword = ConvertTo-SecureString -String 'Pa$$w0rd' -AsPlainText -Force

    $expectedCredential = New-Object -TypeName PSCredential -ArgumentList $expectedUsername, $expectedPassword

    Context "Method StartProcess" {

        BeforeAll {

            if ($isAdmin)
            {
                Write-Verbose "Create local test account: $expectedUsername"

                New-LocalUser -Name $expectedUsername -Password $expectedPassword
            }
        }

        It 'should return true for valid credentials' {

            # Skip test if user is not admin
            if (-not $isAdmin)
            {
                Set-TestInconclusive
                return
            }

            # Arrange
            $expectedResult = $true

            # Act
            $actualResult = Test-Credential -Credential $expectedCredential -Method 'StartProcess' -Quiet

            # Assert
            $actualResult | Should Be $expectedResult
        }

        It 'should return true for valid username and password' {

            # Skip test if user is not admin
            if (-not $isAdmin)
            {
                Set-TestInconclusive
                return
            }

            # Arrange
            $expectedResult = $true

            # Act
            $actualResult = Test-Credential -Username $expectedUsername -Password $expectedPassword -Method 'StartProcess' -Quiet

            # Assert
            $actualResult | Should Be $expectedResult
        }

        It 'should return a credential object for valid credentials' {

            # Skip test if user is not admin
            if (-not $isAdmin)
            {
                Set-TestInconclusive
                return
            }

            # Act
            $actualResult = Test-Credential -Credential $expectedCredential -Method 'StartProcess'

            # Assert
            $actualResult | Should BeOfType 'System.Management.Automation.PSCredential'
            $actualResult.GetNetworkCredential().UserName | Should Be $expectedCredential.GetNetworkCredential().UserName
            $actualResult.GetNetworkCredential().Password | Should Be $expectedCredential.GetNetworkCredential().Password
        }

        It 'should return a credential object for valid username and password' {

            # Skip test if user is not admin
            if (-not $isAdmin)
            {
                Set-TestInconclusive
                return
            }

            # Act
            $actualResult = Test-Credential -Username $expectedUsername -Password $expectedPassword -Method 'StartProcess'

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
            $actualResult = Test-Credential -Credential $invalidCredential -Method 'StartProcess' -Quiet

            # Assert
            $actualResult | Should Be $expectedResult
        }

        It 'should return false for invalid username and password' {

            # Arrange
            $invalidUsername = 'DoesNotExist'
            $invalidPassword = ConvertTo-SecureString -String 'TheWrongPassword' -AsPlainText -Force
            $expectedResult  = $false

            # Act
            $actualResult = Test-Credential -Username $invalidUsername -Password $invalidPassword -Method 'StartProcess' -Quiet

            # Assert
            $actualResult | Should Be $expectedResult
        }

        It 'should throw an exception for invalid credentials' {

            # Arrange
            $invalidCredential = New-Object -TypeName PSCredential -ArgumentList 'DoesNotExist', (ConvertTo-SecureString -String 'TheWrongPassword' -AsPlainText -Force)

            # Act
            { Test-Credential -Credential $invalidCredential -Method 'StartProcess' } | Should Throw
        }

        It 'should throw an exception for invalid username and password' {

            # Arrange
            $invalidUsername = 'DoesNotExist'
            $invalidPassword = ConvertTo-SecureString -String 'TheWrongPassword' -AsPlainText -Force

            # Act
            { Test-Credential -Username $invalidUsername -Password $invalidPassword -Method 'StartProcess' } | Should Throw
        }

        AfterAll {

            if ($isAdmin)
            {
                Write-Verbose "Remove local test account: $expectedUsername"

                Remove-LocalUser -Name $expectedUsername
            }
        }
    }

    Context "Method ActiveDirectory" {

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
            $actualResult = Test-Credential -Credential $expectedCredential -Method 'ActiveDirectory' -Quiet

            # Assert
            $actualResult | Should Be $expectedResult
        }

        It 'should return true for valid username and password' {

            # Arrange
            $expectedResult = $true

            # Act
            $actualResult = Test-Credential -Username $expectedUsername -Password $expectedPassword -Method 'ActiveDirectory' -Quiet

            # Assert
            $actualResult | Should Be $expectedResult
        }

        It 'should return a credential object for valid credentials' {

            # Act
            $actualResult = Test-Credential -Credential $expectedCredential -Method 'ActiveDirectory'

            # Assert
            $actualResult | Should BeOfType 'System.Management.Automation.PSCredential'
            $actualResult.GetNetworkCredential().UserName | Should Be $expectedCredential.GetNetworkCredential().UserName
            $actualResult.GetNetworkCredential().Password | Should Be $expectedCredential.GetNetworkCredential().Password
        }

        It 'should return a credential object for valid username and password' {

            # Act
            $actualResult = Test-Credential -Username $expectedUsername -Password $expectedPassword -Method 'ActiveDirectory'

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
            $actualResult = Test-Credential -Credential $invalidCredential -Method 'ActiveDirectory' -Quiet

            # Assert
            $actualResult | Should Be $expectedResult
        }

        It 'should return false for invalid username and password' {

            # Arrange
            $invalidUsername = 'DoesNotExist'
            $invalidPassword = ConvertTo-SecureString -String 'TheWrongPassword' -AsPlainText -Force
            $expectedResult  = $false

            # Act
            $actualResult = Test-Credential -Username $invalidUsername -Password $invalidPassword -Method 'ActiveDirectory' -Quiet

            # Assert
            $actualResult | Should Be $expectedResult
        }

        It 'should throw an exception for invalid credentials' {

            # Arrange
            $invalidCredential = New-Object -TypeName PSCredential -ArgumentList 'DoesNotExist', (ConvertTo-SecureString -String 'TheWrongPassword' -AsPlainText -Force)

            # Act
            { Test-Credential -Credential $invalidCredential -Method 'ActiveDirectory' } | Should Throw
        }

        It 'should throw an exception for invalid username and password' {

            # Arrange
            $invalidUsername = 'DoesNotExist'
            $invalidPassword = ConvertTo-SecureString -String 'TheWrongPassword' -AsPlainText -Force

            # Act
            { Test-Credential -Username $invalidUsername -Password $invalidPassword -Method 'ActiveDirectory' } | Should Throw
        }
    }
}
