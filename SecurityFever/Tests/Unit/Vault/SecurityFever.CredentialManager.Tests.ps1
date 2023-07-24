
$modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
$moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
Import-Module -Name "$modulePath\$moduleName" -Force

Describe 'SecurityFever.CredentialManager' {

    It 'Should create credential' {

        # Arrange
        $expectedNamespace   = 'LegacyGeneric'
        $expectedAttribute   = 'target'
        $expectedTargetAlias = ''
        $expectedTargetName  = 'Unit Test Demo'
        $expectedType        = [SecurityFever.CredentialManager.CredentialType]::Generic
        $expectedPersist     = [SecurityFever.CredentialManager.CredentialPersist]::LocalMachine
        $expectedUsername    = 'DEMO\\user'
        $expectedPassword    = 'MySecurePassword'
        $expectedCredential  = [System.Management.Automation.PSCredential]::new($expectedUsername, [SecurityFever.CredentialManager.CredentialHelper]::StringToSecureString($expectedPassword))

        # Act
        $actual = [SecurityFever.CredentialManager.CredentialStore]::CreateCredential($expectedTargetName, $expectedType, $expectedPersist, $expectedCredential)

        # Assert
        $actual.Namespace                                  | Should -Be $expectedNamespace
        $actual.Attribute                                  | Should -Be $expectedAttribute
        $actual.TargetAlias                                | Should -Be $expectedTargetAlias
        $actual.TargetName                                 | Should -Be $expectedTargetName
        $actual.Type                                       | Should -Be $expectedType
        $actual.Persist                                    | Should -Be $expectedPersist
        $actual.Credential.Username                        | Should -Be $expectedUsername
        $actual.Credential.GetNetworkCredential().Password | Should -Be $expectedPassword
    }

    It 'Should return true if credential exists' {

        # Arrange
        $targetName = 'Unit Test Demo'
        $type       = [SecurityFever.CredentialManager.CredentialType]::Generic

        # Act
        $actual = [SecurityFever.CredentialManager.CredentialStore]::ExistCredential($targetName, $type)

        # Assert
        $actual | Should -BeTrue
    }

    It 'Should return false if credential does not exists' {

        # Arrange
        $targetName = [System.Guid]::NewGuid().Guid
        $type       = [SecurityFever.CredentialManager.CredentialType]::MaximumEx

        # Act
        $actual = [SecurityFever.CredentialManager.CredentialStore]::ExistCredential($targetName, $type)

        # Assert
        $actual | Should -BeFalse
    }

    It 'Should get credential' {

        # Arrange
        $expectedNamespace   = 'LegacyGeneric'
        $expectedAttribute   = 'target'
        $expectedTargetAlias = ''
        $expectedTargetName  = 'Unit Test Demo'
        $expectedType        = [SecurityFever.CredentialManager.CredentialType]::Generic
        $expectedPersist     = [SecurityFever.CredentialManager.CredentialPersist]::LocalMachine
        $expectedUsername    = 'DEMO\\user'
        $expectedPassword    = 'MySecurePassword'

        # Act
        $actual = [SecurityFever.CredentialManager.CredentialStore]::GetCredential($expectedTargetName, $expectedType)

        # Assert
        $actual.Namespace                                  | Should -Be $expectedNamespace
        $actual.Attribute                                  | Should -Be $expectedAttribute
        $actual.TargetAlias                                | Should -Be $expectedTargetAlias
        $actual.TargetName                                 | Should -Be $expectedTargetName
        $actual.Type                                       | Should -Be $expectedType
        $actual.Persist                                    | Should -Be $expectedPersist
        $actual.Credential.Username                        | Should -Be $expectedUsername
        $actual.Credential.GetNetworkCredential().Password | Should -Be $expectedPassword
    }

    It 'Should get credentials' {

        # Act
        $actual = @([SecurityFever.CredentialManager.CredentialStore]::GetCredentials())

        # Assert
        $actual.Count | Should -BeGreaterThan 0
    }

    It 'Should remove credential' {

        # Arrange
        $targetName = 'Unit Test Demo'
        $type       = [SecurityFever.CredentialManager.CredentialType]::Generic

        # Act
        [SecurityFever.CredentialManager.CredentialStore]::RemoveCredential($targetName, $type)
        $actual = [SecurityFever.CredentialManager.CredentialStore]::ExistCredential($targetName, $type)

        # Assert
        $actual | Should -BeFalse
    }
}
