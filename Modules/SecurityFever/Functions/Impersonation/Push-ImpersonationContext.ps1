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

function Push-ImpersonationContext
{
    [CmdletBinding()]
    param
    (
        # Specifies a user account to impersonate.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    Initialize-ImpersonationContext

    # Handle for the logon token
    $tokenHandle = [IntPtr]::Zero

    # Now logon the user account on the local system
    $logonResult = [Win32.AdvApi32]::LogonUser($Credential.GetNetworkCredential().UserName,
                                               $Credential.GetNetworkCredential().Domain,
                                               $Credential.GetNetworkCredential().Password,
                                               [Win32.Logon32Type]::Interactive,
                                               [Win32.Logon32Provider]::Default,
                                               [ref] $tokenHandle)

    # Error handling, if the logon fails
    if (-not $logonResult)
    {
        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

        throw "Failed to call LogonUser() throwing Win32 exception with error code: $errorCode"
    }

    # Now, impersonate the new user account
    $impersonationContext = [System.Security.Principal.WindowsIdentity]::Impersonate($tokenHandle)
    $globalImpersonationContext = Get-Variable -Name 'ImpersonationContext' -Scope 'Global'
    $globalImpersonationContext.Push($impersonationContext)

    # Finally, close the handle to the token
    [Win32.Kernel32]::CloseHandle($tokenHandle) | Out-Null
}