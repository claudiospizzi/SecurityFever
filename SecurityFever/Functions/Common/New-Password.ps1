<#
    .SYNOPSIS
        Generate a new secure password.

    .DESCRIPTION
        This command will generate a secure random password, by default with 30
        characters. The source characters to generated the password are
        carefully crafted to avoid ambiguous characters and keyboard layout
        issues between Swiss German and US. Default is an equal balance between
        lowercase, uppercase and numbers.
        - l (ell)
        - 1 (one)
        - I (capital i)
        - O (capital o)
        - 0 (zero)
        - zZyY (keyboard layout issues)

    .EXAMPLE
        PS C:\> New-Password
        Generate a new password and copy it to the clipboard.

    .EXAMPLE
        PS C:\> New-Password -OutputType 'SecureString'
        Generate a new password and return it as secure string.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function New-Password
{
    [CmdletBinding()]
    [Alias('pw')]
    param
    (
        # The length of the password.
        [Parameter(Mandatory = $false, Position = 0)]
        [System.Int32]
        $Length = 30,

        # Characters to use for the password generation. See description for
        # more details.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Include = 'abcdefghijkmnopqrstuvwxABCDEFGHJKLMNPQRSTUVWX234567892345678923456789',

        # How to return the generated password.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Clipboard', 'String', 'SecureString')]
        [System.String]
        $OutputType = 'Clipboard'
    )

    try
    {
        $password = [System.Security.SecureString]::new()

        # For PowerShell 6 and later, use the modern random number generator.
        # For PowerShell 5 and before, use the legacy cryptographic functions.
        if ($PSVersionTable.PSVersion.Major -gt 5)
        {
            for ($i = 0; $i -lt $Length; $i++)
            {
                # Directly generated a random number between 0 and the length of
                # the include character array.
                $randomNumber = [System.Security.Cryptography.RandomNumberGenerator]::GetInt32(0, $Include.Length)

                $password.AppendChar($Include[$randomNumber])
            }
        }
        else
        {
            $rngProvider = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
            for ($i = 0; $i -lt $Length; $i++)
            {
                # Generate a cryptographically secure seed for the Random class.
                [System.Byte[]] $randomSeedBytes = [System.Byte[]]::new(4)
                $rngProvider.GetBytes($randomSeedBytes)
                $randomSeedNumber = [System.BitConverter]::ToInt32($randomSeedBytes, 0)

                # Use the seed to generated a random number between 0 and the
                # length of the include character array.
                $randomNumber = [System.Random]::new($randomSeedNumber).Next(0, $Include.Length)

                $password.AppendChar($Include[$randomNumber])
            }
        }

        switch ($OutputType)
        {
            'Clipboard'    { Unprotect-SecureString -SecureString $password | Set-Clipboard; return }
            'String'       { return (Unprotect-SecureString -SecureString $password) }
            'SecureString' { return $password }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
