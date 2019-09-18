
function Convert-EventLogObjectId1074
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
    $recordType     = $Record.Properties[4].Value
    $recordUser     = $Record.Properties[6].Value
    $recordComputer = $Record.Properties[1].Value
    $recordProcess  = $Record.Properties[0].Value
    $recordReason   = $Record.Properties[2].Value
    $recordComment  = $Record.Properties[5].Value

    # Set default values
    $activity.Type     = $recordType
    $activity.Reason   = $recordReason
    $activity.Username = $recordUser
    $activity.Computer = $recordComputer
    $activity.Process  = $recordProcess
    $activity.Comment  = $recordComment

    Write-Output $activity
}
