<#
    .SYNOPSIS
        Get the file system security audit events.

    .DESCRIPTION
        Read the Security event log to get all audit events related to the file
        system. This is currently only the event id 4663.

    .INPUTS
        None.

    .OUTPUTS
        SecurityFever.Audit.FileSystemEvent. File system audit event.

    .EXAMPLE
        PS C:\> Get-SecurityAuditFileSystem
        Get all file system audit events on the local system.

    .EXAMPLE
        PS C:\> Get-SecurityAuditFileSystem -NotBefore (Get-Date).AddDays(-1)
        Get all file system audit events within the last 24 hours on the local
        system.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-SecurityAuditFileSystem
{
    [CmdletBinding()]
    param
    (
        # Filter the event by time.
        [Parameter(Mandatory = $false)]
        [System.DateTime]
        $NotBefore,

        # Filter the event by time.
        [Parameter(Mandatory = $false)]
        [System.DateTime]
        $NotAfter
    )

    # Access to the Security event log requires Administrative privileges.
    Test-AdministratorRole -Throw

    $filter = New-WinEventFilterXml -LogName 'Security' -EventId 4663 -NotBefore $NotBefore -NotAfter $NotAfter
    $events = Get-WinEvent -FilterXml $filter -ErrorAction 'Stop'

    foreach ($event in $events)
    {
        try
        {
            # Reference:
            # https://system32.eventsentry.com/security/event/4663
            # https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/event-4663

            # We need to split the access because it can contain multiple
            # values like '%%4417 %%4418', for such cases, we just return
            # multiple event object.
            $accessList = [System.String] $event.Properties[8].Value
            $accessList = $accessList.Split("`n ")
            foreach ($access in $accessList)
            {
                $access = $access.Trim()
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
                    default  { throw "Access definition for $access not found." }
                }

                # Create a usable event by parsing the properties. But most of the
                # properties are currently not in use:
                # SubjectUserSid (0) = S-1-5-...
                # SubjectLogonId (3) = 0x12345678
                # ObjectServer (4) = Security
                # ObjectType (5) = File
                # HandleId (7) = 0x12345
                # AccessMask (9) = 0x1
                # ProcessId (10) = 12345
                # ProcessName (11) = C:\Windows\explorer.exe
                # ResourceAttributes (12) = S:AI
                [PSCustomObject] @{
                    PSTypeName = 'SecurityFever.Audit.FileSystemEvent'
                    Timestamp  = $event.TimeCreated
                    Subject    = '{0}\{1}' -f $event.Properties[2].Value, $event.Properties[1].Value
                    Access     = $access
                    Object     = [System.String] $event.Properties[6].Value
                }
            }
        }
        catch
        {
            Write-Warning "Failed to parse event $($event.Id) at $($event.TimeCreated): $_"
        }
    }
}
