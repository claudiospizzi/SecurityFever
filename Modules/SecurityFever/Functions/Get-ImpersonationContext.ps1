<#
    .SYNOPSIS
    

    .DESCRIPTION


    .INPUTS
    None.

    .OUTPUTS
    The current impersonation context.

    .EXAMPLE
    PS C:\> 
    

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
        WindowsIdentity    = $windowsIdentity.Name
        AuthenticationType = $windowsIdentity.AuthenticationType
        IsAuthenticated    = $windowsIdentity.IsAuthenticated
        IsGuest            = $windowsIdentity.IsGuest
        IsSystem           = $windowsIdentity.IsSystem
        IsAnonymous        = $windowsIdentity.IsAnonymous
    }
}
