<#
    .SYNOPSIS
        Adapter for the Get-WinEvent function easier to use.
#>
function Get-WinEventAdvanced
{
    [CmdletBinding()]
    param
    (
        # Event log name.
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        # Event id list to filter.
        [Parameter(Mandatory = $true)]
        [System.Int32[]]
        $EventId,

        # Time range when to start.
        [Parameter(Mandatory = $true)]
        [System.DateTime]
        $From
    )

    # Create the event id filter: EventId=1 or EventId=3
    $filterEventId = ($EventId | ForEach-Object { "EventID=$_" }) -join ' or '

    # Create the start time filter: TimeCreated[@SystemTime>='2010-12-26T14:10:15.000Z']]
    $filterStartTime = "TimeCreated[@SystemTime&gt;='{0:yyyy-MM-dd\Thh\:mm\:ss.fff\Z}']]" -f $From.ToUniversalTime()

    # Combine the filters with an and
    $filterQuery = "*[System[({0}) and {1}]" -f $filterEventId, $filterStartTime

    # Invoke the query with the filter
    $filterXml = '<QueryList><Query Id="0" Path="{0}"><Select Path="{0}">{1}</Select></Query></QueryList>' -f $logName, $filterQuery
    Get-WinEvent -FilterXml $filterXml
}
