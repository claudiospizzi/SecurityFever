<#
    .SYNOPSIS


    .DESCRIPTION


    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    PS C:\>


    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/SecurityFever
#>

function Get-SecurityActivity
{
    [CmdletBinding()]
    param
    (
        # Define the activity action(s).
        [Parameter(Mandatory = $false)]
        [ValidateSet('Startup', 'Shutdown', 'Logon', 'Logoff')]
        [System.String[]]
        $Type
    )

    # The Security event log is protected, therefore the cmdlet need elevated
    # permission. Verify if the current session is startet as administrator.
    if (-not (Test-AdministratorRole))
    {
        throw 'Access denied. Please start this functions as an administrator.'
    }

    # Static event log map to get the event log id's for each action type.
    $eventLogSystemMap = @{
        Startup  = @(
            6005,            # The Event log service was started.
            6009             # Microsoft (R) Windows (R) <Version>. <Build> Multiprocessor Free.
        )
        Shutdown = @(
            6006,            # The Event log service was stopped.
            6008,            # The previous system shutdown at 16:19:09 on ‎22.‎09.‎2016 was unexpected.
            1074             # The process <Process> has initiated the power off of computer <Computer> on behalf of user <Domain>\<User> for the following reason: ...
        )
        Logon    = @()
        Logoff   = @()
    }
    $eventLogSecurityMap = @{
        Startup  = @(
            4608             # Windows is starting up.

        )
        Shutdown = @()
        Logon    = @(
            4624,             # An account was successfully logged on.
            4625              # An account failed to log on.
        )
        Logoff   = @(
            4634,            # An account was logged off.
            4647             # User initiated logoff.
        )
    }

    # TODO: 'SessionReconnected', 'SessionDisconnected', 'WorkstationLocked', 'WorkstationUnlocked', 'ScreensaverInvoked', 'ScreensaverDismissed'
    # SessionReconnected   = 4778
    # SessionDisconnected  = 4779
    # WorkstationLocked    = 4800
    # WorkstationUnlocked  = 4801
    # ScreensaverInvoked   = 4802
    # ScreensaverDismissed = 4803

    # If no type is specified, initialize the input with all possible types.
    if ($null -eq $Type -or $Type.Count -eq 0)
    {
        $Type = $eventLogSystemMap.Keys
    }

    # Warning messages, if the audit policy is disabled for the requested type.
    if ($Type -contains 'Startup')
    {
        if(-not (Get-SecurityAuditPolicySetting -Category 'System' -Subcategory 'Security State Change' -Setting 'Success'))
        {
            Write-Warning "System audit policy for 'System' > 'Security State Change' > 'Success' is not enabled."
        }
    }
    if ($Type -contains 'Logon')
    {
        if(-not (Get-SecurityAuditPolicySetting -Category 'Logon/Logoff' -Subcategory 'Logon' -Setting 'Success'))
        {
            Write-Warning "System audit policy for 'Logon/Logoff' > 'Logon' > 'Success' is not enabled."
        }
        if(-not (Get-SecurityAuditPolicySetting -Category 'Logon/Logoff' -Subcategory 'Logon' -Setting 'Failure'))
        {
            Write-Warning "System audit policy for 'Logon/Logoff' > 'Logon' > 'Failure' is not enabled."
        }
    }
    if ($Type -contains 'Logoff')
    {
        if(-not (Get-SecurityAuditPolicySetting -Category 'Logon/Logoff' -Subcategory 'Logoff' -Setting 'Success'))
        {
            Write-Warning "System audit policy for 'Logon/Logoff' > 'Logoff' > 'Success' is not enabled."
        }
    }

    # Create event log queries
    $eventLogSystemIds   = @()
    $eventLogSecurityIds = @()
    foreach ($currentType in $Type)
    {
        $eventLogSystemIds   += $eventLogSystemMap[$currentType]
        $eventLogSecurityIds += $eventLogSecurityMap[$currentType]
    }

    $eventLogSystemIds.Count
    $eventLogSecurityIds.Count
}
