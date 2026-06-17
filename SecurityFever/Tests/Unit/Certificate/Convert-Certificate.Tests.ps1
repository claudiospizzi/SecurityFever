
BeforeAll {

    $modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
    $moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module -Name "$modulePath\$moduleName" -Force
}

Describe 'Convert-Certificate' {

    $testDataPath = Resolve-Path -Path "$PSScriptRoot\TestData" | Select-Object -ExpandProperty 'Path'

    $testCases = @(
        @{
            InPath  = $testDataPath
            InFile  = 'ca.pem'
            InType  = 'X.509/PEM'
            OutFile = 'ca.pem'
            OutType = 'X.509/PEM'
        }
        @{
            InPath  = $testDataPath
            InFile  = 'ca.pem'
            InType  = 'X.509/PEM'
            OutFile = 'ca.cer'
            OutType = 'X.509/DER'
        }
        @{
            InPath  = $testDataPath
            InFile  = 'ca.cer'
            InType  = 'X.509/DER'
            OutFile = 'ca.pem'
            OutType = 'X.509/PEM'
        }
        @{
            InPath  = $testDataPath
            InFile  = 'ca.cer'
            InType  = 'X.509/DER'
            OutFile = 'ca.cer'
            OutType = 'X.509/DER'
        }
        @{
            InPath  = $testDataPath
            InFile  = 'cert.pem'
            InType  = 'X.509/PEM'
            OutFile = 'cert.pem'
            OutType = 'X.509/PEM'
        }
        @{
            InPath  = $testDataPath
            InFile  = 'cert.pem'
            InType  = 'X.509/PEM'
            OutFile = 'cert.cer'
            OutType = 'X.509/DER'
        }
        @{
            InPath  = $testDataPath
            InFile  = 'cert.cer'
            InType  = 'X.509/DER'
            OutFile = 'cert.pem'
            OutType = 'X.509/PEM'
        }
        @{
            InPath  = $testDataPath
            InFile  = 'cert.cer'
            InType  = 'X.509/DER'
            OutFile = 'cert.cer'
            OutType = 'X.509/DER'
        }
    )

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

            switch ($Type)
            {
                'X.509/DER' {
                    $hashObject = Get-FileHash -Path $Path -Algorithm 'SHA256'
                    return $hashObject.Hash
                }
                'X.509/PEM' {
                    $content = Get-Content -Path $Path -Raw
                    return $content
                }
            }
        }
    }

    BeforeEach {

        Get-ChildItem -Path 'TestDrive:' -Include '*.cer', '*.pem', '*.pfx', '*.p7b' -Recurse | Remove-Item -Force
    }

    It 'Should convert <InFile> (<InType>) to <OutFile> (<OutType>)' -TestCases $testCases {

        param ($InPath, $InFile, $OutFile, $OutType)

        # Arrange
        $expected = Get-CertificateFile -Path "$InPath\$OutFile" -Type $OutType

        # Act
        Convert-Certificate -InPath "$InPath\$InFile" -OutPath "TestDrive:\$OutFile" -OutType $OutType

        # Assert
        Get-CertificateFile -Path "TestDrive:\$OutFile" -Type $OutType | Should -Be $expected
    }
}
