
function Initialize-ImpersonationContext
{
    [CmdletBinding()]
    param ()

    # Add Win32 native API methods to call to LogonUser()
    if (-not ([System.Management.Automation.PSTypeName]'Win32.AdvApi32').Type)
    {
        Add-Type -Namespace 'Win32' -Name 'AdvApi32' -MemberDefinition '
            [DllImport("advapi32.dll", SetLastError = true)]
            public static extern bool LogonUser(string lpszUserName, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, out IntPtr phToken);
        '
    }

    # Add Win32 native API methods to call to CloseHandle()
    if (-not ([System.Management.Automation.PSTypeName]'Win32.Kernel32').Type)
    {
        Add-Type -Namespace 'Win32' -Name 'Kernel32' -MemberDefinition '
            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern bool CloseHandle(IntPtr handle);
        '
    }

    # Define enumeration for the logon type
    if (-not ([System.Management.Automation.PSTypeName]'Win33.Logon32Type').Type)
    {
        Add-Type -TypeDefinition '
            namespace Win32
            {
                public enum Logon32Type
                {
                    Interactive      = 2,
                    Network          = 3,
                    Batch            = 4,
                    Service          = 5,
                    Unlock           = 7,
                    NetworkClearText = 8,
                    NewCredentials   = 9
                }
            }
        '
    }

    # Define enumeration for the logon provider
    if (-not ([System.Management.Automation.PSTypeName]'Win33.Logon32Type').Type)
    {
        Add-Type -TypeDefinition '
            namespace Win32
            {
                public enum Logon32Provider
                {
                    Default = 0,
                    WinNT40 = 2,
                    WinNT50 = 3
                }
            }
        '
    }

    # Global variable to hold the impersonation context
    if ($null -eq $Script:ImpersonationContext)
    {
        $Script:ImpersonationContext = New-Object -TypeName 'System.Collections.Generic.Stack[System.Security.Principal.WindowsImpersonationContext]'
    }

    # Global variable to hold the PSReadline preference
    if ($null -ne (Get-Module -Name 'PSReadline') -and $null -eq $Script:PSReadlineHistorySaveStyle)
    {
        $Script:PSReadlineHistorySaveStyle = Get-PSReadlineOption | Select-Object -ExpandProperty 'HistorySaveStyle'
    }
}
