
function Test-AdministratorRole
{
    [CmdletBinding()]
    param ()

    # Check against the generic administrator role (language neutral).
    $AdministratorRole = [Security.Principal.WindowsBuiltInRole]::Administrator

    # Get the current user identity
    $CurrentWindowsPrincipal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()

    return $CurrentWindowsPrincipal.IsInRole($AdministratorRole)
}
