
function Convert-EventLogObjectId4647
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
    $recordUser     = $Record.Properties[2].Value + '\' + $Record.Properties[1].Value

    # Set default values
    $activity.Username     = $recordUser

    Write-Output $activity
}
