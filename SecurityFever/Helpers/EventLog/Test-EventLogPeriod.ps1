<#
    .SYNOPSIS
        Test if the oldest record does cover the period. Throw warnings if not.
        Return the period start timestamp.
#>
function Test-EventLogPeriod
{
    [CmdletBinding()]
    param
    (
        # The event log name.
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        # Period of days to report for the audit events.
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $Period,

        # Hide the warning message.
        [Parameter(Mandatory = $false)]
        [Switch]
        $HideWarning
    )

    $periodStart = [System.DateTime]::Now.AddDays(-1 * $Period)

    $oldestEvent = Get-WinEvent -LogName $LogName -MaxEvents 1 -Oldest

    if ($oldestEvent.TimeCreated -gt $periodStart)
    {
        if (-not $HideWarning.IsPresent)
        {
            Write-Warning ("$LogName event log entry starts at {0:dd\.MM\.yyyy hh\:mm\:ss}, deviates {1:d\.hh\:mm\:ss} " -f $oldestEvent.TimeCreated, ($oldestEvent.TimeCreated - $periodStart))
        }

        Write-Output $oldestEvent.TimeCreated
    }
    else
    {
        Write-Output $periodStart
    }
}
