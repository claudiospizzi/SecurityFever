
function Convert-EventLogObjectId1
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
    $recordReason = $Record.Properties[12].Value

    # Set default values
    $activity.Reason = "Unknown ($recordReason)"

    # Populate the awake source
    switch ($recordReason)
    {
        1 { $activity.Reason = 'Power Button' }
        3 { $activity.Reason = 'S4 Doze to Hibernate' }
        5 { $activity.Reason = 'Device - ACPI Lid' }
    }

    Write-Output $activity
}
