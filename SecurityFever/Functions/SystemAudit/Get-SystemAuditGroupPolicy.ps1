<#
    .SYNOPSIS
        Get all audit events around the user sessions on the local system.

    .DESCRIPTION
        This function will show all user setting audit events by parsing the
        Security event log:
        - 1502: Computer Group Policy Changed
        - 1503: User Group Policy Changed
#>
function Get-SystemAuditGroupPolicy
{
    [CmdletBinding()]
    param
    (
        # Period of days to cover.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $DayPeriod = 7,

        # Show extended events, not only the important ones.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Extended,

        # Hide the warning messages, don't test the prerequisites.
        [Parameter(Mandatory = $false)]
        [Switch]
        $HideWarning
    )

    Show-SystemAuditEventLogWarning -LogName 'System' -DayPeriod $DayPeriod -HideWarning:$HideWarning.IsPresent

    $configEventLog = Get-Content -Path "$Script:ConfigurationPath\SystemAudit.EventLog.json" | ConvertFrom-Json

    # Get all relevant event log records for user session events
    $records = Get-WinEventAdvanced -LogName 'System' -EventId 1502, 1503 -ProviderName 'Microsoft-Windows-GroupPolicy' -DayPeriod $DayPeriod

    foreach ($record in $records)
    {
        $recordId = $record.Id

        $event = [PSCustomObject] @{
            PSTypeName = 'SecurityFever.SystemAuditEvent'
            Timestamp  = $record.TimeCreated
            Machine    = $record.MachineName
            User       = Get-WinEventRecordUser -Record $record
            Component  = 'Group Policy'
            Action     = $configEventLog.System.$recordId.Action
            Context    = ''
            Detail     = ''
            Source     = '/EventLog/Security/System[@Id={0}]' -f $recordId
        }

        # Get record properties
        $recordProperties = Get-WinEventRecordProperty -Record $record -PropertyName $configEventLog.System.$recordId.Properties

        # Update the context
        $event.Context = '{0} Settings Changed' -f $recordProperties.NumberOfGroupPolicyObjects

        Write-Output $event
    }
}
