
function Convert-EventLogObjectId4624
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
    $recordType     = $Record.Properties[8].Value.ToString().Trim()
    $recordUser     = $Record.Properties[6].Value + '\' + $Record.Properties[5].Value
    $recordComputer = $Record.Properties[11].Value
    $recordProcess  = $Record.Properties[9].Value.Trim()
    $recordAuth     = $Record.Properties[10].Value
    $recordAuth2    = $Record.Properties[14].Value

    # Set default values
    $activity.Type         = "Unknown ($recordType)"
    $activity.Username     = $recordUser
    $activity.Computer     = $recordComputer
    $activity.Process      = $recordProcess
    $activity.Comment      = "$recordAuth ($recordAuth2)"

    # Populate the type
    if ($typeMap.ContainsKey($recordType))
    {
        $activity.Type = $typeMap[$recordType]
    }

    # Cleanup comment
    $activity.Comment = $activity.Comment.Replace(' (-)', '')

    Write-Output $activity
}
