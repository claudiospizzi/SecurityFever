
BeforeAll {

    $modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
    $moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module -Name "$modulePath\$moduleName" -Force
}

Describe 'Convert-Certificate' {

    BeforeAll {

        function Get-CertificateFile
        {
            param
            (
                [Parameter(Mandatory = $true)]
                [System.String]
                $Path,

                [Parameter(Mandatory = $true)]
                [System.String]
                $Type
            )

            if ($Type -eq 'X.509/DER')
            {
                # For DER we don't compare the content but the file hash.
                $hashObject = Get-FileHash -Path $Path -Algorithm 'SHA256'
                return $hashObject.Hash
            }
            else
            {
                $content = Get-Content -Path $Path -Raw

                # Depending on the OS, replace the line endings with the correct
                # ones. This is required for the test cases to pass on Linux and
                # Windows.
                if ($PSVersionTable.PSVersion.Major -gt 5 -and ($IsLinux -or $IsMacOS))
                {
                    # Just remove the carriage return characters. The line feed
                    # characters are already the correct ones on Linux and
                    # macOS.
                    $content = $content.Replace("`r", '')
                }
                else
                {
                    # Replace the line endings with the correct ones for
                    # Windows.
                    $content = $content.Replace("`r", '').Replace("`n", "`r`n")
                }

                return $content
            }
        }
    }

    BeforeEach {

        Get-ChildItem -Path 'TestDrive:' -Include '*.cer', '*.pem', '*.pfx', '*.p7b' -Recurse | Remove-Item -Force
    }

    $testDataPath = Resolve-Path -Path "$PSScriptRoot\TestData" | Select-Object -ExpandProperty 'Path'

    $testCasesSingleFile = @(
        # X.509/PEM -> X.509/PEM (ca cert)
        @{
            InPath  = $testDataPath
            InFile  = 'ca.pem'
            InType  = 'X.509/PEM'
            OutFile = 'ca.pem'
            OutType = 'X.509/PEM'
        }
        # X.509/PEM -> X.509/DER (ca cert)
        @{
            InPath  = $testDataPath
            InFile  = 'ca.pem'
            InType  = 'X.509/PEM'
            OutFile = 'ca.cer'
            OutType = 'X.509/DER'
        }
        # X.509/DER -> X.509/PEM (ca cert)
        @{
            InPath  = $testDataPath
            InFile  = 'ca.cer'
            InType  = 'X.509/DER'
            OutFile = 'ca.pem'
            OutType = 'X.509/PEM'
        }
        # X.509/DER -> X.509/DER (ca cert)
        @{
            InPath  = $testDataPath
            InFile  = 'ca.cer'
            InType  = 'X.509/DER'
            OutFile = 'ca.cer'
            OutType = 'X.509/DER'
        }
        # X.509/PKCS#7 -> X.509/PEM (ca cert)
        @{
            InPath  = $testDataPath
            InFile  = 'ca.p7b'
            InType  = 'X.509/PKCS#7'
            OutFile = 'ca.pem'
            OutType = 'X.509/PEM'
        }
        # X.509/PKCS#7 -> X.509/DER (ca cert)
        @{
            InPath  = $testDataPath
            InFile  = 'ca.p7b'
            InType  = 'X.509/PKCS#7'
            OutFile = 'ca.cer'
            OutType = 'X.509/DER'
        }
        # PKCS#12 (AES) -> X.509/PEM (ca cert)
        @{
            InPath  = $testDataPath
            InFile  = 'ca-aes.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'ca.pem'
            OutType = 'X.509/PEM'
        }
        # PKCS#12 (AES) -> X.509/DER (ca cert)
        @{
            InPath  = $testDataPath
            InFile  = 'ca-aes.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'ca.cer'
            OutType = 'X.509/DER'
        }
        # PKCS#12 (AES) -> PKCS#1 (RSA private key)
        @{
            InPath  = $testDataPath
            InFile  = 'ca-aes.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'ca-rsa.pem'
            OutType = 'PKCS#1'
        }
        # PKCS#12 (AES) -> PKCS#8 (private key)
        @{
            InPath  = $testDataPath
            InFile  = 'ca-aes.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'ca-key.pem'
            OutType = 'PKCS#8'
        }
        # PKCS#12 (3DES) -> X.509/PEM (ca cert)
        @{
            InPath  = $testDataPath
            InFile  = 'ca-3des.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'ca.pem'
            OutType = 'X.509/PEM'
        }
        # PKCS#12 (3DES) -> X.509/DER (ca cert)
        @{
            InPath  = $testDataPath
            InFile  = 'ca-3des.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'ca.cer'
            OutType = 'X.509/DER'
        }
        # PKCS#12 (3DES) -> PKCS#1 (RSA private key)
        @{
            InPath  = $testDataPath
            InFile  = 'ca-3des.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'ca-rsa.pem'
            OutType = 'PKCS#1'
        }
        # PKCS#12 (3DES) -> PKCS#8 (private key)
        @{
            InPath  = $testDataPath
            InFile  = 'ca-3des.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'ca-key.pem'
            OutType = 'PKCS#8'
        }
        # X.509/PEM -> X.509/PEM (issued cert)
        @{
            InPath  = $testDataPath
            InFile  = 'cert.pem'
            InType  = 'X.509/PEM'
            OutFile = 'cert.pem'
            OutType = 'X.509/PEM'
        }
        # X.509/PEM -> X.509/DER (issued cert)
        @{
            InPath  = $testDataPath
            InFile  = 'cert.pem'
            InType  = 'X.509/PEM'
            OutFile = 'cert.cer'
            OutType = 'X.509/DER'
        }
        # X.509/DER -> X.509/PEM (issued cert)
        @{
            InPath  = $testDataPath
            InFile  = 'cert.cer'
            InType  = 'X.509/DER'
            OutFile = 'cert.pem'
            OutType = 'X.509/PEM'
        }
        # X.509/DER -> X.509/DER (issued cert)
        @{
            InPath  = $testDataPath
            InFile  = 'cert.cer'
            InType  = 'X.509/DER'
            OutFile = 'cert.cer'
            OutType = 'X.509/DER'
        }
        # X.509/PKCS#7 -> X.509/PEM (issued cert / single)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-single.p7b'
            InType  = 'X.509/PKCS#7'
            OutFile = 'cert.pem'
            OutType = 'X.509/PEM'
        }
        # X.509/PKCS#7 -> X.509/DER (issued cert / single)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-single.p7b'
            InType  = 'X.509/PKCS#7'
            OutFile = 'cert.cer'
            OutType = 'X.509/DER'
        }
        # PKCS#12 (AES) -> X.509/PEM (issued cert / single)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-single-aes.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert.pem'
            OutType = 'X.509/PEM'
        }
        # PKCS#12 (AES) -> X.509/DER (issued cert / single)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-single-aes.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert.cer'
            OutType = 'X.509/DER'
        }
        # PKCS#12 (AES) -> PKCS#1 (RSA private key / single)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-single-aes.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert-rsa.pem'
            OutType = 'PKCS#1'
        }
        # PKCS#12 (AES) -> PKCS#8 (private key / single)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-single-aes.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert-key.pem'
            OutType = 'PKCS#8'
        }
        # PKCS#12 (3DES) -> X.509/PEM (issued cert / single)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-single-3des.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert.pem'
            OutType = 'X.509/PEM'
        }
        # PKCS#12 (3DES) -> X.509/DER (issued cert / single)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-single-3des.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert.cer'
            OutType = 'X.509/DER'
        }
        # PKCS#12 (3DES) -> PKCS#1 (RSA private key / single)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-single-3des.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert-rsa.pem'
            OutType = 'PKCS#1'
        }
        # PKCS#12 (3DES) -> PKCS#8 (private key / single)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-single-3des.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert-key.pem'
            OutType = 'PKCS#8'
        }
        # PKCS#12 (AES) -> X.509/PEM (issued cert / chain)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-chain-aes.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert.pem'
            OutType = 'X.509/PEM'
        }
        # PKCS#12 (AES) -> X.509/DER (issued cert / chain)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-chain-aes.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert.cer'
            OutType = 'X.509/DER'
        }
        # PKCS#12 (AES) -> PKCS#1 (RSA private key / chain)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-chain-aes.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert-rsa.pem'
            OutType = 'PKCS#1'
        }
        # PKCS#12 (AES) -> PKCS#8 (private key / chain)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-chain-aes.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert-key.pem'
            OutType = 'PKCS#8'
        }
        # PKCS#12 (3DES) -> X.509/PEM (issued cert / chain)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-chain-3des.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert.pem'
            OutType = 'X.509/PEM'
        }
        # PKCS#12 (3DES) -> X.509/DER (issued cert / chain)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-chain-3des.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert.cer'
            OutType = 'X.509/DER'
        }
        # PKCS#12 (3DES) -> PKCS#1 (RSA private key / chain)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-chain-3des.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert-rsa.pem'
            OutType = 'PKCS#1'
        }
        # PKCS#12 (3DES) -> PKCS#8 (private key / chain)
        @{
            InPath  = $testDataPath
            InFile  = 'cert-chain-3des.pfx'
            InType  = 'X.509/PKCS#12'
            OutFile = 'cert-key.pem'
            OutType = 'PKCS#8'
        }
    )

    It 'Should convert <InFile> (<InType>) to <OutFile> (<OutType>)' -TestCases $testCasesSingleFile {

        param ($InPath, $InFile, $OutFile, $OutType)

        # Arrange
        $password = Protect-String -String 'Passw0rd'
        $expected = Get-CertificateFile -Path "$InPath\$OutFile" -Type $OutType

        # Act
        if ($InFile.EndsWith('.pfx'))
        {
            Convert-Certificate -InPath "$InPath\$InFile" -OutPath "TestDrive:\$OutFile" -OutType $OutType -InPassword $password
        }
        else
        {
            Convert-Certificate -InPath "$InPath\$InFile" -OutPath "TestDrive:\$OutFile" -OutType $OutType
        }

        # Assert
        Test-Path -Path "TestDrive:\$OutFile" | Should -BeTrue -Because "the output file should exist after conversion."
        Get-CertificateFile -Path "TestDrive:\$OutFile" -Type $OutType | Should -Be $expected
    }

    $testCasesMultipleFiles = @(
        # X.509/PKCS#7 -> X.509/PEM (issued cert / chain)
        @{
            InPath   = $testDataPath
            InFile   = 'cert-chain.p7b'
            InType   = 'X.509/PKCS#7'
            OutFile  = 'cert-chain.pem'
            OutFile1 = 'cert-chain-8f1bd1f.pem'
            OutFile2 = 'cert-chain-092cb28.pem'
            OutType  = 'X.509/PEM'
        }
        # X.509/PKCS#7 -> X.509/DER (issued cert / chain)
        @{
            InPath   = $testDataPath
            InFile   = 'cert-chain.p7b'
            InType   = 'X.509/PKCS#7'
            OutFile  = 'cert-chain.cer'
            OutFile1 = 'cert-chain-8f1bd1f.cer'
            OutFile2 = 'cert-chain-092cb28.cer'
            OutType  = 'X.509/DER'
        }
    )

    It 'Should convert <InFile> (<InType>) to <OutFile1> and <OutFile2> (<OutType>)' -TestCases $testCasesMultipleFiles {

        param ($InPath, $InFile, $OutFile, $OutFile1, $OutFile2, $OutType)

        # Arrange
        $expected1 = Get-CertificateFile -Path "$InPath\$OutFile1" -Type $OutType
        $expected2 = Get-CertificateFile -Path "$InPath\$OutFile2" -Type $OutType

        # Act
        Convert-Certificate -InPath "$InPath\$InFile" -OutPath "TestDrive:\$OutFile" -OutType $OutType -WarningAction 'SilentlyContinue'

        # Assert
        Test-Path -Path "TestDrive:\$OutFile" | Should -BeFalse -Because 'the output file provided by the parameter should not exist after conversion, since the input file contains multiple certificates.'
        Test-Path -Path "TestDrive:\$OutFile1" | Should -BeTrue -Because 'the output file should exist after conversion and should not be the provided output file.'
        Test-Path -Path "TestDrive:\$OutFile2" | Should -BeTrue -Because 'the output file should exist after conversion and should not be the provided output file.'
        Get-CertificateFile -Path "TestDrive:\$OutFile1" -Type $OutType | Should -Be $expected1 -Because 'the output file content should match the expected content after conversion.'
        Get-CertificateFile -Path "TestDrive:\$OutFile2" -Type $OutType | Should -Be $expected2 -Because 'the output file content should match the expected content after conversion.'
    }
}
