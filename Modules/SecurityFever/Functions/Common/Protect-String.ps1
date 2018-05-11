<#
    .SYNOPSIS
        Convert a string into a secure string.

    .DESCRIPTION
        Uses the Windows build-in data protection API (DPAPI) to convert the
        string to a secure string. Only the current user, on the current
        computer with the current profile can decrypt the secure string.

    .INPUTS
        System.String. The String to protect.

    .OUTPUTS
        System.Security.SecureString. The protected string.

    .EXAMPLE
        PS C:\> Protect-String -String 'Passw0rd'
        Protect the password a secure string.

    .EXAMPLE
        PS C:\> 'Text A', 'Text B' | Protect-String
        Protect both strings as a secure string.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Protect-String
{
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope='Function', Target='Protect-String')]
    [OutputType([System.Security.SecureString])]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [System.String[]]
        $String
    )

    process
    {
        foreach ($currentString in $String)
        {
            $currentSecureString = ConvertTo-SecureString -String $currentString -AsPlainText -Force

            Write-Output $currentSecureString
        }
    }
}
