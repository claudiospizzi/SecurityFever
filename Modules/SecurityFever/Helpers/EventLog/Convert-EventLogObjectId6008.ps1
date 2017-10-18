
function Convert-EventLogObjectId6008
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

    try
    {
        $lrMark = [char]8206

        $time = $Record.Properties[0].Value
        $date = $Record.Properties[1].Value.Replace("$lrMark", "")

        $activity.TimeCreated = [DateTime]::Parse("$date $time")
    }
    catch
    {
        Write-Warning "TimeCreated value parsing error for event 6008: $_"
    }

    Write-Output $activity
}
