<#
    .SYNOPSIS
        Disconnect from the built-in VPN.

    .DESCRIPTION
        This script will use the rasdial.exe command line tool to disconnect
        from the built-in VPN.
#>
function Global:Disconnect-WindowsVPN
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ConnectionName
    )

    # Disconnect from VPN
    rasdial.exe "$ConnectionName" /disconnect
}
