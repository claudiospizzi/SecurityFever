<#
    .SYNOPSIS
        Add an entry to the trusted host list.

    .DESCRIPTION
        Append the entry to the trusted host list separated by a comma and store
        it in the path WSMan:\localhost\Client\TrustedHosts.

    .INPUTS
        System.String. Trusted host list entry.

    .OUTPUTS
        None.

    .EXAMPLE
        PS C:\> Add-TrustedHosts -ComputerName 'SERVER', '10.0.0.1', '*.contoso.com'
        Add the three entries to the trusted host list.

    .EXAMPLE
        PS C:\> '10.0.0.1', '10.0.0.2', '10.0.0.3' | Add-TrustedHosts
        Add the list of IP addresses to the trusted host list.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Add-TrustedHost
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.String[]]
        $ComputerName
    )

    begin
    {
        # Check the WinRM service
        $serviceWinRM = Get-Service -Name 'WinRM'
        if ($serviceWinRM.StartType -ne 'Automatic' -or $serviceWinRM.Status -ne 'Running')
        {
            throw 'The WinRM service is not running.'
        }

        # The trusted hosts list can only be changed as an administrator.
        Test-AdministratorRole -Throw

        # Get the WSMan trusted hosts item, ensure its a string
        $trustedHosts = [String] (Get-Item -Path 'WSMan:\localhost\Client\TrustedHosts').Value
    }

    process
    {
        # Add all new entries
        foreach ($computer in $ComputerName)
        {
            $trustedHosts = '{0},{1}' -f $trustedHosts, $computer
            $trustedHosts = $trustedHosts.Trim(',')
        }
    }

    end
    {
        if ($PSCmdlet.ShouldProcess($trustedHosts, "Set"))
        {
            # Finally, set the item
            Set-Item -Path 'WSMan:\localhost\Client\TrustedHosts' -Value $trustedHosts -Force
        }
    }
}
