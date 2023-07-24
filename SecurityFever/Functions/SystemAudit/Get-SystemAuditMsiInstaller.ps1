<#
    .SYNOPSIS
        Get all audit events of the MSI Installer.

    .DESCRIPTION
        This function will show all MSI Installer audit changes on the target
        system by parsing the following Application events:
        - 11707: Installation completed successfully
        - 11708: Installation failed
        - 11724: Removal completed successfully
        - 11725: Removal failed
        - 11728: Configuration completed successfully
        - 11729: Configuration failed

    .INPUTS
        None.

    .OUTPUTS
        SecurityFever.SystemAudit.Event.

    .EXAMPLE
        PS C:\> Get-SystemAuditMsiInstaller
        Get the local MSI installer system audit events.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-SystemAuditMsiInstaller
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

    Show-SystemAuditEventLogWarning -LogName 'Application' -DayPeriod $DayPeriod -HideWarning:$HideWarning.IsPresent

    $configEventLog = Get-Content -Path "$Script:ConfigurationPath\SystemAudit.EventLog.json" | ConvertFrom-Json

    # Get all relevant event log records for the MSI Installer
    $records = Get-WinEventAdvanced -LogName 'Application' -EventId 11707, 11708, 11724, 11725, 11728, 11729 -ProviderName 'MsiInstaller' -DayPeriod $DayPeriod

    foreach ($record in $records)
    {
        $recordId = $record.Id

        $auditEvent = [PSCustomObject] @{
            PSTypeName  = 'SecurityFever.SystemAudit.Event'
            Timestamp   = $record.TimeCreated
            Machine     = $record.MachineName
            User        = Get-WinEventRecordUser -Record $record
            Component   = 'MSI Installer'
            Action      = $configEventLog.Events.Application.$recordId.Action
            Context     = ''
            Detail      = ''
            SourcePath  = '/EventLog/Application/Record[@Id={0}]' -f $recordId
            SourceEvent = $record
        }

        # Extract the product name from the event message, see this example:
        # Product: My Product -- Installation completed successfully.
        $auditEvent.Context = $record.Properties[0].Value
        $auditEvent.Context = $auditEvent.Context.Substring($auditEvent.Context.IndexOf(': ') + 2)
        $auditEvent.Context = $auditEvent.Context.Substring(0, $auditEvent.Context.LastIndexOf(' -- '))

        Write-Output $auditEvent
    }
}
