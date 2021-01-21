<#
    .SYNOPSIS
        Get the security audit events for the file system.

    .DESCRIPTION
        Read the Security Event log to get all audit events related for file
        system changes. Currently only event id 4663.

    .OUTPUTS
        SecurityFever.Audit.FileSystem.Event. File system audit event.

    .EXAMPLE
        PS C:\> Get-SecurityAuditFileSystem
        Get all file system audit events on the local system.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-SecurityAuditFileSystem
{
    [CmdletBinding()]
    param ()

    $filter = '<QueryList>' +
              '    <Query Id="0" Path="Security">' +
              '        <Select Path="Security">*[System[(EventID=4663)]]</Select>' +
              '    </Query>' +
              '</QueryList>'

    $events = Get-WinEvent -FilterXml $filter -ErrorAction 'Stop'

    foreach ($event in $events)
    {
        # Reference:
        # https://system32.eventsentry.com/security/event/4663
        # https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/event-4663
        $access = [System.String] $event.Properties[8].Value
        $access = $access.Trim()
        switch ($access)
        {
            '%%4416' { $access = 'ReadData / ListDirectory' } # 0x1
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
        }

        [PSCustomObject] @{
            PSTypeName = 'SecurityFever.Audit.FileSystem.Event'
            Subject    = '{0}\{1}' -f $event.Properties[2].Value, $event.Properties[1].Value
            Object     = [System.String] $event.Properties[6].Value
            Access     = $access
        }

        # Not used properties:
        # SubjectUserSid (0) = S-1-5-...
        # SubjectLogonId (3) = 0x12345678
        # ObjectServer (4) = Security
        # ObjectType (5) = File
        # HandleId (7) = 0x12345
        # AccessMask (9) = 0x1
        # ProcessId (10) = 12345
        # ProcessName (11) = C:\Windows\explorer.exe
        # ResourceAttributes (12) = S:AI
    }
}
