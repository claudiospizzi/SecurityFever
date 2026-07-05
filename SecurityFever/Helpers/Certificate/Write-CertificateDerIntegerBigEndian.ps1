<#
    .SYNOPSIS
        Writes a DER-encoded integer in big-endian format to a binary writer.
#>
function Write-CertificateDerIntegerBigEndian
{
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.IO.BinaryWriter]
        $Writer,

        [Parameter(Mandatory = $true)]
        [System.Byte[]]
        $Value,

        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $ForceUnsigned = $true
    )

    process
    {
        $Writer.Write([System.Byte]0x02) # INTEGER

        $prefixZeros = 0
        for ($i = 0; $i -lt $Value.Length; $i++)
        {
            if ($Value[$i] -ne 0)
            {
                break
            }

            $prefixZeros++
        }

        if (($Value.Length - $prefixZeros) -eq 0)
        {
            Write-CertificateDerLength -Writer $Writer -Length 1
            $Writer.Write([System.Byte]0)
            return
        }

        if ($ForceUnsigned -and $Value[$prefixZeros] -gt 0x7F)
        {
            # Add prefix 0x00 when highest bit is set.
            Write-CertificateDerLength -Writer $Writer -Length ($Value.Length - $prefixZeros + 1)
            $Writer.Write([System.Byte]0)
        }
        else
        {
            Write-CertificateDerLength -Writer $Writer -Length ($Value.Length - $prefixZeros)
        }

        for ($i = $prefixZeros; $i -lt $Value.Length; $i++)
        {
            $Writer.Write($Value[$i])
        }
    }
}
