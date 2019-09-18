<#
    .SYNOPSIS
        Show security relevant activities on a system.

    .DESCRIPTION
        Show security relevant activities on a system. This includes:
        - Startup / Shutdown
        - Awake / Sleep
        - Logon / Logoff

    .INPUTS
        None.

    .OUTPUTS
        SecurityFever.ActivityRecord. Array of custom activity records.

    .EXAMPLE
        PS C:\> Get-SecurityActivity
        Get all available security activity records on the system.

    .EXAMPLE
        PS C:\> Get-SecurityActivity -Activity Startup, Shutdown
        Get only the startup and shutdown activity records on the system.

    .EXAMPLE
        PS C:\> Get-SecurityActivity -Recommended
        Get all available security activity records on the system but show just
        the recommended records and hide verbose records.

    .EXAMPLE
        PS C:\> Get-SecurityActivity -ComputerName 'COMPUTER' -Credential 'DOMAIN\User'
        Get all security activity records on the remote system 'COMPUTER'.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-SecurityActivity
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Scope='Function', Target='Get-SecurityActivity')]
    [CmdletBinding(DefaultParameterSetName = 'Local')]
    param
    (
        # Define the activity action(s).
        [Parameter(Mandatory = $false)]
        [ValidateSet('Startup', 'Shutdown', 'Awake', 'Sleep', 'Logon', 'Logoff')]
        [System.String[]]
        $Activity,

        # Specify a remote computer to query.
        [Parameter(Mandatory = $true, ParameterSetName = 'Remote')]
        [System.String]
        $ComputerName,

        # Specify credentials for the remote computer.
        [Parameter(Mandatory = $false, ParameterSetName = 'Remote')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # Specify a time limit for the records.
        [Parameter(Mandatory = $false)]
        [System.DateTime]
        $After = ([DateTime]::MinValue),

        # Show only filtered recommended events.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]
        $Recommended
    )

    # The security event log is protected, therefore the cmdlet need elevated
    # permission. Verify if the current session is startet as administrator.
    if ($PSCmdlet.ParameterSetName -eq 'Local' -and -not (Test-AdministratorRole))
    {
        throw 'Access denied. Please start this functions as an administrator.'
    }

    # If no activity is specified, initialize the input with all possible
    # activities.
    if ($null -eq $Activity -or $Activity.Count -eq 0)
    {
        $Activity = (Get-Command -Name 'Get-SecurityActivity').Parameters['Activity'].Attributes.ValidValues
    }

    # Static event log map to get the event log id's for each activity.
    $eventLogMap = @{
        4608 = @{ Activity = 'Startup';  Log = 'Security'; Event  = 'LSASS Started'       }   # Windows is starting up.
        6005 = @{ Activity = 'Startup';  Log = 'System';   Event  = 'Event Log Started'   }   # The Event log service was started.
        6009 = @{ Activity = 'Startup';  Log = 'System';   Event  = 'OS Initialization'   }   # Microsoft (R) Windows (R) <Version>. <Build> Multiprocessor Free.

        1074 = @{ Activity = 'Shutdown'; Log = 'System';   Event  = 'Requested Shutdown'  }   # The process <Process> has initiated the power off of computer <Computer> on behalf of user <Domain>\<User> for the following reason: ...
        6006 = @{ Activity = 'Shutdown'; Log = 'System';   Event  = 'Event Log Stopped'   }   # The Event log service was stopped.
        6008 = @{ Activity = 'Shutdown'; Log = 'System';   Event  = 'Unexpected Shutdown' }   # The previous system shutdown at <Time> on <Date> was unexpected.

        1    = @{ Activity = 'Awake';    Log = 'System';   Event  = 'Leaving Sleep'       }   # The system has returned from a low power state.

        42   = @{ Activity = 'Sleep';    Log = 'System';   Event  = 'Entering Sleep'      }   # The system is entering sleep.

        4624 = @{ Activity = 'Logon';    Log = 'Security'; Event  = 'Logon Successful'    }   # An account was successfully logged on.
        4625 = @{ Activity = 'Logon';    Log = 'Security'; Event  = 'Logon Failed'        }   # An account failed to log on.

        4634 = @{ Activity = 'Logoff';   Log = 'Security'; Event  = 'Logoff Successful'   }   # An account was logged off.
        4647 = @{ Activity = 'Logoff';   Log = 'Security'; Event  = 'Logoff Request'      }   # User initiated logoff.

        # 4648 = @{ Activity = 'Logon'                }   # A logon was attempted using explicit credentials
        # 4778 = @{ Activity = 'SessionReconnected'   }
        # 4779 = @{ Activity = 'SessionDisconnected'  }
        # 4800 = @{ Activity = 'WorkstationLocked'    }
        # 4801 = @{ Activity = 'WorkstationUnlocked'  }
        # 4802 = @{ Activity = 'ScreensaverInvoked'   }
        # 4803 = @{ Activity = 'ScreensaverDismissed' }
    }

    # Warning messages, if the audit policy is disabled for the requested
    # activity.
    if ($PSCmdlet.ParameterSetName -eq 'Local')
    {
        if ($Activity -contains 'Startup')
        {
            if(-not (Get-SecurityAuditPolicySetting -Category 'System' -Subcategory 'Security State Change' -Setting 'Success'))
            {
                Write-Warning "System audit policy for 'System' > 'Security State Change' > 'Success' is not enabled."
            }
        }
        if ($Activity -contains 'Logon')
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
        if ($Activity -contains 'Logoff')
        {
            if(-not (Get-SecurityAuditPolicySetting -Category 'Logon/Logoff' -Subcategory 'Logoff' -Setting 'Success'))
            {
                Write-Warning "System audit policy for 'Logon/Logoff' > 'Logoff' > 'Success' is not enabled."
            }
        }
    }
    if ($PSCmdlet.ParameterSetName -eq 'Remote')
    {
        Write-Warning "Unable to verify the audit policy settings for $ComputerName."
    }

    # Build the xml filter to query the system and security log.
    $filterSystem   = ''
    $filterSecurity = ''
    $filterSystemIds   = $eventLogMap.GetEnumerator() | Where-Object { $_.Value.Activity -in $Activity -and $_.Value.Log -eq 'System' } | ForEach-Object Name
    $filterSecurityIds = $eventLogMap.GetEnumerator() | Where-Object { $_.Value.Activity -in $Activity -and $_.Value.Log -eq 'Security' } | ForEach-Object Name
    if ($filterSystemIds.Count -gt 0)
    {
        $filterSystem = '<Select Path="System">*[System[(({0}) and TimeCreated[@SystemTime&gt;=''{1}''])]]</Select>' -f ([String]::Join(' or ', ($filterSystemIds | ForEach-Object { "EventID=$_" }))), $After.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    }
    if ($filterSecurityIds.Count -gt 0)
    {
        $filterSecurity = '<Select Path="Security">*[System[(({0}) and TimeCreated[@SystemTime&gt;=''{1}''])]]</Select>' -f ([String]::Join(' or ', ($filterSecurityIds | ForEach-Object { "EventID=$_" }))), $After.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    }
    $filter = '<QueryList><Query Id="0" Path="Security">{0}{1}</Query></QueryList>' -f $filterSystem, $filterSecurity

    # Execute query against local or remote system.
    if ($PSCmdlet.ParameterSetName -eq 'Local')
    {
        $events = Get-WinEvent -FilterXml $filter -ErrorAction Stop
    }
    if ($PSCmdlet.ParameterSetName -eq 'Remote')
    {
        $invokeCommandParam = @{
            ComputerName = $ComputerName
            ScriptBlock  = { param ($filter) Get-WinEvent -FilterXml $filter -ErrorAction Stop | Select-Object Id, MachineName, TimeCreated, Properties }
            ArgumentList = $filter
        }
        if ($null -ne $Credential)
        {
            $invokeCommandParam['Credential'] = $Credential
        }

        $events = Invoke-Command @invokeCommandParam -ErrorAction Stop
    }

    # Security activities
    $activities = @()

    foreach ($event in $events)
    {
        switch ($event.Id)
        {
            4608 { $activities += Convert-EventLogObject -Record $event -Map $eventLogMap }
            6005 { $activities += Convert-EventLogObject -Record $event -Map $eventLogMap }
            6009 { $activities += Convert-EventLogObject -Record $event -Map $eventLogMap }

            1074 { $activities += Convert-EventLogObjectId1074 -Record $event -Map $eventLogMap }
            6006 { $activities += Convert-EventLogObject -Record $event -Map $eventLogMap }
            6008 { $activities += Convert-EventLogObjectId6008 -Record $event -Map $eventLogMap }

            1    { if ($event.ProviderName -eq 'Microsoft-Windows-Power-Troubleshooter') { $activities += Convert-EventLogObjectId1 -Record $event -Map $eventLogMap } }

            42   { $activities += Convert-EventLogObjectId42 -Record $event -Map $eventLogMap }

            4624 { $activities += Convert-EventLogObjectId4624 -Record $event -Map $eventLogMap }
            4625 { $activities += Convert-EventLogObjectId4625 -Record $event -Map $eventLogMap }

            4634 { $activities += Convert-EventLogObjectId4634 -Record $event -Map $eventLogMap }
            4647 { $activities += Convert-EventLogObjectId4647 -Record $event -Map $eventLogMap }
        }
    }

    # Filter for recommended activities
    if ($Recommended.IsPresent)
    {
        $activities = $activities | Where-Object { -not (
            $_.Id -eq 6006 -or
            $_.Id -eq 6005 -or
            $_.Id -eq 4608 -or
            ($_.Id -eq 4624 -and 'Network', 'Batch', 'Service', 'Unlock', 'NetworkCleartext', 'NewCredentials' -contains $_.Type) -or
            ($_.Id -eq 4624 -and $_.Username -like 'Window Manager\DWM-*') -or
            ($_.Id -eq 4634 -and 'Network', 'Batch', 'Service', 'Unlock', 'NetworkCleartext', 'NewCredentials' -contains $_.Type) -or
            ($_.Id -eq 4634 -and $_.Username -like 'Window Manager\DWM-*')
        ) }
    }

    $activities | Sort-Object TimeCreated -Descending | Write-Output
}
