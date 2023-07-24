<#
    .SYNOPSIS
        Generate a shared secret for the Time-Base One-Time algorithm RFC 6238.

    .DESCRIPTION
        This command will create a new shared secret to be used for the
        Time-Based One-Time password algorithm (TOTP) specified in the RFC 6238.
        The command will return an object containing the following
        representations of the shared secret:
        - Shared secret encoded as Base32 (specified in RFC 4648)
        - Key uri format otpauth:// for apps like the Google Authenticator
        - As Duo Security compatible CSV line to import as hardware token

    .INPUTS
        None.

    .OUTPUTS
        SecurityFever.TOTPSharedSecret. Object with multiple representations of
        the shared secret.

    .EXAMPLE
        PS C:\> New-TimeBasedOneTimeSharedSecret -Account 'User1'
        Create a new TOTP shared secret for the user User1.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function New-TimeBasedOneTimeSharedSecret
{
    [CmdletBinding()]
    [Alias('New-TOTPSharedSecret')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Account,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Issuer = "$Env:UserDomain\$Env:Username"
    )

    $ErrorActionPreference = 'Stop'

    [System.Byte[]] $bytes = @()
    for ($i = 0; $i -lt 16; $i++)
    {
        $bytes += [System.Byte] (Get-Random -Minimum 0 -Maximum 255)
    }

    # Convert the shared secret into usable formats
    $sharedSecretHex    = [System.BitConverter]::ToString($bytes) -replace '-', ''
    $sharedSecretBase32 = Convert-ByteToBase32 -Byte $bytes

    # Generate the QR code
    $qrCodePath = '{0}\{1:yyyyMMddHHmmss}_{2}.png' -f $Env:Temp, (Get-Date), $Account.Replace('\', '_')
    $qrOneTimeGenerator = [QRCoder.PayloadGenerator+OneTimePassword]::new()
    $qrOneTimeGenerator.Secret = $sharedSecretBase32
    $qrOneTimeGenerator.Issuer = $Issuer
    $qrOneTimeGenerator.Label  = $Account
    $qrGenerator = [QRCoder.QRCodeGenerator]::new()
    $qrData = $qrGenerator.CreateQrCode($qrOneTimeGenerator.ToString(), 'Q')
    $qrCode = [QRCoder.PngByteQRCode]::new($qrData)
    [System.IO.File]::WriteAllBytes($qrCodePath, $qrCode.GetGraphic(100))

    [PSCustomObject] @{
        PSTypeName          = 'SecurityFever.TOTPSharedSecret'
        SharedSecret        = $sharedSecretBase32
        AuthenticatorUri    = 'otpauth://totp/{0}?secret={1}&issuer={2}' -f $Account, $sharedSecretBase32, $Issuer
        AuthenticatorQRCode = $qrCodePath
        DuoHardwareToken    = 'SoftwareToken_{0},{1}' -f $Account, $sharedSecretHex
    }

    Invoke-Item -Path $qrCodePath
}
