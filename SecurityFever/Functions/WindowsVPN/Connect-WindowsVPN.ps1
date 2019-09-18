<#
    .SYNOPSIS
        Connect to the built-in VPN.

    .DESCRIPTION
        This script will use the rasdial.exe command line tool to connect to the
        built-in VPN.
#>
function Connect-WindowsVPN
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ConnectionName,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Credential()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    $username = $Credential.UserName
    $password = $Credential.GetNetworkCredential().Password

    # Connect to VPN
    rasdial.exe "$ConnectionName" "$username" "$password"
}
