<#
    .SYNOPSIS
        Get all audit events around the user sessions on the local system.

    .DESCRIPTION
        tbd
#>
function Get-SystemAuditUserSession
{
    [CmdletBinding()]
    param
    (
        # Period of days to report for the audit events.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $Period = 7,

        # Switch to skip the tests
        [Parameter(Mandatory = $false)]
        [Switch]
        $SkipTest
    )

    # Load configuration
    $configEventLog = Get-Content -Path "$Script:ConfigurationPath\SystemAudit.EventLog.json" | ConvertFrom-Json

    # Test if the event log period is valid, return the start date/time
    $periodStart = Test-EventLogPeriod -LogName 'Security' -Period $Period -HideWarning:$SkipTest.IsPresent
    Test-AuditLogPolicySetting
    # Second test for the audit policy!!!

    # if ($Activity -contains 'Logon')
    # {
    #     if(-not (Get-SecurityAuditPolicySetting -Category 'Logon/Logoff' -Subcategory 'Logon' -Setting 'Success'))
    #     {
    #         Write-Warning "System audit policy for 'Logon/Logoff' > 'Logon' > 'Success' is not enabled."
    #     }
    #     if(-not (Get-SecurityAuditPolicySetting -Category 'Logon/Logoff' -Subcategory 'Logon' -Setting 'Failure'))
    #     {
    #         Write-Warning "System audit policy for 'Logon/Logoff' > 'Logon' > 'Failure' is not enabled."
    #     }
    # }
    # if ($Activity -contains 'Logoff')
    # {
    #     if(-not (Get-SecurityAuditPolicySetting -Category 'Logon/Logoff' -Subcategory 'Logoff' -Setting 'Success'))
    #     {
    #         Write-Warning "System audit policy for 'Logon/Logoff' > 'Logoff' > 'Success' is not enabled."
    #     }
    # }

    # Get all relevant event log records for the MSI Installer
    $records = Get-WinEventAdvanced -LogName 'Security' -EventId  -From $periodStart

    foreach ($record in $records)
    {
        $recordId = $record.Id

        if ($record.ProviderName -eq $configEventLog.System.$recordId.ProviderName)
        {
            $event = [PSCustomObject] @{
                PSTypeName = 'SecurityFever.SystemAuditEvent'
                Timestamp  = $record.TimeCreated
                Machine    = $record.MachineName
                User       = Get-WinEventRecordUser -Record $record
                Component  = ''
                Action     = ''
                Context    = ''
                Detail     = ''
                Source     = '/EventLog/Security/Record[@Id={0}]' -f $recordId
            }

            Write-Output $event
        }
    }
}
