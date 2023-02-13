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

        # Provider names to filter.
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ProviderName,

        # Period of days to cover.
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $DayPeriod
    )

    # Convert the provider name array to the required filter query
    $filterProviderName = 'Provider[{0}]' -f [System.String]::Join(' or ', $ProviderName.ForEach({ "@Name='$_'" }))

    # Convert the event id array to the required filter query
    $filterEventId = '({0})' -f [System.String]::Join(' or ', $EventId.ForEach({ "EventID=$_" }))

    # Convert the day period number to the required time create filter query
    $filterTimeCreated = "TimeCreated[@SystemTime&gt;='{0:yyyy-MM-dd\Thh\:mm\:ss.fff\Z}']" -f [DateTime]::UtcNow.AddDays(-1 * $DayPeriod)

    # Invoke the query with the filter
    $filterXml = '<QueryList><Query Id="0" Path="{0}"><Select Path="{0}">*[System[{1} and {2} and {3}]]</Select></Query></QueryList>' -f $LogName, $filterProviderName, $filterEventId, $filterTimeCreated

    try
    {
        Get-WinEvent -FilterXml $filterXml -ErrorAction 'Stop'
    }
    catch
    {
        if ($_.Exception.Message -ne 'No events were found that match the specified selection criteria.')
        {
            throw $_
        }
    }
}
