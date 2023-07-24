<#
    .SYNOPSIS
        Extract the Win32 Exception message.
#>
function Get-WinEventWin32Exception
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        # The error code.
        [Parameter(Mandatory = $true)]
        $ErrorCode
    )

    try
    {
        $parsedErrorCode = [System.String] $ErrorCode
        $parsedErrorCode = $parsedErrorCode.Trim('%')
        $parsedErrorCode = [System.Int32] $parsedErrorCode

        $exception = [ComponentModel.Win32Exception] $parsedErrorCode

        if ([System.String]::IsNullOrWhiteSpace($exception.Message))
        {
            throw 'Exception message missing.'
        }
        else
        {
            return $exception.Message
        }
    }
    catch
    {
        return "Unspecified Error ($ErrorCode)"
    }
}
