<#
    .SYNOPSIS
        Get all audit changes on the target system.
#>
function Get-SystemAudit
{
    [CmdletBinding()]
    param
    (
        # Period of days to report for the audit events
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $Period = 7
    )

    # Global tests
    Test-EventLogPeriod -LogName 'Application' -Period $Period | Out-Null
    Test-EventLogPeriod -LogName 'System' -Period $Period | Out-Null

    # Get all audit events
    Get-SystemAuditMsiInstaller -Period $Period -SkipTest
    Get-SystemAuditPowerCycle -Period $Period -SkipTest
}
