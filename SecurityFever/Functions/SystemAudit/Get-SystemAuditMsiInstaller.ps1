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
#>
function Get-SystemAuditMsiInstaller
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

    Show-SystemAuditEventLogWarning -LogName 'Application' -DayPeriod $DayPeriod -HideWarning:$HideWarning.IsPresent

    $configEventLog = Get-Content -Path "$Script:ConfigurationPath\SystemAudit.EventLog.json" | ConvertFrom-Json

    # Get all relevant event log records for the MSI Installer
    $records = Get-WinEventAdvanced -LogName 'Application' -EventId 11707, 11708, 11724, 11725, 11728, 11729 -ProviderName 'MsiInstaller' -DayPeriod $DayPeriod

    foreach ($record in $records)
    {
        $recordId = $record.Id

        $event = [PSCustomObject] @{
            PSTypeName = 'SecurityFever.SystemAuditEvent'
            Timestamp  = $record.TimeCreated
            Machine    = $record.MachineName
            User       = Get-WinEventRecordUser -Record $record
            Component  = 'MSI Installer'
            Action     = $configEventLog.Application.$recordId.Action
            Context    = ''
            Detail     = ''
            Source     = '/EventLog/Application/Record[@Id={0}]' -f $recordId
        }

        # Extract the product name from the event message, see this example:
        # Product: My Product -- Installation completed successfully.
        $event.Context = $record.Properties[0].Value
        $event.Context = $event.Context.Substring($event.Context.IndexOf(': ') + 2)
        $event.Context = $event.Context.Substring(0, $event.Context.LastIndexOf(' -- '))

        Write-Output $event
    }
}
