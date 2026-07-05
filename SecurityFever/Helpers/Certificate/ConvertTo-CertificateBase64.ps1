<#
    .SYNOPSIS
        Converts a byte array to a certificate base64 PEM format string with
        line breaks every 64 characters as required by the PEM format. The PEM
        type can be specified as parameter.
#>
function ConvertTo-CertificateBase64
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('CERTIFICATE', 'PRIVATE KEY', 'RSA PRIVATE KEY')]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Byte[]]
        $Byte
    )

    begin
    {
        # Start the with the PEM header line
        $outputBuilder = [System.Text.StringBuilder]::new()
        $outputBuilder.AppendLine("-----BEGIN $Type-----") | Out-Null

        $derBytes = @()
    }

    process
    {
        foreach ($currentByte in $Byte)
        {
            $derBytes += $currentByte
        }
    }

    end
    {
        # Convert the byte array to a base64 string.
        $pemBase64 = [System.Convert]::ToBase64String($derBytes)

        # Convert the string to base64 junks with a maximum length of 64
        # characters per line. This is the certificate content.
        for ($i = 0; $i -lt $pemBase64.Length; $i += 64)
        {
            $outputBuilder.AppendLine($pemBase64.Substring($i, [System.Math]::Min(64, $pemBase64.Length - $i))) | Out-Null
        }

        # Finish the PEM format with the end line.
        $outputBuilder.AppendLine("-----END $Type-----") | Out-Null
        return $outputBuilder.ToString()
    }
}
