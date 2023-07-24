<#
    .SYNOPSIS
        Test if the user is an administrator.
#>
function Test-AdministratorRole
{
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    param
    (
        # If enabled, the function with throw if the user is not admin
        [Parameter(Mandatory = $false)]
        [Switch]
        $Throw,

        # Message to throw if the user is not admin
        [Parameter(Mandatory = $false)]
        [System.String]
        $Message = 'Access denied. Please start this functions as an administrator.'
    )

    # Check against the generic administrator role (language neutral).
    $AdministratorRole = [Security.Principal.WindowsBuiltInRole]::Administrator

    # Get the current user identity
    $CurrentWindowsPrincipal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()

    $result = $CurrentWindowsPrincipal.IsInRole($AdministratorRole)

    if ($Throw.IsPresent)
    {
        if (-not $result)
        {
            # Throw an error message
            throw $Message
        }
    }
    else
    {
        # Return the boolean result
        return $result
    }
}
