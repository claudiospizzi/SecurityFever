<#
    .SYNOPSIS
    Get trusted host list entries.

    .DESCRIPTION
    Return the WSMan:\localhost\Client\TrustedHosts item as string array
    separated by the comma.

    .INPUTS
    None.

    .OUTPUTS
    System.String. Array of trusted host list entries.

    .EXAMPLE
    PS C:\> Get-TrsutedHosts
    Get trusted host list entries.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/SecurityFever
#>

function Get-TrustedHosts
{
    [CmdletBinding()]
    param ()

    # Get the WSMan trusted hosts item, ensure its a string
    $trustedHosts = [String] (Get-Item -Path 'WSMan:\localhost\Client\TrustedHosts').Value

    # Split the list by comma
    if (-not [String]::IsNullOrWhiteSpace($trustedHosts))
    {
        Write-Output $trustedHosts.Split(',')
    }
}