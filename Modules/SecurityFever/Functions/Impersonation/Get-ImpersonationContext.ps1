<#
    .SYNOPSIS
        Get the current impersonation context and the active windows identity.

    .DESCRIPTION
        Returns the current impersonation context and the active windows
        identity available on the GetCurrent() method on the WindowsIdentity
        .NET class.

    .INPUTS
        None.

    .OUTPUTS
        The current impersonation context.

    .EXAMPLE
        PS C:\> Get-ImpersonationContext
        Return the current impersonation context.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-ImpersonationContext
{
    [CmdletBinding()]
    param ()

    Initialize-ImpersonationContext

    $windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()

    [PSCustomObject] @{
        ImpersonationLevel = $windowsIdentity.ImpersonationLevel
        ImpersonationStack = $Script:ImpersonationContext.Count
        WindowsIdentity    = $windowsIdentity.Name
        AuthenticationType = $windowsIdentity.AuthenticationType
        IsAuthenticated    = $windowsIdentity.IsAuthenticated
        IsGuest            = $windowsIdentity.IsGuest
        IsSystem           = $windowsIdentity.IsSystem
        IsAnonymous        = $windowsIdentity.IsAnonymous
    }
}
