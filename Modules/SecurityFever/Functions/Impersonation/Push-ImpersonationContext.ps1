<#
    .SYNOPSIS
        Create a new impersonation context by using the specified credentials.
        All following commands will be executed as the specified user until the
        context is closed.

    .DESCRIPTION
        Use the Win32 unmanaged API in the AdvApi32.dll to logon the user with
        the specified credentials. With this logon token, the user can be
        impersonated in the current session.

    .INPUTS
        None.

    .OUTPUTS
        None.

    .EXAMPLE
        PS C:\> Push-ImpersonationContext -Credential 'CONTOSO\Operator'
        Create a new impersonation context for the Contoso Operator user.

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
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # The logon type.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Interactive', 'Network', 'Batch', 'Service', 'Unlock', 'NetworkClearText', 'NewCredentials')]
        $LogonType = 'Interactive',

        # The logon provider.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Default', 'WinNT40', 'WinNT50')]
        $LogonProvider = 'Default'
    )

    Initialize-ImpersonationContext

    # Handle for the logon token
    $tokenHandle = [IntPtr]::Zero

    # Now logon the user account on the local system
    $logonResult = [Win32.AdvApi32]::LogonUser($Credential.GetNetworkCredential().UserName,
                                               $Credential.GetNetworkCredential().Domain,
                                               $Credential.GetNetworkCredential().Password,
                                               ([Win32.Logon32Type] $LogonType),
                                               ([Win32.Logon32Provider] $LogonProvider),
                                               [ref] $tokenHandle)

    # Error handling, if the logon fails
    if (-not $logonResult)
    {
        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

        throw "Failed to call LogonUser() throwing Win32 exception with error code: $errorCode"
    }

    # Update the PSReadline history save style
    if ($null -ne (Get-Module -Name 'PSReadline') -and $Script:ImpersonationContext.Count -eq 0)
    {
        Set-PSReadlineOption -HistorySaveStyle 'SaveNothing' -ErrorAction SilentlyContinue
    }

    # Go to the system root drive, to prevent access denied on user paths
    Set-Location -Path "$Env:SystemDrive\"

    # Now, impersonate the new user account
    $newImpersonationContext = [System.Security.Principal.WindowsIdentity]::Impersonate($tokenHandle)
    $Script:ImpersonationContext.Push($newImpersonationContext)

    # Finally, close the handle to the token
    [Win32.Kernel32]::CloseHandle($tokenHandle) | Out-Null
}
