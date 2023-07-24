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
        - zZyY (en/us keyboard layout issues)

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
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
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
        [Alias('As')]
        [ValidateSet('SecureString', 'String', 'Clipboard')]
        [System.String]
        $OutputType = 'SecureString'
    )

    try
    {
        $password = [System.Security.SecureString]::new()

        # For PowerShell 6 and later, use the modern random number generator.
        # For PowerShell 5 and before, use the legacy cryptographic functions.
        do
        {
            $isComplexLower  = $false
            $isComplexUpper  = $false
            $isComplexNumber = $false

            for ($i = 0; $i -lt $Length; $i++)
            {
                # Directly generated a random number between 0 and the length of
                # the include character array. If we have a modern PowerShell
                # and .NET version, use the cryptographically secure seed for
                # the Random class.
                if ($PSVersionTable.PSVersion.Major -gt 5)
                {
                    $randomNumber = [System.Security.Cryptography.RandomNumberGenerator]::GetInt32(0, $Include.Length)
                }
                else
                {
                    # Generate a cryptographically secure seed for the Random
                    # class and then use the seed to generated a random number
                    # between 0 and the length of the include character array.
                    [System.Byte[]] $randomSeedBytes = [System.Byte[]]::new(4)
                    $rngProvider = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
                    $rngProvider.GetBytes($randomSeedBytes)
                    $randomSeedNumber = [System.BitConverter]::ToInt32($randomSeedBytes, 0)
                    $randomNumber = [System.Random]::new($randomSeedNumber).Next(0, $Include.Length)
                }

                $randomChar = $Include[$randomNumber]
                $password.AppendChar($randomChar)

                switch -regex ($randomChar)
                {
                    '[a-z]' { $isComplexLower  = $true }
                    '[A-Z]' { $isComplexUpper  = $true }
                    '[0-9]' { $isComplexNumber = $true }
                }
            }
        }
        while (-not ($isComplexLower -and $isComplexUpper -and $isComplexNumber))

        switch ($OutputType)
        {
            'SecureString'
            {
                Write-Output $password
            }
            'String'
            {
                Unprotect-SecureString -SecureString $password | Write-Output
            }
            'Clipboard'
            {
                Unprotect-SecureString -SecureString $password | Set-Clipboard
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
