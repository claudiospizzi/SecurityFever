
$ProjectRoot = ($PSScriptRoot | Split-Path)
$ModuleName  = (Get-ChildItem -Path "$ProjectRoot\Sources" | Select-Object -First 1 -ExpandProperty Name)

Describe 'Meta' {

    $TextFiles = Get-ChildItem -Path "$PSScriptRoot\.." -File -Recurse |
                     Where-Object { '.gitignore', '.gitattributes', '.ps1', '.psm1', '.psd1', '.ps1xml', '.txt', '.xml', '.cmd', '.json', '.md' -contains $_.Extension } |
                         ForEach-Object { $_.FullName }

    Context 'Project Structure' {

        It 'should contain the required module files' {

            $ErrorCount = 0

            $Paths = @(
                '\appveyor.yml'
                '\LICENSE'
                '\README.md'
                '\Scripts\build.ps1'
                '\Scripts\deploy.ps1'
                '\Scripts\test.ps1'
                "\Sources\$ModuleName"
                "\Sources\$ModuleName\$ModuleName.psd1"
                "\Sources\$ModuleName\$ModuleName.psm1"
                "\Sources\$ModuleName\en-US"
                "\Sources\$ModuleName\en-US\about_$ModuleName.help.txt"
                "\Sources\$ModuleName\Functions"
                "\Sources\$ModuleName\Helpers"
                "\Sources\$ModuleName\Resources"
                "\Sources\$ModuleName\Resources\$ModuleName.Formats.ps1xml"
                "\Sources\$ModuleName\Resources\$ModuleName.Types.ps1xml"
                '\Tests\Meta.Tests.ps1'
            )

            foreach ($Path in $Paths)
            {
                if (-not (Join-Path -Path $ProjectRoot -ChildPath $Path | Test-Path))
                {
                    Write-Warning ('File or folder {0} does not exist.' -f $Path)

                    $ErrorCount++
                }
            }

            $ErrorCount | Should Be 0
        }
    }

    Context 'File Encoding' {

        It 'should not use Unicode encoding' {

            $ErrorFiles = 0

            foreach ($TextFile in $TextFiles)
            {
                if (@([System.IO.File]::ReadAllBytes($TextFile) -eq 0).Length -gt 0)
                {
                    Write-Warning "File $TextFile contains 0x00 bytes. It's probably uses Unicode and need to be converted to UTF-8."

                    $ErrorFiles++
                }
            }

            $ErrorFiles | Should Be 0
        }

        It 'should not use BOM for UTF-8' {

            $ErrorFiles = 0

            foreach ($TextFile in $TextFiles)
            {
                $Bytes = [System.IO.File]::ReadAllBytes($TextFile)

                if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 239 -and $Bytes[1] -eq 187 -and $Bytes[2] -eq 191)
                {
                    Write-Warning "File $TextFile starts with 0xEF 0xBB 0xBF. It's probably uses UTF-8 with BOM encoding. Remove the BOM encoding."

                    $ErrorFiles++
                }
            }

            $ErrorFiles | Should Be 0
        }
    }

    Context 'Indentations' {

        It 'should use spaces for indentation, not tabs' {

            $ErrorFiles = 0

            foreach ($TextFile in $TextFiles)
            {
                $ErrorLines = @()

                $Content = Get-Content -Path $TextFile

                for ($Line = 0; $Line -lt $Content.Length; $Line++)
                {
                    if(($Content[$Line] | Select-String "`t" | Measure-Object).Count -ne 0)
                    {
                        $ErrorLines += $Line + 1
                    }
                }

                if ($ErrorLines -gt 0)
                {
                    Write-Warning "There are tab in $TextFile. Remove tabs or replace with spaces. Lines: $($ErrorLines -join ', ')"

                    $ErrorFiles++
                }
            }

            $ErrorFiles | Should Be 0
        }

        It 'should use no trailing spaces for lines' {

            $ErrorFiles = 0

            foreach ($TextFile in $TextFiles)
            {
                $ErrorLines = @()

                $Content = Get-Content -Path $TextFile

                for ($Line = 0; $Line -lt $Content.Length; $Line++)
                {
                    if($Content[$Line].TrimEnd() -ne $Content[$Line])
                    {
                        $ErrorLines += $Line + 1
                    }
                }

                if ($ErrorLines -gt 0)
                {
                    Write-Warning "There are trailing white spaces in $TextFile. Remove white space. Lines: $($ErrorLines -join ', ')"

                    $ErrorFiles++
                }
            }

            $ErrorFiles | Should Be 0
        }
    }

    Context 'New Lines' {

        It 'should end with a new line' {

            $ErrorFiles = 0

            foreach ($TextFile in $TextFiles)
            {
                $TextFileContent = Get-Content -Path $TextFile -Raw

                if ($TextFileContent.Length -ne 0 -and $TextFileContent[-1] -ne "`n")
                {
                    Write-Warning "$TextFile does not end with a new line."

                    $ErrorFiles++
                }
            }

            $ErrorFiles | Should Be 0
        }
    }

    Context 'Module Import' {

        It 'should import without any errors' {

            { Import-Module "$ProjectRoot\$ModuleName" -Verbose:$false -ErrorAction Stop } | Should Not Throw

            Remove-Module -Name 'OperationsManagerFever' -Verbose:$false -ErrorAction SilentlyContinue -Force
        }
    }
}
