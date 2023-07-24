<#
    .SYNOPSIS
        Extract the user name of a event log record.
#>
function Get-WinEventRecordUser
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        # Event log record object.
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Eventing.Reader.EventLogRecord]
        $Record
    )

    if ($null -eq $Record.UserId)
    {
        return ''
    }

    try
    {
        $ntAccount = $Record.UserId.Translate([System.Security.Principal.NTAccount])
        return $ntAccount.Value
    }
    catch
    {
        return $Record.UserId.Value
    }
}
