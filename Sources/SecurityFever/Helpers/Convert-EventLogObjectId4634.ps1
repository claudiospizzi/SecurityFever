
function Convert-EventLogObjectId4634
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

    # Definition: Types
    $typeMap = @{
        '2'  = 'Interactive'
        '3'  = 'Network'
        '4'  = 'Batch'
        '5'  = 'Service'
        '7'  = 'Unlock'
        '8'  = 'NetworkCleartext'
        '9'  = 'NewCredentials'
        '10' = 'RemoteInteractive'
        '11' = 'CachedInteractive'
    }

    $activity = Convert-EventLogObject -Record $Record -Map $Map

    # Grab record properties
    $recordType     = $Record.Properties[4].Value.ToString().Trim()
    $recordUser     = $Record.Properties[2].Value + '\' + $Record.Properties[1].Value

    # Set default values
    $activity.Type         = "Unknown ($recordType)"
    $activity.Username     = $recordUser

    # Populate the type
    if ($typeMap.ContainsKey($recordType))
    {
        $activity.Type = $typeMap[$recordType]
    }

    Write-Output $activity
}
