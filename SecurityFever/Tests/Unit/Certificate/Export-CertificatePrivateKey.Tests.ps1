BeforeAll {

    $modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
    $moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module -Name "$modulePath\$moduleName" -Force
}

Describe 'Export-CertificatePrivateKey' {

    $testDataPath = Resolve-Path -Path "$PSScriptRoot\TestData" | Select-Object -ExpandProperty 'Path'

    $testCases = @(
        @{
            InPath    = $testDataPath
            InFile    = 'ca-aes.pfx'
            OutFile   = 'ca-rsa.pem'
            OutFormat = 'PKCS#1'
        }
        @{
            InPath    = $testDataPath
            InFile    = 'ca-aes.pfx'
            OutFile   = 'ca-key.pem'
            OutFormat = 'PKCS#8'
        }
        @{
            InPath    = $testDataPath
            InFile    = 'ca-3des.pfx'
            OutFile   = 'ca-rsa.pem'
            OutFormat = 'PKCS#1'
        }
        @{
            InPath    = $testDataPath
            InFile    = 'ca-3des.pfx'
            OutFile   = 'ca-key.pem'
            OutFormat = 'PKCS#8'
        }
        @{
            InPath    = $testDataPath
            InFile    = 'cert-single-aes.pfx'
            OutFile   = 'cert-rsa.pem'
            OutFormat = 'PKCS#1'
        }
        @{
            InPath    = $testDataPath
            InFile    = 'cert-single-aes.pfx'
            OutFile   = 'cert-key.pem'
            OutFormat = 'PKCS#8'
        }
        @{
            InPath    = $testDataPath
            InFile    = 'cert-single-3des.pfx'
            OutFile   = 'cert-rsa.pem'
            OutFormat = 'PKCS#1'
        }
        @{
            InPath    = $testDataPath
            InFile    = 'cert-single-3des.pfx'
            OutFile   = 'cert-key.pem'
            OutFormat = 'PKCS#8'
        }
    )

    It 'Should export private key of <InFile> to <OutFile> (<OutFormat>)' -TestCases $testCases {

        param ($InPath, $InFile, $OutFile, $OutFormat)

        # Arrange
        $password = Protect-String -String 'Passw0rd'
        $expected = Get-Content -Path "$InPath\$OutFile" -Raw

        # Act
        Export-CertificatePrivateKey -InPath "$InPath\$InFile" -InPassword $password -OutPath "TestDrive:\$OutFile" -OutFormat $OutFormat

        # Assert
        Get-Content -Path "TestDrive:\$OutFile" -Raw | Should -Be $expected
    }
}
