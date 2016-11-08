
$ModulePath = Resolve-Path -Path "$PSScriptRoot\..\..\Sources" | ForEach-Object Path
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

        AfterAll {

            Write-Verbose 'Remove local test account'

            Remove-LocalUser -Name $expectedUsername -Verbose
        }
    }
}
