<#
    .SYNOPSIS
        Get all audit events of the Windows services.

    .DESCRIPTION
        This function will show all Windows service audit changes on the target
        system by parsing the following Application events:
        - 7000: Service Start Failed
        - 7001: Service Dependency Start Failed
        - 7011: Service Start/Stop Timeout
        - 7023: Service Terminated
        - 7026: Boot/System-Start Driver Not Loaded
        - 7030: Service Configuration Error: Interactive Service Configured but not Allowed
        - 7034: Service Terminated Unexpectedly
        - 7038: Service Configuration Error: Unable to Log-On
        - 7040: Service Changed: Start Type Updated
        - 7045: Service Installed

    .INPUTS
        None.

    .OUTPUTS
        SecurityFever.SystemAudit.Event.

    .EXAMPLE
        PS C:\> Get-SystemAuditWindowsService
        Get the local Windows service system audit events.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-SystemAuditWindowsService
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

    # Get all relevant event log records for the MSI Installer
    $records = Get-WinEventAdvanced -LogName 'System' -EventId 7000, 7001, 7011, 7023, 7026, 7030, 7034, 7038, 7040, 7045 -ProviderName 'Service Control Manager' -DayPeriod $DayPeriod

    foreach ($record in $records)
    {
        $recordId = $record.Id

        $auditEvent = [PSCustomObject] @{
            PSTypeName  = 'SecurityFever.SystemAudit.Event'
            Timestamp   = $record.TimeCreated
            Machine     = $record.MachineName
            User        = Get-WinEventRecordUser -Record $record
            Component   = 'Windows Service'
            Action      = $configEventLog.Events.System.$recordId.Action
            Context     = $record.Properties[0].Value
            Detail      = ''
            SourcePath  = '/EventLog/Application/Record[@Id={0}]' -f $recordId
            SourceEvent = $record
        }

        # Fix the context for events where the service name is not stored in the
        # first property.
        if ($recordId -eq 7011)
        {
            $auditEvent.Context = $record.Properties[1].Value
        }

        # Enhance the service audit records with additional details.
        if ($recordId -eq 7000)
        {
            $auditEvent.Detail = 'Error: {0}' -f (Get-WinEventWin32Exception -ErrorCode $record.Properties[1].Value)
        }
        if ($recordId -eq 7001)
        {
            $auditEvent.Detail = 'Depending Service: {0}, Error: {1}' -f $record.Properties[1].Value, (Get-WinEventWin32Exception -ErrorCode $record.Properties[2].Value)
        }
        if ($recordId -eq 7011)
        {
            $auditEvent.Detail = 'Timeout: {0}ms' -f $record.Properties[1].Value
        }
        if ($recordId -eq 7023)
        {
            $auditEvent.Detail = 'Error: {0}' -f (Get-WinEventWin32Exception -ErrorCode $record.Properties[1].Value)
        }
        if ($recordId -eq 7034)
        {
            $auditEvent.Detail = 'Count: {0}' -f $record.Properties[1].Value
        }
        if ($recordId -eq 7038)
        {
            $auditEvent.Detail = 'User: {0}, Error: {1}' -f $record.Properties[1].Value, (Get-WinEventWin32Exception -ErrorCode $record.Properties[2].Value)
        }
        if ($recordId -eq 7040)
        {
            $auditEvent.Detail = 'Old: {0}, New: {1}' -f $record.Properties[1].Value, $record.Properties[2].Value
        }
        if ($recordId -eq 7045)
        {
            $auditEvent.Detail = 'Path: {0}, Type: {1}, Start: {2}, User: {3}' -f $record.Properties[1].Value, $record.Properties[2].Value, $record.Properties[3].Value, $record.Properties[4].Value
        }

        Write-Output $auditEvent
    }
}
