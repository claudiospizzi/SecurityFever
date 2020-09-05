<#
    .SYNOPSIS
        Extract the user name of a event log record.
#>
function Get-WinEventRecordProperty
{
    [CmdletBinding()]
    param
    (
        # Event log record object.
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Eventing.Reader.EventLogRecord]
        $Record,

        # List of property names.
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $PropertyName
    )

    $propertyHash = @{}

    for ($i = 0; $i -lt $PropertyName.Count; $i++)
    {
        $propertyHash[$PropertyName[$i]] = $Record.Properties[$i].Value
    }

    [PSCustomObject] $propertyHash
}
