<#
    .SYNOPSIS
        Convert a secure string into a string.

    .DESCRIPTION
        Uses the Windows build-in data protection API (DPAPI) to convert the
        secure string back to a string. Only the user which has protected the
        original string can decrypt it.

    .INPUTS
        System.Security.SecureString. The protected secure string.

    .OUTPUTS
        System.String. The unprotected string.

    .EXAMPLE
        PS C:\> Unprotect-SecureString -SecureString $password
        Get the plain text password.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Unprotect-SecureString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [System.Security.SecureString[]]
        $SecureString
    )

    process
    {
        foreach ($currentSecureString in $SecureString)
        {
            $currentCredential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList 'Dummy', $currentSecureString

            $currentString = $currentCredential.GetNetworkCredential().Password

            Write-Output $currentString
        }
    }
}
