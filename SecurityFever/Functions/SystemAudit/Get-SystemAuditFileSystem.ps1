<#
    .SYNOPSIS
        Get all audit events of the file system.

    .DESCRIPTION
        This function will show all file system audit event logs. This is only
        the security event with id 4663.

    .INPUTS
        None.

    .OUTPUTS
        SecurityFever.SystemAudit.Event.

    .EXAMPLE
        PS C:\> Get-SystemAuditFileSystem
        Get the local file system audit events.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-SystemAuditFileSystem
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

    Test-AdministratorRole -Throw

    Show-SystemAuditEventLogWarning -LogName 'Security' -DayPeriod $DayPeriod -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditPolicyWarning -Category 'Object Access' -Subcategory 'File System' -Setting 'Success' -HideWarning:$HideWarning.IsPresent

    # Get all relevant event log records for the file system
    $filter = New-WinEventFilterXml -LogName 'Security' -EventId 4663 -NotBefore ([System.DateTime]::Now.AddDays(-1 * $DayPeriod))
    try
    {
        $records = Get-WinEvent -FilterXml $filter -ErrorAction 'Stop'
    }
    catch
    {
        if ($_.Exception.Message -ne 'No events were found that match the specified selection criteria.')
        {
            throw $_
        }
        else
        {
            $records = @()
        }
    }

    foreach ($record in $records)
    {
        $recordId = $record.Id

        # Reference:
        # https://system32.eventsentry.com/security/event/4663
        # https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/event-4663

        # We need to split the access because it can contain multiple
        # values like '%%4417 %%4418', for such cases, we just return
        # multiple event object.
        $accessList = [System.String] $record.Properties[8].Value
        $accessList = $accessList.Split("`n ")
        foreach ($access in $accessList)
        {
            $access = $access.Trim()
            if ([System.String]::IsNullOrEmpty($access))
            {
                continue
            }

            switch ($access)
            {
                '%%4416' { $access = 'ReadData / ListDirectory' }
                '%%4417' { $access = 'WriteData / AddFile' }
                '%%4418' { $access = 'AppendData / AddSubdirectory / CreatePipeInstance' }
                '%%4419' { $access = 'ReadExtendedAttributes' }
                '%%4420' { $access = 'WriteExtendedAttributes' }
                '%%4421' { $access = 'Execute/Traverse' }
                '%%4422' { $access = 'DeleteChild' }
                '%%4423' { $access = 'ReadAttributes' }
                '%%4424' { $access = 'WriteAttributes' }
                '%%1537' { $access = 'Delete' }
                '%%1538' { $access = 'ReadAccessControl' }
                '%%1539' { $access = 'WriteAccessControl' }
                '%%1540' { $access = 'WriteOwner' }
                '%%1541' { $access = 'Synchronize' }
                '%%1542' { $access = 'AccessSysSec' }
                default  { Write-Warning "Access definition for '$access' not found." }
            }

            # Create a usable event by parsing the properties. But most of the
            # properties are currently not in use:
            # SubjectUserSid (0) = S-1-5-...
            # SubjectLogonId (3) = 0x12345678
            # ObjectServer (4) = Security
            # ObjectType (5) = File
            # ObjectName (6) =
            # HandleId (7) = 0x12345
            # AccessMask (9) = 0x1
            # ProcessId (10) = 12345
            # ProcessName (11) = C:\Windows\explorer.exe
            # ResourceAttributes (12) = S:AI
            $auditEvent = [PSCustomObject] @{
                PSTypeName  = 'SecurityFever.SystemAudit.Event'
                Timestamp   = $record.TimeCreated
                Machine     = $record.MachineName
                User        = Get-WinEventRecordUser -Record $record
                Component   = 'File System'
                Action      = $access
                Context     = [System.String] $record.Properties[6].Value
                Detail      = 'Subject: {0}\{1}' -f $record.Properties[2].Value, $record.Properties[1].Value
                SourcePath  = '/EventLog/Security/Record[@Id={0}]' -f $recordId
                SourceEvent = $record
            }

            Write-Output $auditEvent
        }
    }
}
