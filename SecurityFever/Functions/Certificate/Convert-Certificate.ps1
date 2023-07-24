<#
    .SYNOPSIS
        Convert certificates files into other formats.

    .DESCRIPTION
        Function to convert certificate files. This function is using native
        .NET crypto functions and does not required external dependencies.

        The following overview should give a short introduction about
        certificates and their file formats:
        - X.509/DER (.cer)
          Contains the public part of a single X.509 certificate in the binary
          DER format. Used primary on Windows systems.
        - X.509/PEM (.pem)
          Contains the public part of a single X.509 certificate in the Base64
          encoded PEM format. Used primary on Linux systems.

        Input certificate formats supported by this command:
        - X.509/DER
        - X.509/PEM

        Output certificate formats supported by this command:
        - X.509/DER
        - X.509/PEM

        IDeas but not yet implemented certificate formats:
        - .PKCS#7 (.p7b)
        - .pfx Files
        - PKCS#1 private key
        - PKCS#8 private key
        - PKCS#7 (multiple cert)
        - PKCS12 public + private key (.p12/.pfx)

    .EXAMPLE
        PS C:\> Convert-Certificate -InPath 'cert.cer' -OutPath 'cert.pem' -OutType 'X.509/PEM'
        Convert a X.509/DER certificate file to a X.509/PEM certificate file.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Convert-Certificate
{
    [CmdletBinding()]
    param
    (
        # Path to the input certificate file.
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('In', 'InFile')]
        [ValidateScript({ Test-Path -Path $_ })]
        [System.String]
        $InPath,

        # Optional password to read the input file.
        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]
        $InPassword,

        # Path to the output certificate file.
        [Parameter(Mandatory = $true, Position = 1)]
        [Alias('Out', 'OutFile')]
        [System.String]
        $OutPath,

        # Optional password to write the output file.
        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]
        $OutPassword,

        # Type of the output certificate file.
        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateSet('X.509/DER', 'X.509/PEM')]
        [System.String]
        $OutType
    )

    $InPath = Resolve-Path -Path $InPath | Select-Object -ExpandProperty 'Path'

    if ($PSBoundParameters.ContainsKey('InPassword'))
    {
        $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate]::new($InPath, $InPassword)
    }
    else
    {
        $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate]::new($InPath)
    }

    function ConvertTo-Base64 ([System.Byte[]] $Byte)
    {
        $straight = [System.Convert]::ToBase64String($Byte)

        # Convert the string to base64 junks with a maximum length of 64
        # characters per line.
        $formatted = [System.Text.StringBuilder]::new()
        for ($i = 0; $i -lt $straight.Length; $i += 64)
        {
            $formatted.AppendLine($straight.Substring($i, [System.Math]::Min(64, $straight.Length - $i))) | Out-Null
        }

        # Remove the new lines for the last empty line and store it as a simple
        # string with newlines, no string array.
        $formattedString = $formatted.ToString().TrimEnd("`n`r")

        return $formattedString
    }

    switch ($OutType)
    {
        'X.509/DER'
        {
            $certificateBytes  = $certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
            [System.IO.File]::WriteAllBytes($OutPath, $certificateBytes)
        }

        'X.509/PEM'
        {
            $certificateBytes  = $certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
            $certificateBase64 = ConvertTo-Base64 -Byte $certificateBytes

            $outStringBuilder = [System.Text.StringBuilder]::new()
            $outStringBuilder.AppendLine("-----BEGIN CERTIFICATE-----") | Out-Null
            $outStringBuilder.AppendLine($certificateBase64) | Out-Null
            $outStringBuilder.Append("-----END CERTIFICATE-----") | Out-Null

            Set-Content -Path $OutPath -Value $outStringBuilder.ToString() #-Encoding 'UTF8'
        }
    }
}


# openssl x509 -inform der -outform pem -in ca.cer -out ca.pem


# -----BEGIN RSA PRIVATE KEY-----
# MIIDBjCCAm8CAQAwcTERMA8GA1UEAxMIcXV1eC5jb20xDzANBgNVBAsTBkJyYWlu
# czEWMBQGA1UEChMNRGV2ZWxvcE1lbnRvcjERMA8GA1UEBxMIVG9ycmFuY2UxEzAR
# BgNVBAgTCkNhbGlmb3JuaWExCzAJBgNVBAYTAlVTMIGfMA0GCSqGSIb3DQEBAQUA
# <...>
# -----END RSA PRIVATE KEY-----


# -----BEGIN PRIVATE KEY-----
# MIIDBjCCAm8CAQAwcTERMA8GA1UEAxMIcXV1eC5jb20xDzANBgNVBAsTBkJyYWlu
# czEWMBQGA1UEChMNRGV2ZWxvcE1lbnRvcjERMA8GA1UEBxMIVG9ycmFuY2UxEzAR
# BgNVBAgTCkNhbGlmb3JuaWExCzAJBgNVBAYTAlVTMIGfMA0GCSqGSIb3DQEBAQUA
# <...>
# -----END PRIVATE KEY-----
