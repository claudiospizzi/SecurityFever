<#
    .SYNOPSIS
        Get all audit events around the user sessions on the local system.

    .DESCRIPTION
        This function will show all user setting audit events by parsing the
        Security event log:
        - 4624: An account was successfully logged on
        - 4625: An account failed to log on
        - 4634: An account was logged off
        - 4647: User initiated logoff

    .INPUTS
        None.

    .OUTPUTS
        SecurityFever.SystemAudit.Event.

    .EXAMPLE
        PS C:\> Get-SystemAuditUserSession
        Get the local user session system audit events.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-SystemAuditUserSession
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

    Test-AdministratorRole -Throw

    Show-SystemAuditEventLogWarning -LogName 'Security' -DayPeriod $DayPeriod -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditPolicyWarning -Category 'Logon/Logoff' -Subcategory 'Logon' -Setting 'Success' -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditPolicyWarning -Category 'Logon/Logoff' -Subcategory 'Logon' -Setting 'Failure' -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditPolicyWarning -Category 'Logon/Logoff' -Subcategory 'Logoff' -Setting 'Success' -HideWarning:$HideWarning.IsPresent

    $configEventLog = Get-Content -Path "$Script:ConfigurationPath\SystemAudit.EventLog.json" | ConvertFrom-Json

    # Get all relevant event log records for user session events
    $records = Get-WinEventAdvanced -LogName 'Security' -EventId 4624, 4625, 4637, 4647 -ProviderName 'Microsoft-Windows-Security-Auditing' -DayPeriod $DayPeriod

    foreach ($record in $records)
    {
        $recordId = $record.Id

        # Skip records if not extended (part 1)
        if (-not $Extended.IsPresent -and $recordId -eq 4647)
        {
            continue
        }

        $auditEvent = [PSCustomObject] @{
            PSTypeName  = 'SecurityFever.SystemAudit.Event'
            Timestamp   = $record.TimeCreated
            Machine     = $record.MachineName
            User        = Get-WinEventRecordUser -Record $record
            Component   = 'User Session'
            Action      = $configEventLog.Events.Security.$recordId.Action
            Context     = ''
            Detail      = ''
            SourcePath  = '/EventLog/Security/Record[@Id={0}]' -f $recordId
            SourceEvent = $record
        }

        # Get record properties
        $recordProperties = Get-WinEventRecordProperty -Record $record -PropertyName $configEventLog.Events.Security.$recordId.Properties

        # Extract the subject to logon
        if ($recordProperties.PSObject.Properties.Name -contains 'TargetUserName' -and
            $recordProperties.TargetUserName -ne '-')
        {
            $auditEvent.User = ('{0}\{1}' -f $recordProperties.TargetDomainName, $recordProperties.TargetUserName).Trim('\-')
        }

        # Extract the logon type
        if ($recordProperties.PSObject.Properties.Name -contains 'LogonType' -and
            $recordProperties.LogonType -ne '-')
        {
            $logonType = $recordProperties.LogonType

            if ($configEventLog.Enumerations.LogonType.PSObject.Properties.Name -contains $logonType)
            {
                $auditEvent.Context = $configEventLog.Enumerations.LogonType.$logonType
            }
        }

        # Extract the logon requester
        if ($recordProperties.PSObject.Properties.Name -contains 'SubjectUserName' -and
            $recordProperties.SubjectUserName -ne '-')
        {
            $auditEvent.Detail += 'Requester: {0}, ' -f ('{0}\{1}' -f $recordProperties.SubjectDomainName, $recordProperties.SubjectUserName).Trim('\-')
        }

        # Extract the failure code message
        if ($recordProperties.PSObject.Properties.Name -contains 'Status')
        {
            $failureCode = '0x{0:X8}' -f $recordProperties.Status

            if ($configEventLog.Enumerations.FailureCode.PSObject.Properties.Name -contains $failureCode)
            {
                $auditEvent.Detail += 'Status: {0}, ' -f $configEventLog.Enumerations.FailureCode.$failureCode
            }
        }
        if ($recordProperties.PSObject.Properties.Name -contains 'SubStatus')
        {
            $failureCode = '0x{0:X8}' -f $recordProperties.SubStatus

            if ($configEventLog.Enumerations.FailureCode.PSObject.Properties.Name -contains $failureCode)
            {
                $auditEvent.Detail += 'SubStatus: {0}, ' -f $configEventLog.Enumerations.FailureCode.$failureCode
            }
        }

        # Fix the detail string
        $auditEvent.Detail += 'Auth: {0}, ' -f $recordProperties.AuthenticationPackageName

        # Extract the source process
        if ($recordProperties.PSObject.Properties.Name -contains 'ProcessName' -and
            $recordProperties.ProcessName -ne '-')
        {
            $auditEvent.Detail += 'Process: {0}, ' -f $recordProperties.ProcessName
        }

        # Extract the source pc name
        if ($recordProperties.PSObject.Properties.Name -contains 'WorkstationName' -and
            $recordProperties.WorkstationName -ne '-')
        {
            $auditEvent.Detail += 'Source PC: {0}, ' -f $recordProperties.WorkstationName
        }

        # Extract the source ip address
        if ($recordProperties.PSObject.Properties.Name -contains 'IpAddress' -and
            $recordProperties.IpAddress -ne '-')
        {
            $auditEvent.Detail += 'Source IP: {0}:{1}, ' -f $recordProperties.IpAddress, $recordProperties.IpPort
        }

        # Skip records if not extended (part 2)
        if (-not $Extended.IsPresent -and $recordId -eq 4624 -and $auditEvent.Context -notin 'Interactive', 'RemoteInteractive')
        {
            continue
        }

        # Optimize object
        $auditEvent.Detail = $auditEvent.Detail.TrimEnd(', ')

        Write-Output $auditEvent
    }
}
