<#
    .SYNOPSIS
        Writes the DER-encoded length to a binary writer.
#>
function Write-CertificateDerLength
{
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.IO.BinaryWriter]
        $Writer,

        [Parameter(Mandatory = $true)]
        [System.Int32]
        $Length
    )

    process
    {
        if ($Length -lt 0)
        {
            throw [System.ArgumentOutOfRangeException]::new('Length', 'Length must be non-negative')
        }

        if ($Length -lt 0x80)
        {
            # DER short form length
            $Writer.Write([System.Byte]$Length)
            return
        }

        # DER long form length
        $temp = $Length
        $bytesRequired = 0
        while ($temp -gt 0)
        {
            $temp = $temp -shr 8
            $bytesRequired++
        }

        $Writer.Write([System.Byte]($bytesRequired -bor 0x80))
        for ($i = $bytesRequired - 1; $i -ge 0; $i--)
        {
            $Writer.Write([System.Byte](($Length -shr (8 * $i)) -band 0xFF))
        }
    }
}
