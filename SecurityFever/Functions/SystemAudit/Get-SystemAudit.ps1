<#
    .SYNOPSIS
        Get all audit changes on the target system.

    .DESCRIPTION
        Invoke all system audit commands in the SecurityFever module and get a
        summarized view of all audit events.
        - File System
        - MSI Installer
        - Power Cycle
        - User Session
        - Group Policy
        - Windows Service

    .INPUTS
        None.

    .OUTPUTS
        SecurityFever.SystemAudit.Event.

    .EXAMPLE
        PS C:\> Get-SystemAudit
        Get all local system audit events covered by the SecurityFever module.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
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

    # Ensure we are administrator to access the security log.
    Test-AdministratorRole -Throw

    # Global tests if all event's are logged on the local system. Show a warning
    # if we query events which are not logged in the first place.
    Show-SystemAuditEventLogWarning -LogName 'Application' -DayPeriod $DayPeriod -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditEventLogWarning -LogName 'Security' -DayPeriod $DayPeriod -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditEventLogWarning -LogName 'System' -DayPeriod $DayPeriod -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditPolicyWarning -Category 'Logon/Logoff' -Subcategory 'Logon' -Setting 'Success' -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditPolicyWarning -Category 'Logon/Logoff' -Subcategory 'Logon' -Setting 'Failure' -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditPolicyWarning -Category 'Logon/Logoff' -Subcategory 'Logoff' -Setting 'Success' -HideWarning:$HideWarning.IsPresent
    Show-SystemAuditPolicyWarning -Category 'Object Access' -Subcategory 'File System' -Setting 'Success' -HideWarning:$HideWarning.IsPresent

    # Get all audit events
    Get-SystemAuditFileSystem -Extended:$Extended.IsPresent -DayPeriod $DayPeriod -HideWarning
    Get-SystemAuditMsiInstaller -Extended:$Extended.IsPresent -DayPeriod $DayPeriod -HideWarning
    Get-SystemAuditPowerCycle -Extended:$Extended.IsPresent -DayPeriod $DayPeriod -HideWarning
    Get-SystemAuditUserSession -Extended:$Extended.IsPresent -DayPeriod $DayPeriod -HideWarning
    Get-SystemAuditGroupPolicy -Extended:$Extended.IsPresent -DayPeriod $DayPeriod -HideWarning
    Get-SystemAuditWindowsService -Extended:$Extended.IsPresent -DayPeriod $DayPeriod -HideWarning
}
