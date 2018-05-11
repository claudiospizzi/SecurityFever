<#
    .SYNOPSIS
        Remove an entry from the trusted host list.

    .DESCRIPTION
        Remove an entry from the trusted host list and regenerate a new list
        with all the remaining entries, separated by a comma, and store it in
        the path WSMan:\localhost\Client\TrustedHosts.

    .INPUTS
        System.String. Trusted host list entry.

    .OUTPUTS
        None.

    .EXAMPLE
        PS C:\> Remove-TrustedHosts -ComputerName 'SERVER', '10.0.0.1', '*.contoso.com'
        Remove three entries from the trusted host list.

    .EXAMPLE
        PS C:\> '10.0.0.1', '10.0.0.2', '10.0.0.3' | Remove-TrustedHosts
        Remove the list of IP addresses from the trusted host list.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Remove-TrustedHost
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
        # The trusted hosts list can only be changed as an administrator.
        if (-not (Test-AdministratorRole))
        {
            throw 'Access denied. Please start this functions as an administrator.'
        }

        # Get the WSMan trusted hosts item, ensure its a string
        $trustedHosts = [String] (Get-Item -Path 'WSMan:\localhost\Client\TrustedHosts').Value

        # Create an array list
        $trustedHostsList = New-Object -TypeName 'System.Collections.ArrayList'
        $trustedHostsList.AddRange($trustedHosts.Split(','))
    }

    process
    {
        # Remove the entries
        foreach ($computer in $ComputerName)
        {
            if ($trustedHostsList.Contains($computer))
            {
                $trustedHostsList.Remove($computer)
            }
        }
    }

    end
    {
        # Join the remaining entries
        $trustedHosts = [String]::Join(',', @($trustedHostsList))

        if ($PSCmdlet.ShouldProcess($trustedHosts, "Set"))
        {
            # Finally, set the item
            Set-Item -Path 'WSMan:\localhost\Client\TrustedHosts' -Value $trustedHosts -Force
        }
    }
}
