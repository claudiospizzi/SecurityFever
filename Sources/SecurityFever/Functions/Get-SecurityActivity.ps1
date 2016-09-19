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
        [ValidateSet('Startup', 'Shutdown',
                     'Logon', 'Logoff', 'LogoffInit',
                     'SessionReconnected', 'SessionDisconnected',
                     'WorkstationLocked', 'WorkstationUnlocked',
                     'ScreensaverInvoked', 'ScreensaverDismissed')]
        [System.String]
        $Type
    )

    # The Security event log is protected, therefore the cmdlet need elevated
    # permission, verify if the current session is startet as administrator.
    if (-not (Test-AdministratorRole))
    {
        throw 'Access denied. Please start this functions as an administrator.'
    }

    # Static event log map to get the event log id's for each action type.
    $EventLogMap = @{
        Startup              = 4608
        Shutdown             = 4609 # 4609 / 1100
        Logon                = 4624
        Logoff               = 4634
        LogoffInit           = 4647
        SessionReconnected   = 4778
        SessionDisconnected  = 4779
        WorkstationLocked    = 4800
        WorkstationUnlocked  = 4801
        ScreensaverInvoked   = 4802
        ScreensaverDismissed = 4803
    }

    # If no type is specified, initialize the input with all possible types.
    if ($null -eq $Type -or $Type.Count -eq 0)
    {
        $Type = $EventLogMap.Keys
    }

    # Warning messages, if the audit policy is disabled for the requested type.

}
