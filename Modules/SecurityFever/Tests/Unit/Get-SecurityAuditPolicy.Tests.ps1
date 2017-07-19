
$modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Select-Object -ExpandProperty Path
$moduleName = Resolve-Path -Path "$PSScriptRoot\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
Import-Module -Name "$modulePath\$moduleName" -Force

Describe 'Get-SecurityAuditPolicy' {

    Copy-Item -Path "$PSScriptRoot\TestData" -Destination 'TestDrive:\' -Recurse

    Mock 'Invoke-AuditPolGetCategoryAllCsv' -ModuleName $ModuleName {
        Get-Content -Path 'TestDrive:\TestData\auditpol-getcategoryall.csv' | Write-Output
    }

    Mock 'Invoke-AuditPolListSubcategoryAllCsv' -ModuleName $ModuleName {
        Get-Content -Path 'TestDrive:\TestData\auditpol-listsubcategoryall.csv' | Write-Output
    }

    Mock 'Test-AdministratorRole' -ModuleName $ModuleName {
        return $true
    }

    Context 'Verify Output' {

        It 'should return all audit policies' {

            $auditPolicies = Get-SecurityAuditPolicy

            $auditPolicies.Count | Should Be 53
        }

        It 'should parse category and subcategory' {

            $auditPolicies = Get-SecurityAuditPolicy

            $auditPolicies[0].ComputerName    | Should Be 'PC'
            $auditPolicies[0].Category        | Should Be 'System'
            $auditPolicies[0].CategoryGuid    | Should Be '{69979848-797A-11D9-BED3-505054503030}'
            $auditPolicies[0].Subcategory     | Should Be 'Security State Change'
            $auditPolicies[0].SubcategoryGuid | Should Be '{0CCE9210-69AE-11D9-BED3-505054503030}'

            $auditPolicies[21].ComputerName    | Should Be 'PC'
            $auditPolicies[21].Category        | Should Be 'Object Access'
            $auditPolicies[21].CategoryGuid    | Should Be '{6997984A-797A-11D9-BED3-505054503030}'
            $auditPolicies[21].Subcategory     | Should Be 'File Share'
            $auditPolicies[21].SubcategoryGuid | Should Be '{0CCE9224-69AE-11D9-BED3-505054503030}'

            $auditPolicies[52].ComputerName    | Should Be 'PC'
            $auditPolicies[52].Category        | Should Be 'Account Logon'
            $auditPolicies[52].CategoryGuid    | Should Be '{69979850-797A-11D9-BED3-505054503030}'
            $auditPolicies[52].Subcategory     | Should Be 'Kerberos Authentication Service'
            $auditPolicies[52].SubcategoryGuid | Should Be '{0CCE9242-69AE-11D9-BED3-505054503030}'
        }

        It 'should parse "Success and Failure" setting' {

            $auditPolicy = Get-SecurityAuditPolicy |
                               Where-Object { $_.Category -eq 'System' -and $_.Subcategory -eq 'Security System Extension' }

            $auditPolicy.AuditSuccess | Should Be $true
            $auditPolicy.AuditFailure | Should Be $true
        }

        It 'should parse "No Auditing" setting' {

            $auditPolicy = Get-SecurityAuditPolicy |
                               Where-Object { $_.Category -eq 'Logon/Logoff' -and $_.Subcategory -eq 'Account Lockout' }

            $auditPolicy.AuditSuccess | Should Be $false
            $auditPolicy.AuditFailure | Should Be $false
        }

        It 'should parse "Success" setting' {

            $auditPolicy = Get-SecurityAuditPolicy |
                               Where-Object { $_.Category -eq 'Account Logon' -and $_.Subcategory -eq 'Credential Validation' }

            $auditPolicy.AuditSuccess | Should Be $true
            $auditPolicy.AuditFailure | Should Be $false
        }

        It 'should parse "Failure" setting' {

            $auditPolicy = Get-SecurityAuditPolicy |
                               Where-Object { $_.Category -eq 'Object Access' -and $_.Subcategory -eq 'File System' }

            $auditPolicy.AuditSuccess | Should Be $false
            $auditPolicy.AuditFailure | Should Be $true
        }
    }

    Context 'Permission' {

        Mock 'Test-AdministratorRole' -ModuleName $ModuleName {
            return $false
        }

        It 'should throw an exception if not run as administrator' {

            { Get-SecurityAuditPolicy } | Should Throw
        }
    }

    Context 'Type' {

        It 'should return as "SecurityFever.AuditPolicy" type' {

            $auditPolicies = Get-SecurityAuditPolicy

            ($auditPolicies | Get-Member).TypeName | Select-Object -First 1 | Should Be 'SecurityFever.AuditPolicy'
        }
    }
}
