
function Convert-EventLogObject
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

    $activity = New-Object -TypeName PSObject -Property @{
        ComputerName = $Record.MachineName.Split('.')[0]
        TimeCreated  = $Record.TimeCreated
        Id           = $Record.Id
        Activity     = $Map[$Record.Id].Activity
        Event        = $Map[$Record.Id].Event
        Type         = ''
        Reason       = ''
        Username     = ''
        Computer     = ''
        Process      = ''
        Comment      = ''
    }

    $activity.PSTypeNames.Insert(0, 'SecurityFever.ActivityRecord')

    Write-Output $activity
}
