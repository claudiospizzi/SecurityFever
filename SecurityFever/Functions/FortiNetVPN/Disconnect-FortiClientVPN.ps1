<#
    .SYNOPSIS
        Disconnect from the FortiNet VPN.

    .DESCRIPTION
        This script will use the FortiSSLVPNclient.exe command line tool to
        disconnect from the FortiClient VPN.
#>
function Global:Disconnect-FortiClientVPN
{
    [CmdletBinding()]
    param ()

    # Disconnect
    FortiSSLVPNclient.exe disconnect
}
