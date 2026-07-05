BeforeAll {

    $modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
    $moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module -Name "$modulePath\$moduleName" -Force
}

Describe 'Export-CertificatePrivateKey' {

    BeforeAll {

        function Get-CertificateFile
        {
            param
            (
                [Parameter(Mandatory = $true)]
                [System.String]
                $Path
            )

            $content = Get-Content -Path $Path -Raw

            # Depending on the OS, replace the line endings with the correct
            # ones. This is required for the test cases to pass on Linux and
            # Windows.
            if ($PSVersionTable.PSVersion.Major -gt 5 -and ($IsLinux -or $IsMacOS))
            {
                # Just remove the carriage return characters. The line feed
                # characters are already the correct ones on Linux and macOS.
                $content = $content.Replace("`r", '')
            }
            else
            {
                # Replace the line endings with the correct ones for Windows.
                $content = $content.Replace("`r", '').Replace("`n", "`r`n")
            }

            return $content
        }
    }

    BeforeEach {

        Get-ChildItem -Path 'TestDrive:' -Include '*.cer', '*.pem', '*.pfx', '*.p7b' -Recurse | Remove-Item -Force
    }

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
        $expected = Get-CertificateFile -Path "$InPath\$OutFile"

        # Act
        Export-CertificatePrivateKey -InPath "$InPath\$InFile" -InPassword $password -OutPath "TestDrive:\$OutFile" -OutFormat $OutFormat

        # Assert
        Get-CertificateFile -Path "TestDrive:\$OutFile" | Should -Be $expected
    }
}
