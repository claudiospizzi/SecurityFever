
$ModulePath = Resolve-Path -Path "$PSScriptRoot\..\..\Modules" | ForEach-Object Path
$ModuleName = Get-ChildItem -Path $ModulePath | Select-Object -First 1 -ExpandProperty BaseName

Remove-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue
Import-Module -Name "$ModulePath\$ModuleName" -Force

Describe 'Get-SecurityAuditPolicySettings' {

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

        It 'should return a boolean value' {

            $securityAuditPolicySettingParam = @{
                Category    = 'System'
                Subcategory = 'Security System Extension'
                Setting     = 'Success'
            }

            $AuditPolicySetting = Get-SecurityAuditPolicySetting @SecurityAuditPolicySettingParam

            $AuditPolicySetting.GetType().FullName | Should Be 'System.Boolean'
        }

        It 'should parse "Success and Failure" setting' {

            $securityAuditPolicySettingParam = @{
                Category    = 'System'
                Subcategory = 'Security System Extension'
            }

            $auditPolicySettingSuccess = Get-SecurityAuditPolicySetting @SecurityAuditPolicySettingParam -Setting 'Success'
            $auditPolicySettingFailure = Get-SecurityAuditPolicySetting @SecurityAuditPolicySettingParam -Setting 'Failure'

            $auditPolicySettingSuccess | Should Be $true
            $auditPolicySettingFailure | Should Be $true
        }

        It 'should parse "No Auditing" setting' {

            $securityAuditPolicySettingParam = @{
                Category    = 'Logon/Logoff'
                Subcategory = 'Account Lockout'
            }

            $auditPolicySettingSuccess = Get-SecurityAuditPolicySetting @SecurityAuditPolicySettingParam -Setting 'Success'
            $auditPolicySettingFailure = Get-SecurityAuditPolicySetting @SecurityAuditPolicySettingParam -Setting 'Failure'

            $auditPolicySettingSuccess | Should Be $false
            $auditPolicySettingFailure | Should Be $false
        }

        It 'should parse "Success" setting' {

            $securityAuditPolicySettingParam = @{
                Category    = 'Detailed Tracking'
                Subcategory = 'Process Creation'
            }

            $auditPolicySettingSuccess = Get-SecurityAuditPolicySetting @SecurityAuditPolicySettingParam -Setting 'Success'
            $auditPolicySettingFailure = Get-SecurityAuditPolicySetting @SecurityAuditPolicySettingParam -Setting 'Failure'

            $auditPolicySettingSuccess | Should Be $true
            $auditPolicySettingFailure | Should Be $false
        }

        It 'should parse "Failure" setting' {

            $securityAuditPolicySettingParam = @{
                Category    = 'Object Access'
                Subcategory = 'File System'
            }

            $auditPolicySettingSuccess = Get-SecurityAuditPolicySetting @SecurityAuditPolicySettingParam -Setting 'Success'
            $auditPolicySettingFailure = Get-SecurityAuditPolicySetting @SecurityAuditPolicySettingParam -Setting 'Failure'

            $auditPolicySettingSuccess | Should Be $false
            $auditPolicySettingFailure | Should Be $true
        }
    }
}
