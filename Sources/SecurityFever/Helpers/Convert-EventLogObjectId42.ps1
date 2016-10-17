
function Convert-EventLogObjectId42
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        $Record,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Map
    )

    $activity = Convert-EventLogObject -Record $Record -Map $Map

    # Grab record properties
    $recordReason = $Record.Properties[2].Value

    # Set default values
    $activity.Reason = "Unknown ($recordReason)"

    # Populate the sleep reason
    switch ($recordReason)
    {
        0 { $activity.Reason = 'Button or Lid' }
        2 { $activity.Reason = 'Battery' }
        4 { $activity.Reason = 'Application API' }
        6 { $activity.Reason = 'Hibernate from Sleep - Fixed Timeout' }
        7 { $activity.Reason = 'System Idle' }
    }

    Write-Output $activity
}
