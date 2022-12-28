
$modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
$moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
Import-Module -Name "$modulePath\$moduleName" -Force

Describe 'Convert-Certificate' {

    $testInPath  = Resolve-Path -Path "$PSScriptRoot\TestData" | Select-Object -ExpandProperty 'Path'
    # $testOutPath = Resolve-Path -Path 'TestDrive:' | Select-Object -ExpandProperty 'ProviderPath'
    $testOutPath = 'C:\Temp'

    BeforeEach {
        Write-Host '> BeforeEach'
    }

    It 'Should convert X.509/PEM to X.509/PEM' {

        # Act
        Convert-Certificate -InPath "$testInPath\ca.pem" -OutPath "$testOutPath\ca.pem" -OutType 'X.509/PEM'

        # Assert
        $expectedContent = [System.IO.File]::ReadAllBytes("$testInPath\ca.pem")
        $actualContent   = [System.IO.File]::ReadAllBytes("$testOutPath\ca.pem")

        $actualContent | Should -Be $expectedContent
    }

    # $inTestData = @{
    #     'X.509/DER' = @{
    #         InPath = "$PSScriptRoot\TestData\ca.cer"
    #     }
    #     'X.509/PEM' = @{
    #         InPath = "$PSScriptRoot\TestData\ca.pem"
    #     }
    # }

    # $outTestData = @{
    #     'X.509/DER' = @{
    #         OutPath = "$PSScriptRoot\TestData\ca.cer"
    #     }
    #     'X.509/PEM' = @{
    #         OutPath = "$PSScriptRoot\TestData\ca.pem"
    #     }
    # }

    # $content = @{
    #     'X.509/DER' = Get-Content "$PSScriptRoot\TestData\ca.cer" -Raw
    #     'X.509/PEM' = Get-Content "$PSScriptRoot\TestData\ca.cer" -Raw
    # }

    # Context 'Input: X.509/DER' {

    #     $inSplat = $inTestData['X.509/DER']

    #     Context 'Output: X.509/PEM' {

    #         $outSplat = $outTestData['X.509/PEM']

    #         It 'should convert the root certificate' {

    #             # Act
    #             $actual = Convert-Certificate @inSplat @outSplat

    #             # Assert


    #         }
    #     }

        # # Optional password to read the input file.
        # [Parameter(Mandatory = $false)]
        # [System.Security.SecureString]
        # $InPassword,

        # # Path to the output certificate file.
        # [Parameter(Mandatory = $true, Position = 1)]
        # [Alias('Out', 'OutFile')]
        # [System.String]
        # $OutPath,

        # # Optional password to write the output file.
        # [Parameter(Mandatory = $false)]
        # [System.Security.SecureString]
        # $OutPassword,

        # # Type of the output certificate file.
        # [Parameter(Mandatory = $true, Position = 2)]
        # [ValidateSet('X.509/DER', 'X.509/PEM')]
        # [System.String]
        # $OutType

    # }

    Context 'Input: X.509/PEM' {

    }

    #     Mock 'Test-AdministratorRole' -ModuleName $moduleName { $false }

    #     It 'should throw an exception' {

    #         # Arrange, Act, Assert
    #         { Add-TrustedHost -ComputerName $Env:COMPUTERNAME } | Should Throw
    #     }
    # }

    # Context 'Is Administrator' {

    #     Mock 'Test-AdministratorRole' -ModuleName $moduleName { $true }

    #     Mock 'Get-Item' -ModuleName $ModuleName {
    #         [PSCustomObject] @{ Value = '10.0.0.1' }
    #     }

    #     Mock 'Set-Item' -ModuleName $ModuleName -Verifiable -ParameterFilter {
    #         $Path -eq 'WSMan:\localhost\Client\TrustedHosts' -and $Value -eq '10.0.0.1,SERVER,*.contoso.com'
    #     } { }

    #     It 'should add two entries via parameter' {

    #         # Arrange
    #         $list = 'SERVER', '*.contoso.com'

    #         # Act
    #         Add-TrustedHost -ComputerName $list

    #         # Assert
    #         Assert-MockCalled 'Set-Item' -ModuleName $moduleName -Times 1 -Exactly
    #     }

    #     It 'should add two entries via pipeline' {

    #         # Arrange
    #         $list = 'SERVER', '*.contoso.com'

    #         # Act
    #         $list | Add-TrustedHost

    #         # Assert
    #         Assert-MockCalled 'Set-Item' -ModuleName $moduleName -Times 2 -Exactly
    #     }
    # }
}