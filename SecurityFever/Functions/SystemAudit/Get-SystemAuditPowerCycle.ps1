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
#>
function Get-SystemAuditPowerCycle
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
    $periodStart = Test-EventLogPeriod -LogName 'System' -Period $Period -HideWarning:$SkipTest.IsPresent

    # Get all relevant event log records for the MSI Installer
    $records = Get-WinEventAdvanced -LogName 'System' -EventId 1, 42, 1074, 6005, 6006, 6008 -From $periodStart

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
                Component  = 'System Power'
                Action     = $configEventLog.System.$recordId.Action
                Context    = ''
                Detail     = ''
                Source     = '/EventLog/System/Record[@Id={0}]' -f $recordId
            }

            # Try to get the reason for sleep and awake action
            if ($recordId -eq 1)
            {
                switch ($record.Properties[12].Value)
                {
                    1 { $event.Detail = 'Reason: Power Button' }
                    3 { $event.Detail = 'Reason: S4 Doze to Hibernate' }
                    5 { $event.Detail = 'Reason: Device - ACPI Lid' }
                }
            }
            if ($recordId -eq 42)
            {
                switch ($record.Properties[2].Value)
                {
                    0 { $event.Detail = 'Reason: Button or Lid' }
                    2 { $event.Detail = 'Reason: Battery' }
                    4 { $event.Detail = 'Reason: Application API' }
                    6 { $event.Detail = 'Reason: Hibernate from Sleep - Fixed Timeout' }
                    7 { $event.Detail = 'Reason: System Idle' }
                }
            }

            # Add aditionall info to the reboot / power off request
            if ($recordId -eq 1074)
            {
                $event.Detail = 'Process: {0}' -f $record.Properties[0].Value.ToLower()
                $event.Action = $event.Action -f [System.Globalization.CultureInfo]::InvariantCulture.TextInfo.ToTitleCase($Record.Properties[4].Value)
            }

            # Update the date for the unexpected reboot
            if ($recordId -eq 6008)
            {
                # Helper char, must be removed from the date property
                $lrMark    = [char]8206
                $timestamp = '{0} {1}' -f $record.Properties[1].Value.Replace("$lrMark", ""), $record.Properties[0].Value

                try
                {
                    $event.Timestamp = [System.DateTime]::Parse($timestamp)
                    $event.Detail    = "Event Created: {0}" -f $record.TimeCreated
                }
                catch
                {
                    Write-Warning "Failed to parse timestamp $timestamp for System event id 6008: $_"
                }
            }

            Write-Output $event
        }
    }
}
