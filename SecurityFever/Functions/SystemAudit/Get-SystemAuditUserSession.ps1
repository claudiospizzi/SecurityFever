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

        $event = [PSCustomObject] @{
            PSTypeName = 'SecurityFever.SystemAuditEvent'
            Timestamp  = $record.TimeCreated
            Machine    = $record.MachineName
            User       = Get-WinEventRecordUser -Record $record
            Component  = 'User Session'
            Action     = $configEventLog.Security.$recordId.Action
            Context    = ''
            Detail     = ''
            Source     = '/EventLog/Security/Record[@Id={0}]' -f $recordId
        }

        # Get record properties
        $recordProperties = Get-WinEventRecordProperty -Record $record -PropertyName $configEventLog.Security.$recordId.Properties

        # Extract the subject to logon
        if ($recordProperties.PSObject.Properties.Name -contains 'TargetUserName' -and
            $recordProperties.TargetUserName -ne '-')
        {
            $event.User = ('{0}\{1}' -f $recordProperties.TargetDomainName, $recordProperties.TargetUserName).Trim('\-')
        }

        # Extract the logon type
        if ($recordProperties.PSObject.Properties.Name -contains 'LogonType' -and
            $recordProperties.LogonType -ne '-')
        {
            $logonType = $recordProperties.LogonType

            if ($configEventLog.Security.LogonType.PSObject.Properties.Name -contains $logonType)
            {
                $event.Context = $configEventLog.Security.LogonType.$logonType
            }
        }

        # Extract the logon requester
        if ($recordProperties.PSObject.Properties.Name -contains 'SubjectUserName' -and
            $recordProperties.SubjectUserName -ne '-')
        {
            $event.Detail += 'Requester: {0}, ' -f ('{0}\{1}' -f $recordProperties.SubjectDomainName, $recordProperties.SubjectUserName).Trim('\-')
        }

        # Extract the failure code message
        if ($recordProperties.PSObject.Properties.Name -contains 'Status')
        {
            $failureCode = '0x{0:X8}' -f $recordProperties.Status

            if ($configEventLog.Security.FailureCode.PSObject.Properties.Name -contains $failureCode)
            {
                $event.Detail += 'Status: {0}, ' -f $configEventLog.Security.FailureCode.$failureCode
            }
        }
        if ($recordProperties.PSObject.Properties.Name -contains 'SubStatus')
        {
            $failureCode = '0x{0:X8}' -f $recordProperties.SubStatus

            if ($configEventLog.Security.FailureCode.PSObject.Properties.Name -contains $failureCode)
            {
                $event.Detail += 'SubStatus: {0}, ' -f $configEventLog.Security.FailureCode.$failureCode
            }
        }

        # Fix the detail string
        $event.Detail += 'Auth: {0}, ' -f $recordProperties.AuthenticationPackageName

        # Extract the source process
        if ($recordProperties.PSObject.Properties.Name -contains 'ProcessName' -and
            $recordProperties.ProcessName -ne '-')
        {
            $event.Detail += 'Process: {0}, ' -f $recordProperties.ProcessName
        }

        # Extract the source pc name
        if ($recordProperties.PSObject.Properties.Name -contains 'WorkstationName' -and
            $recordProperties.WorkstationName -ne '-')
        {
            $event.Detail += 'Source PC: {0}, ' -f $recordProperties.WorkstationName
        }

        # Extract the source ip address
        if ($recordProperties.PSObject.Properties.Name -contains 'IpAddress' -and
            $recordProperties.IpAddress -ne '-')
        {
            $event.Detail += 'Source IP: {0}:{1}, ' -f $recordProperties.IpAddress, $recordProperties.IpPort
        }

        # Skip records if not extended (part 2)
        if (-not $Extended.IsPresent -and $recordId -eq 4624 -and $event.Context -notin 'Interactive', 'RemoteInteractive')
        {
            continue
        }

        # Optimize object
        $event.Detail = $event.Detail.TrimEnd(', ')

        Write-Output $event
    }
}
