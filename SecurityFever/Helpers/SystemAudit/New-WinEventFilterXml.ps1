<#
    .SYNOPSIS
        Create a XML filter to be used with the Get-WinEvent command.

    .DESCRIPTION
        The filter will be created by the provided parameers. Only parameter
        specified are included in the filter.

    .OUTPUTS
        System.String. XML filter.

    .EXAMPLE
        PS C:\> New-WinEventFilterXml -LogName 'Security'
        Filter for all events in the Security log.

    .EXAMPLE
        PS C:\> New-WinEventFilterXml -LogName 'Application' -Provider 'MsiInstaller' -Level 'Critical', 'Error', 'Warning' -EventId 11707, 11708, 11724, 11725, 11728, 11729 -NotBefore (Get-Date).AddDays(-7)
        Filter for all MSI events indicating a problem in the last 7 days.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function New-WinEventFilterXml
{
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        # Event log name.
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        # Filter by provider name.
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [System.String[]]
        $Provider,

        # Filter by log level.
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [ValidateSet('Critical', 'Error', 'Warning', 'Information', 'Verbose')]
        [System.String[]]
        $Level,

        # Filter by event id.
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [System.Int32[]]
        $EventId,

        # Filter the events by creation time, but not before the specified
        # DateTime.
        [Alias('From')]
        [Nullable[System.DateTime]]
        $NotBefore,

        # Filter the events by creation time, but not after the specified
        # DateTime.
        [Alias('To')]
        [Nullable[System.DateTime]]
        $NotAfter
    )

    $select = @()

    # Filter by the provider name. The select looks like this:
    # Provider[@Name='MYPROVIDER' or @Name='Microsoft-Windows-ImportantService']
    if ($PSBoundParameters.ContainsKey('Provider') -and $Provider.Count -gt 0)
    {
        $selectProvider = @()
        foreach ($providerName in $Provider)
        {
            $selectProvider += '@Name=''{0}''' -f $providerName
        }
        $select += 'Provider[{0}]' -f ($selectProvider -join ' or ')
    }

    # Filter by the log level. The command accepts the string representation of
    # the level, this is converted to it's numbers:
    # (Level=1 or Level=2)
    if ($PSBoundParameters.ContainsKey('Level') -and $Level.Count -gt 0)
    {
        $selectLevel = @()
        foreach ($levelName in $Level)
        {
            switch ($levelName)
            {
                'Critical'    { $selectLevel += 'Level=1' }
                'Error'       { $selectLevel += 'Level=2' }
                'Warning'     { $selectLevel += 'Level=3' }
                'Information' { $selectLevel += 'Level=4 or Level=0' }
                'Verbose'     { $selectLevel += 'Level=5' }
            }
        }
        $select += '({0})' -f ($selectLevel -join ' or ')
    }

    # Filter by the event id numbers like this:
    # (EventID=12345 or EventID=999)
    if ($PSBoundParameters.ContainsKey('EventId') -and $EventId.Count -gt 0)
    {
        $selectEventId = @()
        foreach ($eventIdNumber in $EventId)
        {
            $selectEventId += 'EventID={0}' -f $eventIdNumber
        }
        $select += '({0})' -f ($selectEventId -join ' or ')
    }

    # Filter by the created time, can be specified with not before (From) until
    # not after (To):
    # TimeCreated[@SystemTime&gt;='2021-01-01T00:00:00.000Z' and @SystemTime&lt;='2021-12-31T23:59:59.999Z']
    if (($PSBoundParameters.ContainsKey('NotBefore') -and $NotBefore.HasValue) -or
        ($PSBoundParameters.ContainsKey('NotAfter') -and $NotAfter.HasValue))
    {
        $selectTimeCreated = @()
        if ($PSBoundParameters.ContainsKey('NotBefore') -and $NotBefore.HasValue)
        {
            $selectTimeCreated += '@SystemTime&gt;=''{0:yyyy-MM-ddTHH:mm:ss.fffZ}''' -f $NotBefore.Value.ToUniversalTime()
        }
        if ($PSBoundParameters.ContainsKey('NotAfter') -and $NotAfter.HasValue)
        {
            $selectTimeCreated += '@SystemTime&lt;=''{0:yyyy-MM-ddTHH:mm:ss.fffZ}''' -f $NotBefore.Value.ToUniversalTime()
        }
        $select += 'TimeCreated[{0}]' -f ($selectTimeCreated -join ' and ')
    }

    # Combine all selections into a single select where all parts must be
    # matched for the event to return.
    $select = $select -join ' and '

    $filter = '<QueryList><Query Id="0" Path="{0}"><Select Path="{0}">*[System[{1}]]</Select></Query></QueryList>' -f $LogName, $select

    return $filter
}
