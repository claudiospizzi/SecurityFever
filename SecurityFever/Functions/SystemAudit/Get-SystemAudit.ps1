<#
    .SYNOPSIS
        Get all audit changes on the target system.
#>
function Get-SystemAudit
{
    [CmdletBinding()]
    param
    (
        # Period of days to cover.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $DayPeriod = 7,

        # Show extended events, not only the important ones.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Extended,

        # Hide the warning messages, don't test the prerequisites.
        [Parameter(Mandatory = $false)]
        [Switch]
        $HideWarning
    )

    # Global tests
    Show-SystemAuditEventLogWarning -LogName 'Application' -DayPeriod $DayPeriod -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditEventLogWarning -LogName 'Security' -DayPeriod $DayPeriod -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditEventLogWarning -LogName 'System' -DayPeriod $DayPeriod -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditPolicyWarning -Category 'Logon/Logoff' -Subcategory 'Logon' -Setting 'Success' -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditPolicyWarning -Category 'Logon/Logoff' -Subcategory 'Logon' -Setting 'Failure' -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditPolicyWarning -Category 'Logon/Logoff' -Subcategory 'Logoff' -Setting 'Success' -HideWarning:$HideWarning.IsPresent

    # Get all audit events
    Get-SystemAuditMsiInstaller -Extended:$Extended.IsPresent -DayPeriod $DayPeriod -HideWarning
    Get-SystemAuditPowerCycle -Extended:$Extended.IsPresent -DayPeriod $DayPeriod -HideWarning
    Get-SystemAuditUserSession -Extended:$Extended.IsPresent -DayPeriod $DayPeriod -HideWarning
    Get-SystemAuditGroupPolicy -Extended:$Extended.IsPresent -DayPeriod $DayPeriod -HideWarning
}
