<#
    .SYNOPSIS
        Convert a byte array to a Base32 (RFC 4648) based string.
#>
function Convert-ByteToBase32
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Byte[]]
        $Byte
    )

    # RFC 4648 Base32 alphabet
    $rfc4648 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'

    # Convert the byte array to a binary string
    $binaryString = ''
    foreach ($b in $Byte)
    {
        $binaryString += [System.Convert]::ToString($b, 2).PadLeft(8, '0')
    }

    # If we have a binary string to a multiple of 5, append 0 chars to fill.
    if ($binaryString.Length % 5)
    {
        $binaryString += '0' * (5 - ($binaryString.Length % 5))
    }

    # Convert it to a Base32 string by using regex to split the binary array
    # into chunks of 5 bits, convert that to an int indexing into the RFC 4648
    # alphabet.
    $replaceCallback = {
        param ($Match)
        $index = [System.Convert]::ToInt32($Match.Value, 2)
        return $rfc4648[$index]
    }
    [System.Text.RegularExpressions.Regex]::Replace($binaryString, '.{5}', $replaceCallback)
}
