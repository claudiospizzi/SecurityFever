<#
    .SYNOPSIS
        Test if the oldest record does cover the period. Throw warnings if not.
#>
function Show-SystemAuditEventLogWarning
{
    [CmdletBinding()]
    param
    (
        # The event log name.
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        # Period of days to cover.
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $DayPeriod,

        # Hide the warning messages, don't test the prerequisites.
        [Parameter(Mandatory = $false)]
        [Switch]
        $HideWarning
    )

    if ($HideWarning.IsPresent)
    {
        return
    }

    $oldestEvent = Get-WinEvent -LogName $LogName -MaxEvents 1 -Oldest
    $periodStart = [System.DateTime]::Now.AddDays(-1 * $DayPeriod)

    if ($oldestEvent.TimeCreated -gt $periodStart)
    {
        Write-Warning ('{0} event log entry starts at {1:dd\.MM\.yyyy hh\:mm\:ss}, deviates {2:d\.hh\:mm\:ss}' -f $LogName, $oldestEvent.TimeCreated, ($oldestEvent.TimeCreated - $periodStart))
    }
}
