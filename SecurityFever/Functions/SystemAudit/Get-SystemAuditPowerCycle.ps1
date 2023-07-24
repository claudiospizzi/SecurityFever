<#
    .SYNOPSIS
        Get all audit events around the power cycle of the local system.

    .DESCRIPTION
        This function will show all power cycle events on the target system by
        parsing the following System events:
        - 1: Leaving Sleep
        - 42: Entering Sleep
        - 1074: Request System Restart / Power Off
        - 6005: System Startup
        - 6006: System Shutdown
        - 6008: Unexpected Shutdown

    .INPUTS
        None.

    .OUTPUTS
        SecurityFever.SystemAudit.Event.

    .EXAMPLE
        PS C:\> Get-SystemAuditPowerCycle
        Get the local power cycle system audit events.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-SystemAuditPowerCycle
{
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
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

    # Get all relevant event log records for the power cycle. Refer to the
    # description for the event id explanation.
    $records = Get-WinEventAdvanced -LogName 'System' -EventId 1, 42, 1074, 6005, 6006, 6008 -ProviderName 'Microsoft-Windows-Kernel-Power', 'Microsoft-Windows-Power-Troubleshooter', 'User32', 'EventLog' -DayPeriod $DayPeriod

    foreach ($record in $records)
    {
        $recordId = $record.Id

        $auditEvent = [PSCustomObject] @{
            PSTypeName  = 'SecurityFever.SystemAudit.Event'
            Timestamp   = $record.TimeCreated
            Machine     = $record.MachineName
            User        = Get-WinEventRecordUser -Record $record
            Component   = 'System Power'
            Action      = $configEventLog.Events.System.$recordId.Action
            Context     = ''
            Detail      = ''
            SourcePath  = '/EventLog/System/Record[@Id={0}]' -f $recordId
            SourceEvent = $record
        }

        # Try to get the reason for sleep and awake action
        if ($recordId -eq 1)
        {
            switch ($record.Properties[12].Value)
            {
                1 { $auditEvent.Detail = 'Reason: Power Button' }
                3 { $auditEvent.Detail = 'Reason: S4 Doze to Hibernate' }
                5 { $auditEvent.Detail = 'Reason: Device - ACPI Lid' }
            }
        }
        if ($recordId -eq 42)
        {
            switch ($record.Properties[2].Value)
            {
                0 { $auditEvent.Detail = 'Reason: Button or Lid' }
                2 { $auditEvent.Detail = 'Reason: Battery' }
                4 { $auditEvent.Detail = 'Reason: Application API' }
                6 { $auditEvent.Detail = 'Reason: Hibernate from Sleep - Fixed Timeout' }
                7 { $auditEvent.Detail = 'Reason: System Idle' }
            }
        }

        # Add additional info to the reboot or power off request
        if ($recordId -eq 1074)
        {
            $auditEvent.Detail = 'Process: {0}' -f $record.Properties[0].Value.ToLower()
            $auditEvent.Action = $auditEvent.Action -f [System.Globalization.CultureInfo]::InvariantCulture.TextInfo.ToTitleCase($Record.Properties[4].Value)
        }

        # Update the date for the unexpected reboot
        if ($recordId -eq 6008)
        {
            # Helper char, must be removed from the date property
            $lrMark    = [char]8206
            $timestamp = '{0} {1}' -f $record.Properties[1].Value.Replace("$lrMark", ""), $record.Properties[0].Value

            try
            {
                $auditEvent.Timestamp = [System.DateTime]::Parse($timestamp)
                $auditEvent.Detail    = "Event Created: {0}" -f $record.TimeCreated
            }
            catch
            {
                Write-Warning "Failed to parse timestamp $timestamp for System event id 6008: $_"
            }
        }

        Write-Output $auditEvent
    }
}
