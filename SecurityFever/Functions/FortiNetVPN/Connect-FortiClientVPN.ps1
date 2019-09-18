<#
    .SYNOPSIS
        Connect to the FortiNet VPN.

    .DESCRIPTION
        This script will use the FortiSSLVPNclient.exe command line tool to
        connect to the FortiClient VPN.

    .PARAMETER ProfileName
        The VPN profile to connect.

    .PARAMETER ComputerName
        The FortiNet VPN server.

    .PARAMETER Port
        The FortiNet VPN port. By default 443.

    .PARAMETER Credential
        Username and password of the FortiNet VPN. By default it will get the
        credential vault entry with the target name 'FortiNet VPN Credential'.

    .PARAMETER Certificate
        The client certificate for the connection. By default the certificate
        from the current user store with the user display name.
#>
function Global:Connect-FortiClientVPN
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ComputerName,

        [Parameter(Mandatory = $false)]
        [System.Int32]
        $Port = 443,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.Credential()]
        [System.Management.Automation.PSCredential]
        $Credential = (Use-VaultCredential -TargetName 'FortiNet VPN Credential'),

        [Parameter(Mandatory = $false)]
        [System.String]
        $Certificate = (Get-CimInstance -ClassName Win32_NetworkLoginProfile -Filter "Caption = '$Env:Username'").FullName
    )

    # Connection credentials
    $username = $Credential.UserName
    $password = $Credential.Password | Unprotect-SecureString

    # Connect
    FortiSSLVPNclient.exe connect -s $ProfileName -h "$ComputerName`:$Port" -u "$username`:$password" -c $Certificate -q -m
}
